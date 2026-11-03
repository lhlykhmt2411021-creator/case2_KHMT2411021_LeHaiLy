const express = require('express');
const statisticsController = require('../controllers/statisticsController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

router.use(authMiddleware);

router.get('/tasks', statisticsController.getTaskStatistics);
router.get('/assignments', statisticsController.getAssignmentStatistics);
router.get('/deadlines', statisticsController.getDeadlineStatistics);

module.exports = router;
