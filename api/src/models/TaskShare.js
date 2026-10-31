const mongoose = require('mongoose');

const TASK_SHARE_PERMISSIONS = ['viewer', 'editor'];

const taskShareSchema = new mongoose.Schema(
  {
    taskId: { type: mongoose.Schema.Types.ObjectId, ref: 'Task', required: true },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    permission: { type: String, enum: TASK_SHARE_PERMISSIONS, default: 'viewer' },
    sharedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  },
  {
    timestamps: { createdAt: true, updatedAt: false },
    collection: 'task_shares',
  }
);

taskShareSchema.index({ taskId: 1, userId: 1 }, { unique: true });

module.exports = mongoose.model('TaskShare', taskShareSchema);
module.exports.TASK_SHARE_PERMISSIONS = TASK_SHARE_PERMISSIONS;
