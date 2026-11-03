const statisticsService = require('../services/statisticsService');

async function getTaskStatistics(req, res, next) {
  try {
    const statistics = await statisticsService.getTaskStatistics(req.user._id);
    return res.status(200).json({ statistics });
  } catch (err) {
    return next(err);
  }
}

async function getAssignmentStatistics(req, res, next) {
  try {
    const statistics = await statisticsService.getAssignmentStatistics(req.user._id);
    return res.status(200).json({ statistics });
  } catch (err) {
    return next(err);
  }
}

async function getDeadlineStatistics(req, res, next) {
  try {
    const statistics = await statisticsService.getDeadlineStatistics(req.user._id);
    return res.status(200).json({ statistics });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  getAssignmentStatistics,
  getDeadlineStatistics,
  getTaskStatistics,
};
