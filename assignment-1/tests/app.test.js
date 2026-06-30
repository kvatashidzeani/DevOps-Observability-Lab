const request = require('supertest');
const app = require('../src/app');

describe('Health Check', () => {
  it('GET /health should return 200 and status ok', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('ok');
    expect(res.body).toHaveProperty('timestamp');
  });
});

describe('Tasks API', () => {
  it('GET /api/tasks should return empty tasks array', async () => {
    const res = await request(app).get('/api/tasks');
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('tasks');
    expect(Array.isArray(res.body.tasks)).toBe(true);
  });

  it('POST /api/tasks should create a task with valid title', async () => {
    const res = await request(app)
      .post('/api/tasks')
      .send({ title: 'Deploy to production' });
    expect(res.statusCode).toBe(201);
    expect(res.body.task.title).toBe('Deploy to production');
    expect(res.body.task).toHaveProperty('id');
    expect(res.body.task.done).toBe(false);
  });

  it('POST /api/tasks should return 400 if title is missing', async () => {
    const res = await request(app)
      .post('/api/tasks')
      .send({});
    expect(res.statusCode).toBe(400);
    expect(res.body).toHaveProperty('error');
  });

  it('POST /api/tasks should return 400 if title is empty string', async () => {
    const res = await request(app)
      .post('/api/tasks')
      .send({ title: '   ' });
    expect(res.statusCode).toBe(400);
  });
});

describe('Math API', () => {
  it('GET /api/add should add two numbers', async () => {
    const res = await request(app).get('/api/add?a=5&b=3');
    expect(res.statusCode).toBe(200);
    expect(res.body.result).toBe(8);
  });

  it('GET /api/add should handle floats', async () => {
    const res = await request(app).get('/api/add?a=1.5&b=2.5');
    expect(res.statusCode).toBe(200);
    expect(res.body.result).toBe(4);
  });

  it('GET /api/add should return 400 for invalid input', async () => {
    const res = await request(app).get('/api/add?a=abc&b=1');
    expect(res.statusCode).toBe(400);
  });
});
