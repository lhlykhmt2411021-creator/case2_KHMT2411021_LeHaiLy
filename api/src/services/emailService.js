const nodemailer = require('nodemailer');
const EmailLog = require('../models/EmailLog');

let transporter = null;

function isConfigured() {
  return Boolean(process.env.SMTP_HOST && process.env.SMTP_PORT);
}

function getTransporter() {
  if (!isConfigured()) {
    return null;
  }
  if (!transporter) {
    const user = process.env.SMTP_USER;
    const pass = process.env.SMTP_PASS;
    transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port: Number(process.env.SMTP_PORT),
      secure: String(process.env.SMTP_SECURE).toLowerCase() === 'true',
      auth: user ? { user, pass } : undefined,
    });
  }
  return transporter;
}

function fromAddress() {
  return process.env.MAIL_FROM || process.env.SMTP_USER || 'no-reply@taskmanager.local';
}

async function deliver(log) {
  const mailer = getTransporter();
  log.attempts += 1;

  if (!mailer) {
    log.status = 'skipped';
    log.errorMessage = 'Chưa cấu hình SMTP';
    await log.save();
    return log;
  }

  try {
    const info = await mailer.sendMail({
      from: fromAddress(),
      to: log.recipientEmail,
      subject: log.subject,
      text: log.textBody,
    });
    log.status = 'sent';
    log.messageId = info.messageId || '';
    log.errorMessage = '';
    log.sentAt = new Date();
  } catch (error) {
    log.status = 'failed';
    log.errorMessage = error.message;
  }

  await log.save();
  return log;
}

async function sendEmail({
  taskId = null,
  userId = null,
  recipientEmail,
  eventType,
  subject,
  text,
}) {
  const log = await EmailLog.create({
    taskId,
    userId,
    recipientEmail,
    eventType,
    subject,
    textBody: text,
  });
  return deliver(log);
}

async function retryEmailLog(logId) {
  const log = await EmailLog.findById(logId);
  if (!log) {
    return null;
  }
  return deliver(log);
}

module.exports = { isConfigured, retryEmailLog, sendEmail };
