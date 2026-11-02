const express = require('express');
const emailLogController = require('../controllers/emailLogController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

router.use(authMiddleware);

router.post('/:id/retry', emailLogController.retryEmailLog);

module.exports = router;
