const express = require('express');
const { notFoundHandler, errorMiddleware } = require('./middleware/errorMiddleware');

const app = express();

app.use(express.json());

app.get('/', (req, res) => {
  res.status(200).json({ message: 'Task Manager API đang chạy' });
});

app.use(notFoundHandler);
app.use(errorMiddleware);

module.exports = app;
