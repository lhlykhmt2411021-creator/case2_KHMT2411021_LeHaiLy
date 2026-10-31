const mongoose = require('mongoose');
const {
  TASK_SCOPES,
  findTasksForUser,
  getTaskWithAccess,
  findTaskShares,
} = require('../services/taskService');

function toUserRef(user) {
  if (!user) {
    return null;
  }
  if (user._id) {
    return { id: user._id.toString(), fullName: user.fullName, email: user.email };
  }
  return { id: user.toString() };
}

function toTaskSummary(task) {
  return {
    id: task._id.toString(),
    title: task.title,
    description: task.description,
    status: task.status,
    priority: task.priority,
    startDate: task.startDate,
    dueDate: task.dueDate,
    createdAt: task.createdAt,
    updatedAt: task.updatedAt,
    createdBy: toUserRef(task.createdBy),
    primaryAssignee: toUserRef(task.primaryAssigneeId),
    assigneeCount: task.assigneeIds ? task.assigneeIds.length : 0,
  };
}

function toTaskDetail(task, role, shares) {
  return {
    ...toTaskSummary(task),
    role,
    assignees: (task.assigneeIds || []).map(toUserRef),
    shares: shares.map((share) => ({
      id: share._id.toString(),
      permission: share.permission,
      user: toUserRef(share.userId),
      sharedBy: toUserRef(share.sharedBy),
      createdAt: share.createdAt,
    })),
  };
}

async function listTasks(req, res, next) {
  try {
    const { scope } = req.query;
    if (scope !== undefined && !TASK_SCOPES.includes(scope)) {
      return res.status(400).json({ message: 'scope không hợp lệ' });
    }

    const tasks = await findTasksForUser(req.user._id, scope);
    return res.status(200).json({ tasks: tasks.map(toTaskSummary) });
  } catch (err) {
    return next(err);
  }
}

async function getTask(req, res, next) {
  try {
    const { id } = req.params;
    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({ message: 'Id không hợp lệ' });
    }

    const { task, allowed, role } = await getTaskWithAccess(id, req.user._id);
    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc' });
    }
    if (!allowed) {
      return res.status(403).json({ message: 'Bạn không có quyền truy cập công việc này' });
    }

    const shares = await findTaskShares(task._id);
    return res.status(200).json({ task: toTaskDetail(task, role, shares) });
  } catch (err) {
    return next(err);
  }
}

module.exports = { listTasks, getTask };
