import type { FastifyInstance, FastifyRequest } from 'fastify';
import { AppError } from '../../errors.js';
import type { AuthService } from '../auth/service.js';
import { academicNotice, consentInput, profileInput, profileSyncInput, type ProfileService } from './service.js';

export function registerProfileRoutes(app: FastifyInstance, auth: AuthService | undefined,
  profiles: ProfileService | undefined, production: boolean) {
  const session = async (request: FastifyRequest) => {
    if (!auth) throw new AppError(503, 'AUTH_NOT_CONFIGURED', 'Sign-in is not available yet.');
    const verified = await auth.authenticate(request.headers.authorization);
    if (!profiles) throw new AppError(503, 'SERVICE_NOT_READY', 'Academic storage is not available yet.');
    if (production) throw new AppError(503, 'PRIVACY_NOT_READY', 'Public academic onboarding is not available yet.');
    return verified;
  };
  app.get('/api/v1/privacy/notice', async request => ({
    data: academicNotice, meta: {requestId: request.id},
  }));
  app.get('/api/v1/privacy/consent', async request => {
    const verified = await session(request);
    return {data: await profiles!.consent(verified), meta: {requestId: request.id}};
  });
  app.post('/api/v1/privacy/consent', async request => {
    const verified = await session(request);
    const body = consentInput.safeParse(request.body);
    if (!body.success) throw new AppError(400, 'VALIDATION_ERROR', 'Check your consent request fields.');
    return {data: await profiles!.setConsent(verified, body.data), meta: {requestId: request.id}};
  });
  app.get('/api/v1/users/me/profile', async request => {
    const verified = await session(request);
    return {data: await profiles!.get(verified), meta: {requestId: request.id}};
  });
  app.put('/api/v1/users/me/profile', async request => {
    const verified = await session(request);
    const body = profileInput.safeParse(request.body);
    if (!body.success) throw new AppError(400, 'VALIDATION_ERROR', 'Check programme, semester and date fields.');
    return {data: await profiles!.save(verified, body.data), meta: {requestId: request.id}};
  });
  app.post('/api/v1/sync/profile', async request => {
    const verified = await session(request);
    const body = profileSyncInput.safeParse(request.body);
    if (!body.success) throw new AppError(400, 'VALIDATION_ERROR', 'Check the profile sync operation.');
    return {data: await profiles!.sync(verified, body.data), meta: {requestId: request.id}};
  });
}
