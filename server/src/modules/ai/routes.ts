import type { FastifyInstance, FastifyRequest } from 'fastify';
import { AppError } from '../../errors.js';
import type { AuthService } from '../auth/service.js';
import {
  AiService,
  chatRequestSchema,
  feedbackSchema,
} from './service.js';

export function registerAiRoutes(
  app: FastifyInstance,
  auth: AuthService | undefined,
  ai: AiService | undefined
) {
  const session = async (request: FastifyRequest) => {
    if (!auth) throw new AppError(503, 'AUTH_NOT_CONFIGURED', 'Sign-in is not available yet.');
    const verified = await auth.authenticate(request.headers.authorization);
    if (!ai) throw new AppError(503, 'SERVICE_NOT_READY', 'AI Assistant is not available yet.');
    return verified;
  };

  app.post('/api/v1/ai/chat', { config: { rateLimit: { max: 30, timeWindow: '1 minute' } } }, async (request) => {
    const verified = await session(request);
    const body = chatRequestSchema.safeParse(request.body);
    if (!body.success) {
      throw new AppError(400, 'VALIDATION_ERROR', 'Check your chat request format.');
    }
    const response = await ai!.chat(verified, body.data);
    return { data: response, meta: { requestId: request.id } };
  });

  app.post<{ Params: { id: string } }>('/api/v1/ai/actions/:id/confirm', async (request) => {
    const verified = await session(request);
    const result = await ai!.confirmAction(verified, request.params.id);
    return { data: result, meta: { requestId: request.id } };
  });

  app.post('/api/v1/ai/feedback', async (request) => {
    const verified = await session(request);
    const body = feedbackSchema.safeParse(request.body);
    if (!body.success) {
      throw new AppError(400, 'VALIDATION_ERROR', 'Check your feedback request format.');
    }
    await ai!.recordFeedback(verified, body.data.messageId, body.data.helpful);
    return { data: { recorded: true }, meta: { requestId: request.id } };
  });
}
