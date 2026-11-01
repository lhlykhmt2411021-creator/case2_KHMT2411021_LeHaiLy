const express = require('express');
const userController = require('../controllers/userController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

router.use(authMiddleware);

router.get('/search', userController.searchUsers);
router.get('/:id', userController.getUserById);

module.exports = router;
