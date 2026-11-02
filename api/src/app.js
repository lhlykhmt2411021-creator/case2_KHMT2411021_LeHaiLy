const express = require('express');
const authRoutes = require('./routes/authRoutes');
const taskRoutes = require('./routes/taskRoutes');
const userRoutes = require('./routes/userRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const emailLogRoutes = require('./routes/emailLogRoutes');
const { notFoundHandler, errorMiddleware } = require('./middleware/errorMiddleware');

const app = express();

app.use(express.json());

app.get('/', (req, res) => {
  res.status(200).json({ message: 'Task Manager API đang chạy' });
});

app.use('/api/auth', authRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/users', userRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/email-logs', emailLogRoutes);

app.use(notFoundHandler);
app.use(errorMiddleware);

module.exports = app;
