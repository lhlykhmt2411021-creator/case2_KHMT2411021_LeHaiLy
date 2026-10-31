const Task = require('../models/Task');
const TaskShare = require('../models/TaskShare');

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

async function findTaskShares(taskId) {
  return TaskShare.find({ taskId })
    .sort({ createdAt: 1 })
    .populate('userId', 'fullName email')
    .populate('sharedBy', 'fullName email');
}

module.exports = { TASK_SCOPES, findTasksForUser, getTaskWithAccess, findTaskShares };
