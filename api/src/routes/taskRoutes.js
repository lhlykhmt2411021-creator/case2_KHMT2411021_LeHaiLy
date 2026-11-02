const express = require('express');
const taskController = require('../controllers/taskController');
const collaborationController = require('../controllers/collaborationController');
const emailLogController = require('../controllers/emailLogController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

router.use(authMiddleware);

router.get('/', taskController.listTasks);
router.post('/', taskController.createTask);

router.get('/:id/activities', taskController.listActivities);
router.get('/:id/email-logs', emailLogController.listTaskEmailLogs);
router.patch('/:id/status', taskController.updateStatus);

router.get('/:id/assignees', collaborationController.listAssignees);
router.post('/:id/assignees', collaborationController.createAssignees);
router.patch('/:id/assignees/:userId', collaborationController.changePrimaryAssignee);
router.delete('/:id/assignees/:userId', collaborationController.deleteAssignee);

router.get('/:id/shares', collaborationController.listShares);
router.post('/:id/shares', collaborationController.createShares);
router.patch('/:id/shares/:shareId', collaborationController.changeShare);
router.delete('/:id/shares/:shareId', collaborationController.deleteShare);

router.get('/:id', taskController.getTask);
router.put('/:id', taskController.updateTask);
router.delete('/:id', taskController.deleteTask);

module.exports = router;
