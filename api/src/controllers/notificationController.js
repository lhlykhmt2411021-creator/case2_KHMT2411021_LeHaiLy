const mongoose = require('mongoose');
const Notification = require('../models/Notification');
const { toUserRef } = require('../utils/taskSerializer');

const INVALID_ID_MESSAGE = 'Id thông báo không hợp lệ';
const NOT_FOUND_MESSAGE = 'Không tìm thấy thông báo';

function toNotification(notification) {
  return {
    id: notification._id.toString(),
    type: notification.type,
    title: notification.title,
    message: notification.message,
    isRead: notification.isRead,
    taskId: notification.taskId ? notification.taskId.toString() : null,
    actor: toUserRef(notification.actorId),
    createdAt: notification.createdAt,
  };
}

async function listNotifications(req, res, next) {
  try {
    const { isRead, limit } = req.query;
    const query = { userId: req.user._id };

    if (isRead !== undefined) {
      if (isRead !== 'true' && isRead !== 'false') {
        return res.status(400).json({ message: 'isRead phải là true hoặc false' });
      }
      query.isRead = isRead === 'true';
    }

    let max = 50;
    if (limit !== undefined) {
      const parsed = Number(limit);
      if (!Number.isInteger(parsed) || parsed <= 0 || parsed > 100) {
        return res.status(400).json({ message: 'limit phải là số nguyên từ 1 đến 100' });
      }
      max = parsed;
    }

    const notifications = await Notification.find(query)
      .sort({ createdAt: -1 })
      .limit(max)
      .populate('actorId', 'fullName email');
    const unreadCount = await Notification.countDocuments({
      userId: req.user._id,
      isRead: false,
    });

    return res.status(200).json({
      notifications: notifications.map(toNotification),
      unreadCount,
    });
  } catch (err) {
    return next(err);
  }
}

async function getUnreadCount(req, res, next) {
  try {
    const unreadCount = await Notification.countDocuments({
      userId: req.user._id,
      isRead: false,
    });
    return res.status(200).json({ unreadCount });
  } catch (err) {
    return next(err);
  }
}

async function markNotificationRead(req, res, next) {
  try {
    const { id } = req.params;
    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({ message: INVALID_ID_MESSAGE });
    }

    const notification = await Notification.findOneAndUpdate(
      { _id: id, userId: req.user._id },
      { isRead: true },
      { new: true }
    ).populate('actorId', 'fullName email');

    if (!notification) {
      return res.status(404).json({ message: NOT_FOUND_MESSAGE });
    }

    return res.status(200).json({ notification: toNotification(notification) });
  } catch (err) {
    return next(err);
  }
}

async function markAllRead(req, res, next) {
  try {
    const result = await Notification.updateMany(
      { userId: req.user._id, isRead: false },
      { isRead: true }
    );
    return res.status(200).json({ updated: result.modifiedCount });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  getUnreadCount,
  listNotifications,
  markAllRead,
  markNotificationRead,
};
