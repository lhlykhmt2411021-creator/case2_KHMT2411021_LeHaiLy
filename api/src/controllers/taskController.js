const mongoose = require('mongoose');
const {
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
  updateTask,
} = require('../services/taskService');
const {
  validateCreateTaskInput,
  validateUpdateTaskInput,
  validateStatusInput,
} = require('../validators/taskValidator');
const {
  toActivity,
  toTaskDetail,
  toTaskSummary,
} = require('../utils/taskSerializer');

const INVALID_ID_MESSAGE = 'Id không hợp lệ';
const TASK_NOT_FOUND_MESSAGE = 'Không tìm thấy công việc';
const NO_ACCESS_MESSAGE = 'Bạn không có quyền truy cập công việc này';

async function loadTaskOrRespond(req, res, options = {}) {
  const { id } = req.params;
  if (!mongoose.isValidObjectId(id)) {
    res.status(400).json({ message: INVALID_ID_MESSAGE });
    return null;
  }

  const result = await getTaskWithAccess(id, req.user._id);
  if (!result.task) {
    res.status(404).json({ message: TASK_NOT_FOUND_MESSAGE });
    return null;
  }
  if (!result.allowed) {
    res.status(403).json({ message: NO_ACCESS_MESSAGE });
    return null;
  }
  if (options.permission && !options.permission(result.role)) {
    res.status(403).json({ message: options.forbiddenMessage });
    return null;
  }

  return result;
}

async function respondWithTask(res, taskId, userId, statusCode) {
  const { task, role } = await getTaskWithAccess(taskId, userId);
  const shares = await findTaskShares(taskId);
  return res.status(statusCode).json({ task: toTaskDetail(task, role, shares) });
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
    const result = await loadTaskOrRespond(req, res);
    if (!result) {
      return undefined;
    }

    const shares = await findTaskShares(result.task._id);
    return res.status(200).json({ task: toTaskDetail(result.task, result.role, shares) });
  } catch (err) {
    return next(err);
  }
}

async function createTaskHandler(req, res, next) {
  try {
    const { value, error } = validateCreateTaskInput(req.body);
    if (error) {
      return res.status(400).json({ message: error });
    }

    const task = await createTask(req.user._id, value);
    return respondWithTask(res, task._id, req.user._id, 201);
  } catch (err) {
    return next(err);
  }
}

async function updateTaskHandler(req, res, next) {
  try {
    const result = await loadTaskOrRespond(req, res, {
      permission: canEditTask,
      forbiddenMessage: 'Bạn không có quyền sửa công việc này',
    });
    if (!result) {
      return undefined;
    }

    const { value, error } = validateUpdateTaskInput(req.body);
    if (error) {
      return res.status(400).json({ message: error });
    }

    await updateTask(result.task, req.user._id, value);
    return respondWithTask(res, result.task._id, req.user._id, 200);
  } catch (err) {
    return next(err);
  }
}

async function updateStatusHandler(req, res, next) {
  try {
    const result = await loadTaskOrRespond(req, res, {
      permission: canChangeTaskStatus,
      forbiddenMessage: 'Bạn không có quyền đổi trạng thái công việc này',
    });
    if (!result) {
      return undefined;
    }

    const { value, error } = validateStatusInput(req.body);
    if (error) {
      return res.status(400).json({ message: error });
    }

    await changeTaskStatus(result.task, req.user._id, value.status);
    return respondWithTask(res, result.task._id, req.user._id, 200);
  } catch (err) {
    return next(err);
  }
}

async function deleteTaskHandler(req, res, next) {
  try {
    const result = await loadTaskOrRespond(req, res, {
      permission: canManageTask,
      forbiddenMessage: 'Chỉ người tạo mới được xóa công việc này',
    });
    if (!result) {
      return undefined;
    }

    await deleteTask(result.task, req.user._id);
    return res.status(200).json({ message: 'Đã xóa công việc' });
  } catch (err) {
    return next(err);
  }
}

async function listActivities(req, res, next) {
  try {
    const result = await loadTaskOrRespond(req, res);
    if (!result) {
      return undefined;
    }

    const activities = await findTaskActivities(result.task._id);
    return res.status(200).json({ activities: activities.map(toActivity) });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  createTask: createTaskHandler,
  deleteTask: deleteTaskHandler,
  getTask,
  listActivities,
  listTasks,
  updateStatus: updateStatusHandler,
  updateTask: updateTaskHandler,
};
