const { TASK_PRIORITIES, TASK_STATUSES } = require('../models/Task');

const MAX_TITLE_LENGTH = 200;
const MAX_DESCRIPTION_LENGTH = 2000;

function parseDateField(value) {
  if (value === undefined || value === null || value === '') {
    return { value: null };
  }
  if (typeof value !== 'string' && !(value instanceof Date)) {
    return { error: 'Ngày không hợp lệ' };
  }
  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) {
    return { error: 'Ngày không hợp lệ' };
  }
  return { value: date };
}

function validateTaskFields(body = {}) {
  const title = typeof body.title === 'string' ? body.title.trim() : '';
  if (!title) {
    return { error: 'Tiêu đề không được để trống' };
  }
  if (title.length > MAX_TITLE_LENGTH) {
    return { error: `Tiêu đề không được vượt quá ${MAX_TITLE_LENGTH} ký tự` };
  }

  let description = '';
  if (body.description !== undefined && body.description !== null) {
    if (typeof body.description !== 'string') {
      return { error: 'Mô tả không hợp lệ' };
    }
    description = body.description.trim();
  }
  if (description.length > MAX_DESCRIPTION_LENGTH) {
    return { error: `Mô tả không được vượt quá ${MAX_DESCRIPTION_LENGTH} ký tự` };
  }

  const priority = body.priority === undefined ? 'medium' : body.priority;
  if (!TASK_PRIORITIES.includes(priority)) {
    return { error: 'Mức ưu tiên không hợp lệ' };
  }

  const startDate = parseDateField(body.startDate);
  if (startDate.error) {
    return { error: 'Ngày bắt đầu không hợp lệ' };
  }
  const dueDate = parseDateField(body.dueDate);
  if (dueDate.error) {
    return { error: 'Hạn hoàn thành không hợp lệ' };
  }
  if (startDate.value && dueDate.value && dueDate.value < startDate.value) {
    return { error: 'Hạn hoàn thành phải sau hoặc bằng ngày bắt đầu' };
  }

  return {
    value: {
      title,
      description,
      priority,
      startDate: startDate.value,
      dueDate: dueDate.value,
    },
  };
}

function validateCreateTaskInput(body = {}) {
  const { value, error } = validateTaskFields(body);
  if (error) {
    return { error };
  }

  const status = body.status === undefined ? 'todo' : body.status;
  if (!TASK_STATUSES.includes(status)) {
    return { error: 'Trạng thái không hợp lệ' };
  }

  return { value: { ...value, status } };
}

function validateUpdateTaskInput(body = {}) {
  return validateTaskFields(body);
}

function validateStatusInput(body = {}) {
  const status = body.status;
  if (!TASK_STATUSES.includes(status)) {
    return { error: 'Trạng thái không hợp lệ' };
  }
  return { value: { status } };
}

module.exports = {
  MAX_TITLE_LENGTH,
  MAX_DESCRIPTION_LENGTH,
  validateCreateTaskInput,
  validateUpdateTaskInput,
  validateStatusInput,
};
