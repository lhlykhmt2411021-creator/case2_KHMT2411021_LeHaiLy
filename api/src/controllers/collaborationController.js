const mongoose = require('mongoose');
const {
  addAssignees,
  addShares,
  canManageTask,
  findTaskShares,
  getTaskWithAccess,
  removeAssignee,
  revokeShare,
  setPrimaryAssignee,
  updateShare,
} = require('../services/taskService');
const {
  toShare,
  toTaskDetail,
  toUserRef,
} = require('../utils/taskSerializer');
const {
  validateAssigneesInput,
  validatePermissionInput,
  validateShareInput,
} = require('../validators/collaborationValidator');

const INVALID_ID_MESSAGE = 'Id không hợp lệ';
const TASK_NOT_FOUND_MESSAGE = 'Không tìm thấy công việc';
const NO_ACCESS_MESSAGE = 'Bạn không có quyền truy cập công việc này';
const MANAGE_FORBIDDEN_MESSAGE = 'Chỉ người tạo mới được quản lý giao việc và chia sẻ';

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
  if (options.manage && !canManageTask(result.role)) {
    res.status(403).json({ message: MANAGE_FORBIDDEN_MESSAGE });
    return null;
  }

  return result;
}

async function respondWithTask(res, taskId, userId) {
  const { task, role } = await getTaskWithAccess(taskId, userId);
  const shares = await findTaskShares(taskId);
  return res.status(200).json({ task: toTaskDetail(task, role, shares) });
}

async function listAssignees(req, res, next) {
  try {
    const result = await loadTaskOrRespond(req, res);
    if (!result) {
      return undefined;
    }

    return res.status(200).json({
      assignees: (result.task.assigneeIds || []).map(toUserRef),
      primaryAssignee: toUserRef(result.task.primaryAssigneeId),
    });
  } catch (err) {
    return next(err);
  }
}

async function createAssignees(req, res, next) {
  try {
    const result = await loadTaskOrRespond(req, res, { manage: true });
    if (!result) {
      return undefined;
    }

    const { value, error } = validateAssigneesInput(req.body);
    if (error) {
      return res.status(400).json({ message: error });
    }

    await addAssignees(
      result.task._id,
      req.user._id,
      value.userIds,
      value.primaryAssigneeId
    );
    return respondWithTask(res, result.task._id, req.user._id);
  } catch (err) {
    return next(err);
  }
}

async function changePrimaryAssignee(req, res, next) {
  try {
    const result = await loadTaskOrRespond(req, res, { manage: true });
    if (!result) {
      return undefined;
    }

    const { userId } = req.params;
    if (!mongoose.isValidObjectId(userId)) {
      return res.status(400).json({ message: 'Id người dùng không hợp lệ' });
    }

    await setPrimaryAssignee(result.task._id, req.user._id, userId);
    return respondWithTask(res, result.task._id, req.user._id);
  } catch (err) {
    return next(err);
  }
}

async function deleteAssignee(req, res, next) {
  try {
    const result = await loadTaskOrRespond(req, res, { manage: true });
    if (!result) {
      return undefined;
    }

    const { userId } = req.params;
    if (!mongoose.isValidObjectId(userId)) {
      return res.status(400).json({ message: 'Id người dùng không hợp lệ' });
    }

    await removeAssignee(result.task._id, req.user._id, userId);
    return respondWithTask(res, result.task._id, req.user._id);
  } catch (err) {
    return next(err);
  }
}

async function listShares(req, res, next) {
  try {
    const result = await loadTaskOrRespond(req, res);
    if (!result) {
      return undefined;
    }

    const shares = await findTaskShares(result.task._id);
    return res.status(200).json({ shares: shares.map(toShare) });
  } catch (err) {
    return next(err);
  }
}

async function createShares(req, res, next) {
  try {
    const result = await loadTaskOrRespond(req, res, { manage: true });
    if (!result) {
      return undefined;
    }

    const { value, error } = validateShareInput(req.body);
    if (error) {
      return res.status(400).json({ message: error });
    }

    await addShares(result.task._id, req.user._id, value.userIds, value.permission);
    return respondWithTask(res, result.task._id, req.user._id);
  } catch (err) {
    return next(err);
  }
}

async function changeShare(req, res, next) {
  try {
    const result = await loadTaskOrRespond(req, res, { manage: true });
    if (!result) {
      return undefined;
    }

    const { shareId } = req.params;
    if (!mongoose.isValidObjectId(shareId)) {
      return res.status(400).json({ message: 'Id lượt chia sẻ không hợp lệ' });
    }

    const { value, error } = validatePermissionInput(req.body);
    if (error) {
      return res.status(400).json({ message: error });
    }

    await updateShare(result.task._id, req.user._id, shareId, value.permission);
    return respondWithTask(res, result.task._id, req.user._id);
  } catch (err) {
    return next(err);
  }
}

async function deleteShare(req, res, next) {
  try {
    const result = await loadTaskOrRespond(req, res, { manage: true });
    if (!result) {
      return undefined;
    }

    const { shareId } = req.params;
    if (!mongoose.isValidObjectId(shareId)) {
      return res.status(400).json({ message: 'Id lượt chia sẻ không hợp lệ' });
    }

    await revokeShare(result.task._id, req.user._id, shareId);
    return respondWithTask(res, result.task._id, req.user._id);
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  changePrimaryAssignee,
  changeShare,
  createAssignees,
  createShares,
  deleteAssignee,
  deleteShare,
  listAssignees,
  listShares,
};
