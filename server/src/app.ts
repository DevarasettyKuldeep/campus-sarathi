import { randomUUID } from 'node:crypto';
import Fastify, { LogController } from 'fastify';
import helmet from '@fastify/helmet';
import rateLimit from '@fastify/rate-limit';
import type { Environment } from './config/env.js';
import { AppError } from './errors.js';
import type { AuthService } from './modules/auth/service.js';
import { registerAuthRoutes } from './modules/auth/routes.js';
import type { ProfileService } from './modules/profile/service.js';
import { registerProfileRoutes } from './modules/profile/routes.js';
import type { AiService } from './modules/ai/service.js';
import { registerAiRoutes } from './modules/ai/routes.js';
import type { AcademicService } from './modules/academic/service.js';
import { registerAcademicRoutes } from './modules/academic/routes.js';

export interface AppOptions {
  config: Environment;
  /** A real bounded infrastructure probe will be wired by the Prisma module. */
  readiness?: () => Promise<boolean>;
  auth?: AuthService;
  profiles?: ProfileService;
  ai?: AiService;
  academic?: AcademicService;
}

export async function buildApp({ config, readiness, auth, profiles, ai, academic }: AppOptions) {
  const app = Fastify({
    logger: config.LOG_LEVEL === 'silent' ? false : {
      level: config.LOG_LEVEL,
      redact: ['req.headers.authorization', 'req.headers.cookie', 'res.headers["set-cookie"]'],
    },
    logController: new LogController({disableRequestLogging: true}),
    requestIdHeader: false,
    genReqId: () => randomUUID(),
    trustProxy: false,
    bodyLimit: 64 * 1024,
    requestTimeout: 15_000,
    connectionTimeout: 10_000,
    return503OnClosing: true,
  });
  await app.register(helmet);
  await app.register(rateLimit, {
    max: 120,
    timeWindow: '1 minute',
    errorResponseBuilder: () => ({statusCode: 429}),
  });

  app.addHook('onSend', async (request, reply) => {
    reply.header('x-request-id', request.id);
    reply.header('cache-control', 'no-store');
  });
  app.addHook('onResponse', async (request, reply) => {
    // Do not log URLs, query strings, credentials, bodies or academic records.
    request.log.info({route: request.routeOptions.url ?? 'unmatched',
      status: reply.statusCode}, 'Request completed');
  });
  app.setNotFoundHandler((request, reply) => reply.code(404).send({
    error: {code: 'NOT_FOUND', message: 'Resource not found.'}, requestId: request.id,
  }));
  app.setErrorHandler((error, request, reply) => {
    if (error instanceof AppError) {
      return reply.code(error.statusCode).send({
        error: {code: error.code, message: error.message}, requestId: request.id,
      });
    }
    const requestedStatus = typeof error === 'object' && error !== null && 'statusCode' in error
      ? error.statusCode : undefined;
    const status = typeof requestedStatus === 'number' && requestedStatus >= 400 && requestedStatus < 500
      ? requestedStatus : 500;
    const code = status === 413 ? 'PAYLOAD_TOO_LARGE' : status === 429 ? 'RATE_LIMITED'
      : status === 415 ? 'UNSUPPORTED_MEDIA_TYPE' : status < 500 ? 'INVALID_REQUEST' : 'INTERNAL_ERROR';
    const message = status === 500 ? 'The request could not be completed.'
      : status === 429 ? 'Too many requests. Try again shortly.' : 'Check the request and try again.';
    if (status === 500) request.log.error('Internal request failure');
    return reply.code(status).send({error: {code, message}, requestId: request.id});
  });

  app.get('/api/v1/health', async (request) => ({
    data: {status: 'ok', scope: 'process'}, meta: {requestId: request.id},
  }));
  app.get('/api/v1/ready', async (request, reply) => {
    let available = false;
    if (readiness) {
      try { available = await readiness(); } catch { /* Return a safe unavailable response. */ }
    }
    if (!available) return reply.code(503).send({
      error: {code: 'SERVICE_NOT_READY', message: 'Required infrastructure is not ready.'},
      requestId: request.id,
    });
    return {data: {status: 'ready'}, meta: {requestId: request.id}};
  });
  registerAuthRoutes(app, auth);
  registerProfileRoutes(app, auth, profiles, config.NODE_ENV === 'production');
  registerAcademicRoutes(app, auth, academic, config.NODE_ENV === 'production');
  registerAiRoutes(app, auth, ai);
  return app;
}
