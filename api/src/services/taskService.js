const Task = require('../models/Task');
const TaskShare = require('../models/TaskShare');
const TaskActivity = require('../models/TaskActivity');

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

module.exports = {
  TASK_SCOPES,
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
  sameUser,
  updateTask,
};
