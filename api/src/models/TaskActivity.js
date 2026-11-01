const mongoose = require('mongoose');

const TASK_ACTIVITY_ACTIONS = [
  'created',
  'updated',
  'status_changed',
  'assigned',
  'unassigned',
  'shared',
  'share_updated',
  'share_revoked',
  'deleted',
];

const taskActivitySchema = new mongoose.Schema(
  {
    taskId: { type: mongoose.Schema.Types.ObjectId, ref: 'Task', required: true },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    action: { type: String, enum: TASK_ACTIVITY_ACTIONS, required: true },
    details: { type: String, default: '' },
  },
  {
    timestamps: { createdAt: true, updatedAt: false },
    collection: 'task_activities',
  }
);

taskActivitySchema.index({ taskId: 1, createdAt: -1 });

module.exports = mongoose.model('TaskActivity', taskActivitySchema);
module.exports.TASK_ACTIVITY_ACTIONS = TASK_ACTIVITY_ACTIONS;
