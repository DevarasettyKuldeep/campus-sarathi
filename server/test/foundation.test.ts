import assert from 'node:assert/strict';
import { test } from 'node:test';
import { buildApp } from '../src/app.js';
import { readEnvironment } from '../src/config/env.js';

const config = readEnvironment({NODE_ENV: 'test', LOG_LEVEL: 'silent'});

test('environment rejects wrong database protocol and invalid port without leaking input', () => {
  assert.throws(() => readEnvironment({PORT: '0'}), /PORT/);
  assert.throws(() => readEnvironment({DATABASE_URL: 'mysql://private-password@localhost/db'}), (error: unknown) => {
    assert(error instanceof Error);
    assert(!error.message.includes('private-password'));
    return error.message.includes('DATABASE_URL');
  });
  assert.throws(() => readEnvironment({NODE_ENV: 'production'}), /DATABASE_URL/);
  assert.equal(config.HOST, '127.0.0.1');
});

test('health is process liveness; readiness stays unavailable without real dependency', async (t) => {
  const app = await buildApp({config});
  t.after(() => app.close());
  const health = await app.inject({url: '/api/v1/health', headers: {'x-request-id': 'client-controlled'}});
  assert.equal(health.statusCode, 200);
  assert.equal(health.json().data.scope, 'process');
  assert.notEqual(health.headers['x-request-id'], 'client-controlled');
  assert.equal(health.json().meta.requestId, health.headers['x-request-id']);
  assert.equal(health.headers['cache-control'], 'no-store');
  assert.equal(health.headers['x-content-type-options'], 'nosniff');
  assert.equal((await app.inject('/api/v1/ready')).statusCode, 503);
  assert.equal((await app.inject('/api/v1/users/me')).statusCode, 503);
  assert.equal((await app.inject('/api/v1/users/me')).json().error.code, 'AUTH_NOT_CONFIGURED');
});

test('readiness handles both probe success and failure without exposing details', async (t) => {
  const available = await buildApp({config, readiness: async () => true});
  const unavailable = await buildApp({config, readiness: async () => { throw new Error('private-database-password'); }});
  t.after(async () => { await available.close(); await unavailable.close(); });
  assert.equal((await available.inject('/api/v1/ready')).statusCode, 200);
  const failed = await unavailable.inject('/api/v1/ready');
  assert.equal(failed.statusCode, 503);
  assert(!failed.body.includes('private-database-password'));
});

test('internal errors and malformed JSON use a consistent safe envelope', async (t) => {
  const app = await buildApp({config});
  app.post('/test-failure', () => { throw new Error('private-provider-token'); });
  t.after(() => app.close());
  const response = await app.inject({method: 'POST', url: '/test-failure'});
  assert.equal(response.statusCode, 500);
  assert.equal(response.json().error.code, 'INTERNAL_ERROR');
  assert(!response.body.includes('private-provider-token'));
  const malformed = await app.inject({method: 'POST', url: '/test-failure',
    headers: {'content-type': 'application/json'}, payload: '{broken'});
  assert.equal(malformed.statusCode, 400);
  assert.equal(malformed.json().error.code, 'INVALID_REQUEST');
  const oversized = await app.inject({method: 'POST', url: '/test-failure',
    headers: {'content-type': 'application/json'}, payload: JSON.stringify({text: 'x'.repeat(70_000)})});
  assert.equal(oversized.statusCode, 413);
});

test('rate limit is enforced with retry timing', async (t) => {
  const app = await buildApp({config});
  t.after(() => app.close());
  for (let index = 0; index < 120; index++) {
    assert.equal((await app.inject('/api/v1/health')).statusCode, 200);
  }
  const response = await app.inject('/api/v1/health');
  assert.equal(response.statusCode, 429);
  assert.equal(response.json().error.code, 'RATE_LIMITED');
  assert(response.headers['retry-after']);
});

test('server responds over an actual TCP connection', async (t) => {
  const app = await buildApp({config});
  t.after(() => app.close());
  const address = await app.listen({host: '127.0.0.1', port: 0});
  const response = await fetch(`${address}/api/v1/health`);
  assert.equal(response.status, 200);
  const result = await response.json() as {data: {status: string}};
  assert.equal(result.data.status, 'ok');
});
