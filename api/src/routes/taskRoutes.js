const express = require('express');
const taskController = require('../controllers/taskController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

router.use(authMiddleware);

router.get('/', taskController.listTasks);
router.get('/:id', taskController.getTask);

module.exports = router;
