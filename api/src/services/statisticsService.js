const Task = require('../models/Task');
const { buildAccessibleQuery } = require('./taskService');
const { toTaskSummary } = require('../utils/taskSerializer');

const DUE_SOON_DAYS = 7;
const DEADLINE_LIST_LIMIT = 20;
const STATUSES = ['todo', 'in_progress', 'completed'];
const PRIORITIES = ['low', 'medium', 'high'];

function endOfToday() {
  const now = new Date();
  return new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
}

function addDays(date, days) {
  return new Date(date.getTime() + days * 24 * 60 * 60 * 1000);
}

async function getTaskStatistics(userId) {
  const baseQuery = await buildAccessibleQuery(userId);

  const [total, statusCounts, priorityCounts] = await Promise.all([
    Task.countDocuments(baseQuery),
    Promise.all(
      STATUSES.map((status) => Task.countDocuments({ ...baseQuery, status }))
    ),
    Promise.all(
      PRIORITIES.map((priority) => Task.countDocuments({ ...baseQuery, priority }))
    ),
  ]);

  const byStatus = {};
  STATUSES.forEach((status, index) => {
    byStatus[status] = statusCounts[index];
  });

  const byPriority = {};
  PRIORITIES.forEach((priority, index) => {
    byPriority[priority] = priorityCounts[index];
  });

  const completed = byStatus.completed;
  const completionRate = total === 0 ? 0 : Math.round((completed / total) * 100);

  return {
    total,
    byStatus,
    byPriority,
    completed,
    completionRate,
  };
}

async function getAssignmentStatistics(userId) {
  const baseQuery = await buildAccessibleQuery(userId);
  const now = new Date();

  const rows = await Task.aggregate([
    { $match: baseQuery },
    { $unwind: '$assigneeIds' },
    {
      $group: {
        _id: '$assigneeIds',
        total: { $sum: 1 },
        completed: {
          $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] },
        },
        inProgress: {
          $sum: { $cond: [{ $eq: ['$status', 'in_progress'] }, 1, 0] },
        },
        todo: {
          $sum: { $cond: [{ $eq: ['$status', 'todo'] }, 1, 0] },
        },
        overdue: {
          $sum: {
            $cond: [
              {
                $and: [
                  { $ne: ['$status', 'completed'] },
                  { $ne: ['$dueDate', null] },
                  { $lt: ['$dueDate', now] },
                ],
              },
              1,
              0,
            ],
          },
        },
      },
    },
    {
      $lookup: {
        from: 'users',
        localField: '_id',
        foreignField: '_id',
        as: 'user',
      },
    },
    { $unwind: { path: '$user', preserveNullAndEmptyArrays: true } },
    {
      $project: {
        _id: 0,
        userId: '$_id',
        fullName: '$user.fullName',
        email: '$user.email',
        total: 1,
        completed: 1,
        inProgress: 1,
        todo: 1,
        overdue: 1,
      },
    },
    { $sort: { total: -1, fullName: 1 } },
  ]);

  return {
    totalAssignees: rows.length,
    assignments: rows,
  };
}

async function getDeadlineStatistics(userId) {
  const baseQuery = await buildAccessibleQuery(userId);
  const now = new Date();
  const tomorrow = endOfToday();
  const soon = addDays(tomorrow, DUE_SOON_DAYS);

  const activeQuery = {
    ...baseQuery,
    status: { $ne: 'completed' },
  };

  const [overdueCount, dueSoonCount, noDueDateCount, completedCount, overdue, dueSoon] =
    await Promise.all([
      Task.countDocuments({ ...activeQuery, dueDate: { $ne: null, $lt: now } }),
      Task.countDocuments({
        ...activeQuery,
        dueDate: { $ne: null, $gte: now, $lt: soon },
      }),
      Task.countDocuments({ ...activeQuery, dueDate: null }),
      Task.countDocuments({ ...baseQuery, status: 'completed' }),
      Task.find({ ...activeQuery, dueDate: { $ne: null, $lt: now } })
        .sort({ dueDate: 1 })
        .limit(DEADLINE_LIST_LIMIT)
        .populate('createdBy', 'fullName email')
        .populate('primaryAssigneeId', 'fullName email'),
      Task.find({
        ...activeQuery,
        dueDate: { $ne: null, $gte: now, $lt: soon },
      })
        .sort({ dueDate: 1 })
        .limit(DEADLINE_LIST_LIMIT)
        .populate('createdBy', 'fullName email')
        .populate('primaryAssigneeId', 'fullName email'),
    ]);

  return {
    overdueCount,
    dueSoonCount,
    noDueDateCount,
    completedCount,
    dueSoonDays: DUE_SOON_DAYS,
    overdue: overdue.map(toTaskSummary),
    dueSoon: dueSoon.map(toTaskSummary),
  };
}

module.exports = {
  DUE_SOON_DAYS,
  getAssignmentStatistics,
  getDeadlineStatistics,
  getTaskStatistics,
};
