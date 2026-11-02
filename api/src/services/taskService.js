const Task = require('../models/Task');
const TaskShare = require('../models/TaskShare');
const TaskActivity = require('../models/TaskActivity');
const User = require('../models/User');
const { httpError } = require('../utils/httpError');

const TASK_SCOPES = ['created', 'assigned', 'shared'];

function sameUser(value, userId) {
  if (!value) {
    return false;
  }
  const id = value._id ?? value;
  return id.equals(userId);
}

function isAssignee(task, userId) {
  const assigned = task.assigneeIds.some((assignee) => sameUser(assignee, userId));
  return assigned || sameUser(task.primaryAssigneeId, userId);
}

function buildListQuery(userId, sharedTaskIds) {
  return {
    $or: [
      { createdBy: userId },
      { assigneeIds: userId },
      { primaryAssigneeId: userId },
      { _id: { $in: sharedTaskIds } },
    ],
  };
}

async function findTasksForUser(userId, scope) {
  let query;

  if (scope === 'created') {
    query = { createdBy: userId };
  } else if (scope === 'assigned') {
    query = { $or: [{ assigneeIds: userId }, { primaryAssigneeId: userId }] };
  } else {
    const sharedTaskIds = await TaskShare.find({ userId }).distinct('taskId');
    query = scope === 'shared'
      ? { _id: { $in: sharedTaskIds } }
      : buildListQuery(userId, sharedTaskIds);
  }

  return Task.find(query)
    .sort({ createdAt: -1 })
    .populate('createdBy', 'fullName email')
    .populate('primaryAssigneeId', 'fullName email');
}

async function getTaskWithAccess(taskId, userId) {
  const task = await Task.findById(taskId)
    .populate('createdBy', 'fullName email')
    .populate('primaryAssigneeId', 'fullName email')
    .populate('assigneeIds', 'fullName email');

  if (!task) {
    return { task: null, allowed: false, role: null };
  }

  const share = await TaskShare.findOne({ taskId: task._id, userId });

  let role = null;
  if (sameUser(task.createdBy, userId)) {
    role = 'creator';
  } else if (isAssignee(task, userId)) {
    role = 'assignee';
  } else if (share) {
    role = share.permission;
  }

  return { task, allowed: role !== null, role };
}

function canEditTask(role) {
  return role === 'creator' || role === 'editor';
}

function canChangeTaskStatus(role) {
  return role === 'creator' || role === 'editor' || role === 'assignee';
}

function canManageTask(role) {
  return role === 'creator';
}

async function findTaskShares(taskId) {
  return TaskShare.find({ taskId })
    .sort({ createdAt: 1 })
    .populate('userId', 'fullName email')
    .populate('sharedBy', 'fullName email');
}

async function findTaskActivities(taskId) {
  return TaskActivity.find({ taskId })
    .sort({ createdAt: -1 })
    .populate('userId', 'fullName email');
}

async function logActivity(taskId, userId, action, details = '') {
  return TaskActivity.create({ taskId, userId, action, details });
}

async function createTask(userId, input) {
  const task = await Task.create({ ...input, createdBy: userId });
  await logActivity(task._id, userId, 'created', `Đã tạo công việc "${task.title}"`);
  return task;
}

async function updateTask(task, userId, input) {
  task.title = input.title;
  task.description = input.description;
  task.priority = input.priority;
  task.startDate = input.startDate;
  task.dueDate = input.dueDate;
  await task.save();

  await logActivity(task._id, userId, 'updated', 'Đã cập nhật thông tin công việc');
  return task;
}

async function changeTaskStatus(task, userId, status) {
  if (task.status === status) {
    return task;
  }

  const previousStatus = task.status;
  task.status = status;
  await task.save();

  await logActivity(
    task._id,
    userId,
    'status_changed',
    `Trạng thái: ${previousStatus} -> ${status}`
  );
  return task;
}

async function deleteTask(task, userId) {
  await logActivity(task._id, userId, 'deleted', `Đã xóa công việc "${task.title}"`);
  await TaskShare.deleteMany({ taskId: task._id });
  await task.deleteOne();
}

async function loadRawTask(taskId) {
  const task = await Task.findById(taskId);
  if (!task) {
    throw httpError(404, 'Không tìm thấy công việc');
  }
  return task;
}

async function assertUsersExist(userIds) {
  const users = await User.find({ _id: { $in: userIds } }).select('fullName email');
  if (users.length !== userIds.length) {
    throw httpError(400, 'Có người dùng không tồn tại');
  }
  return users;
}

async function addAssignees(taskId, actorId, userIds, primaryAssigneeId) {
  const task = await loadRawTask(taskId);
  const uniqueIds = [...new Set(userIds.map(String))];

  if (uniqueIds.includes(task.createdBy.toString())) {
    throw httpError(400, 'Không thể giao việc cho chính người tạo');
  }

  const users = await assertUsersExist(uniqueIds);
  const currentIds = task.assigneeIds.map((id) => id.toString());
  if (uniqueIds.some((id) => currentIds.includes(id))) {
    throw httpError(409, 'Một số người đã được giao việc này');
  }

  await TaskShare.deleteMany({ taskId: task._id, userId: { $in: uniqueIds } });

  task.assigneeIds.push(...uniqueIds);
  if (primaryAssigneeId) {
    task.primaryAssigneeId = primaryAssigneeId;
  } else if (!task.primaryAssigneeId) {
    task.primaryAssigneeId = uniqueIds[0];
  }
  await task.save();

  const names = users.map((user) => user.fullName).join(', ');
  await logActivity(task._id, actorId, 'assigned', `Đã giao việc cho ${names}`);
  return task;
}

async function setPrimaryAssignee(taskId, actorId, userId) {
  const task = await loadRawTask(taskId);
  const isAssigned = task.assigneeIds.some((id) => id.toString() === String(userId));
  if (!isAssigned) {
    throw httpError(400, 'Người này chưa được giao công việc');
  }

  const user = await User.findById(userId).select('fullName');
  if (!user) {
    throw httpError(400, 'Có người dùng không tồn tại');
  }

  task.primaryAssigneeId = userId;
  await task.save();

  await logActivity(
    task._id,
    actorId,
    'assigned',
    `Đã đặt ${user.fullName} làm người phụ trách chính`
  );
  return task;
}

async function removeAssignee(taskId, actorId, userId) {
  const task = await loadRawTask(taskId);
  const id = String(userId);
  const index = task.assigneeIds.findIndex((assigneeId) => assigneeId.toString() === id);
  if (index === -1) {
    throw httpError(404, 'Người này chưa được giao công việc');
  }

  const user = await User.findById(userId).select('fullName');
  task.assigneeIds.splice(index, 1);

  if (task.primaryAssigneeId && task.primaryAssigneeId.toString() === id) {
    task.primaryAssigneeId = task.assigneeIds.length > 0 ? task.assigneeIds[0] : null;
  }
  await task.save();

  await logActivity(
    task._id,
    actorId,
    'unassigned',
    `Đã hủy giao việc cho ${user ? user.fullName : id}`
  );
  return task;
}

async function addShares(taskId, actorId, userIds, permission) {
  const task = await loadRawTask(taskId);
  const uniqueIds = [...new Set(userIds.map(String))];

  if (uniqueIds.includes(task.createdBy.toString())) {
    throw httpError(400, 'Không cần chia sẻ cho chính người tạo');
  }

  const users = await assertUsersExist(uniqueIds);
  const assigneeIds = task.assigneeIds.map((id) => id.toString());
  if (uniqueIds.some((id) => assigneeIds.includes(id))) {
    throw httpError(409, 'Người dùng đã được giao việc nên không cần chia sẻ');
  }

  const existingCount = await TaskShare.countDocuments({
    taskId: task._id,
    userId: { $in: uniqueIds },
  });
  if (existingCount > 0) {
    throw httpError(409, 'Một số người đã được chia sẻ công việc này');
  }

  await TaskShare.insertMany(
    uniqueIds.map((userId) => ({
      taskId: task._id,
      userId,
      permission,
      sharedBy: actorId,
    }))
  );

  const names = users.map((user) => user.fullName).join(', ');
  await logActivity(
    task._id,
    actorId,
    'shared',
    `Đã chia sẻ công việc cho ${names} (${permission})`
  );
  return task;
}

async function updateShare(taskId, actorId, shareId, permission) {
  const share = await TaskShare.findOne({ _id: shareId, taskId });
  if (!share) {
    throw httpError(404, 'Không tìm thấy lượt chia sẻ');
  }

  if (share.permission === permission) {
    return share;
  }

  share.permission = permission;
  await share.save();

  const user = await User.findById(share.userId).select('fullName');
  await logActivity(
    taskId,
    actorId,
    'share_updated',
    `Đã đổi quyền của ${user ? user.fullName : share.userId} thành ${permission}`
  );
  return share;
}

async function revokeShare(taskId, actorId, shareId) {
  const share = await TaskShare.findOne({ _id: shareId, taskId });
  if (!share) {
    throw httpError(404, 'Không tìm thấy lượt chia sẻ');
  }

  const user = await User.findById(share.userId).select('fullName');
  await share.deleteOne();

  await logActivity(
    taskId,
    actorId,
    'share_revoked',
    `Đã thu hồi quyền của ${user ? user.fullName : share.userId}`
  );
  return share;
}

module.exports = {
  TASK_SCOPES,
  addAssignees,
  addShares,
  canChangeTaskStatus,
  canEditTask,
  canManageTask,
  changeTaskStatus,
  createTask,
  deleteTask,
  findTaskActivities,
  findTaskShares,
  findTasksForUser,
  getTaskWithAccess,
  isAssignee,
  logActivity,
  removeAssignee,
  revokeShare,
  sameUser,
  setPrimaryAssignee,
  updateShare,
  updateTask,
};
