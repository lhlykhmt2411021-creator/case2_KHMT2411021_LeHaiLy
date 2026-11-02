const Notification = require('../models/Notification');
const User = require('../models/User');
const emailService = require('./emailService');
const { buildEmail } = require('../utils/emailTemplates');

function toId(value) {
  if (!value) {
    return null;
  }
  return String(value._id ?? value);
}

function uniqueIds(values) {
  return [...new Set(values.filter(Boolean).map(toId))];
}

async function findUsers(userIds) {
  if (userIds.length === 0) {
    return [];
  }
  return User.find({ _id: { $in: userIds } }).select('fullName email');
}

async function notifyRecipients({
  task,
  actorId,
  actorName,
  recipients,
  type,
  title,
  message,
  emailEvent,
}) {
  const actor = actorId ? String(actorId) : null;
  const targets = recipients.filter(
    (user) => user && user._id && String(user._id) !== actor
  );

  if (targets.length === 0) {
    return [];
  }

  let senderName = actorName;
  if (!senderName && actorId) {
    const actorUser = await User.findById(actorId).select('fullName');
    senderName = actorUser ? actorUser.fullName : 'Một thành viên';
  }

  const notifications = await Notification.insertMany(
    targets.map((user) => ({
      userId: user._id,
      taskId: task ? task._id : null,
      actorId: actorId || null,
      type,
      title,
      message,
    }))
  );

  if (emailEvent && task) {
    for (const user of targets) {
      if (!user.email) {
        continue;
      }
      const mail = buildEmail(emailEvent, {
        task,
        recipient: user,
        actorName: senderName || 'Một thành viên',
      });
      await emailService.sendEmail({
        taskId: task._id,
        userId: user._id,
        recipientEmail: user.email,
        eventType: emailEvent,
        subject: mail.subject,
        text: mail.text,
      });
    }
  }

  return notifications;
}

async function notifyTaskMembers({
  task,
  actorId,
  actorName,
  type,
  title,
  message,
  emailEvent,
  extraUserIds = [],
}) {
  const memberIds = uniqueIds([
    task.createdBy,
    ...(task.assigneeIds || []),
    ...extraUserIds,
  ]);
  const users = await findUsers(memberIds);
  return notifyRecipients({
    task,
    actorId,
    actorName,
    recipients: users,
    type,
    title,
    message,
    emailEvent,
  });
}

module.exports = { findUsers, notifyRecipients, notifyTaskMembers };
