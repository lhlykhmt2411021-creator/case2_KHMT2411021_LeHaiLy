const mongoose = require('mongoose');
const EmailLog = require('../models/EmailLog');
const { getTaskWithAccess } = require('../services/taskService');
const { retryEmailLog: retryEmailLogService } = require('../services/emailService');

const MAX_ATTEMPTS = 3;

function toEmailLog(log) {
  return {
    id: log._id.toString(),
    taskId: log.taskId ? log.taskId.toString() : null,
    recipientEmail: log.recipientEmail,
    eventType: log.eventType,
    subject: log.subject,
    status: log.status,
    attempts: log.attempts,
    errorMessage: log.errorMessage,
    sentAt: log.sentAt,
    createdAt: log.createdAt,
  };
}

async function listTaskEmailLogs(req, res, next) {
  try {
    const { id } = req.params;
    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({ message: 'Id không hợp lệ' });
    }

    const { task, role } = await getTaskWithAccess(id, req.user._id);
    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc' });
    }
    if (role !== 'creator') {
      return res.status(403).json({ message: 'Chỉ người tạo mới được xem lịch sử email' });
    }

    const logs = await EmailLog.find({ taskId: task._id }).sort({ createdAt: -1 });
    return res.status(200).json({ emailLogs: logs.map(toEmailLog) });
  } catch (err) {
    return next(err);
  }
}

async function retryEmailLog(req, res, next) {
  try {
    const { id } = req.params;
    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({ message: 'Id email log không hợp lệ' });
    }

    const log = await EmailLog.findById(id);
    if (!log) {
      return res.status(404).json({ message: 'Không tìm thấy email log' });
    }

    if (log.taskId) {
      const { task, role } = await getTaskWithAccess(log.taskId, req.user._id);
      if (!task) {
        return res.status(404).json({ message: 'Không tìm thấy công việc' });
      }
      if (role !== 'creator') {
        return res.status(403).json({ message: 'Chỉ người tạo mới được gửi lại email' });
      }
    }

    if (log.attempts >= MAX_ATTEMPTS) {
      return res.status(400).json({ message: 'Email đã vượt quá số lần gửi lại cho phép' });
    }

    const updated = await retryEmailLogService(log._id);
    return res.status(200).json({ emailLog: toEmailLog(updated) });
  } catch (err) {
    return next(err);
  }
}

module.exports = { listTaskEmailLogs, retryEmailLog };
