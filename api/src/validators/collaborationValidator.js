const mongoose = require('mongoose');
const { TASK_SHARE_PERMISSIONS } = require('../models/TaskShare');

const INVALID_USER_ID_MESSAGE = 'Id người dùng không hợp lệ';

function normalizeUserIds(body = {}) {
  let raw;
  if (Array.isArray(body.userIds)) {
    raw = body.userIds;
  } else if (body.userId !== undefined) {
    raw = [body.userId];
  } else {
    raw = [];
  }

  const userIds = [];
  for (const value of raw) {
    if (typeof value !== 'string' || !mongoose.isValidObjectId(value)) {
      return { error: INVALID_USER_ID_MESSAGE };
    }
    if (!userIds.includes(value)) {
      userIds.push(value);
    }
  }

  if (userIds.length === 0) {
    return { error: 'Vui lòng chọn ít nhất một người dùng' };
  }

  return { value: { userIds } };
}

function validateAssigneesInput(body = {}) {
  const { value, error } = normalizeUserIds(body);
  if (error) {
    return { error };
  }

  const { userIds } = value;
  let primaryAssigneeId = body.primaryAssigneeId;
  if (primaryAssigneeId === undefined || primaryAssigneeId === null || primaryAssigneeId === '') {
    primaryAssigneeId = userIds[0];
  } else if (
    typeof primaryAssigneeId !== 'string' ||
    !mongoose.isValidObjectId(primaryAssigneeId)
  ) {
    return { error: INVALID_USER_ID_MESSAGE };
  }

  if (!userIds.includes(primaryAssigneeId)) {
    return { error: 'Người phụ trách chính phải nằm trong danh sách được giao' };
  }

  return { value: { userIds, primaryAssigneeId } };
}

function validateShareInput(body = {}) {
  const { value, error } = normalizeUserIds(body);
  if (error) {
    return { error };
  }

  const permission = body.permission === undefined ? 'viewer' : body.permission;
  if (!TASK_SHARE_PERMISSIONS.includes(permission)) {
    return { error: 'Quyền chia sẻ không hợp lệ' };
  }

  return { value: { userIds: value.userIds, permission } };
}

function validatePermissionInput(body = {}) {
  const permission = body.permission;
  if (!TASK_SHARE_PERMISSIONS.includes(permission)) {
    return { error: 'Quyền chia sẻ không hợp lệ' };
  }
  return { value: { permission } };
}

module.exports = {
  INVALID_USER_ID_MESSAGE,
  validateAssigneesInput,
  validatePermissionInput,
  validateShareInput,
};
