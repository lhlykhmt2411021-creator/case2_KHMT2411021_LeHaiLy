const mongoose = require('mongoose');

const EMAIL_LOG_STATUSES = ['pending', 'sent', 'failed', 'skipped'];

const emailLogSchema = new mongoose.Schema(
  {
    taskId: { type: mongoose.Schema.Types.ObjectId, ref: 'Task', default: null },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    recipientEmail: { type: String, required: true },
    eventType: { type: String, required: true },
    subject: { type: String, required: true },
    textBody: { type: String, default: '' },
    status: { type: String, enum: EMAIL_LOG_STATUSES, default: 'pending' },
    attempts: { type: Number, default: 0 },
    errorMessage: { type: String, default: '' },
    messageId: { type: String, default: '' },
    sentAt: { type: Date, default: null },
  },
  {
    timestamps: { createdAt: true, updatedAt: false },
    collection: 'email_logs',
  }
);

emailLogSchema.index({ taskId: 1, createdAt: -1 });
emailLogSchema.index({ status: 1 });

module.exports = mongoose.model('EmailLog', emailLogSchema);
module.exports.EMAIL_LOG_STATUSES = EMAIL_LOG_STATUSES;
