const express = require('express');
const path = require('path');
const app = express();

app.use(express.json());
app.use(express.static(path.join(__dirname, '../public')));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    version: process.env.APP_VERSION || '1.0.0',
    timestamp: new Date().toISOString(),
  });
});

// API: get all tasks
app.get('/api/tasks', (req, res) => {
  res.json({ tasks: [] });
});

// API: add task
app.post('/api/tasks', (req, res) => {
  const { title } = req.body;
  if (!title || title.trim() === '') {
    return res.status(400).json({ error: 'Title is required' });
  }
  const task = { id: Date.now(), title: title.trim(), done: false };
  res.status(201).json({ task });
});

// Math utility route (used in tests)
app.get('/api/add', (req, res) => {
  const a = parseFloat(req.query.a);
  const b = parseFloat(req.query.b);
  if (isNaN(a) || isNaN(b)) {
    return res.status(400).json({ error: 'Invalid numbers' });
  }
  res.json({ result: a + b });
});

module.exports = app;
