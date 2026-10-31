const express = require('express');

const app = express();

app.use(express.json());

app.get('/api/health', (req, res) => {
  res.status(200).json({ message: 'Task Manager API is running' });
});

app.use((req, res) => {
  res.status(404).json({ message: 'Khong tim thay endpoint' });
});

module.exports = app;
