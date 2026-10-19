import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { AppError } from '../../errors.js';
import type { AuthService } from './service.js';

const loginBody = z.strictObject({idToken: z.string().min(1).max(8192)});
const refreshBody = z.strictObject({refreshToken: z.string().regex(/^[A-Za-z0-9_-]{43}$/)});
const deleteAccountBody = z.strictObject({confirmation: z.literal('DELETE_MY_ACCOUNT')});

function validated<T>(schema: z.ZodType<T>, body: unknown): T {
  const parsed = schema.safeParse(body);
  if (!parsed.success) throw new AppError(400, 'VALIDATION_ERROR', 'Check the request fields and try again.');
  return parsed.data;
}

export function registerAuthRoutes(app: FastifyInstance, service: AuthService | undefined) {
  const auth = () => {
    if (!service) throw new AppError(503, 'AUTH_NOT_CONFIGURED', 'Sign-in is not available yet.');
    return service;
  };
  app.post('/api/v1/auth/google', {config: {rateLimit: {max: 10, timeWindow: '1 minute'}}}, async (request) => {
    const body = validated(loginBody, request.body);
    return {data: await auth().login(body.idToken), meta: {requestId: request.id}};
  });
  app.post('/api/v1/auth/refresh', {config: {rateLimit: {max: 30, timeWindow: '1 minute'}}}, async (request) => {
    const body = validated(refreshBody, request.body);
    return {data: await auth().refresh(body.refreshToken), meta: {requestId: request.id}};
  });
  app.post('/api/v1/auth/logout', async (request) => {
    await auth().logout(request.headers.authorization);
    return {data: {loggedOut: true}, meta: {requestId: request.id}};
  });
  app.delete('/api/v1/account', async (request) => {
    const body = validated(deleteAccountBody, request.body);
    await auth().deleteAccount(request.headers.authorization, body.confirmation);
    return {data: {deleted: true, details: 'Account and associated server records have been permanently deleted.'}, meta: {requestId: request.id}};
  });
  app.get('/api/v1/users/me', async (request) => ({
    data: await auth().me(request.headers.authorization), meta: {requestId: request.id},
  }));
}
