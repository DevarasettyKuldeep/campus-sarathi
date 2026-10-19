import { OAuth2Client } from 'google-auth-library';
import { AppError } from '../../errors.js';
import type { IdentityVerifier, VerifiedIdentity } from './types.js';

const domain = 'cb.students.amrita.edu';

export class GoogleIdentityVerifier implements IdentityVerifier {
  constructor(private readonly audiences: string[],
    private readonly client = new OAuth2Client({transporterOptions: {timeout: 5_000, retry: false}})) {
    if (audiences.length === 0) throw new Error('Google audience configuration is required.');
    // The library explicitly enables retries on certificate fetches, overriding
    // transporter defaults. Keep the actual outgoing request bounded as well.
    this.client.transporter.interceptors.request.add({resolved: async (request) => {
      request.timeout = 5_000;
      request.retry = false;
      request.retryConfig = {...request.retryConfig, retry: 0};
      return request;
    }});
  }

  async verify(idToken: string): Promise<VerifiedIdentity> {
    try {
      const ticket = await this.client.verifyIdToken({idToken, audience: this.audiences});
      const payload = ticket.getPayload();
      // Google's library verifies signature, issuer, audience and expiry.
      // A matching email suffix alone does not establish Workspace membership.
      if (!payload?.sub || payload.email_verified !== true || !payload.email ||
          payload.hd !== domain || payload.email.toLowerCase().split('@').length !== 2 ||
          payload.email.toLowerCase().split('@')[1] !== domain) {
        throw new AppError(403, 'STUDENT_ACCOUNT_REQUIRED', 'Use an eligible university-managed student Google account.');
      }
      if (payload.exp <= Math.floor(Date.now() / 1000)) {
        throw new AppError(401, 'INVALID_IDENTITY', 'Google sign-in could not be verified.');
      }
      return {googleSubject: payload.sub, email: payload.email.toLowerCase(),
        displayName: (payload.name?.trim() || 'Student').slice(0, 200)};
    } catch (error) {
      if (error instanceof AppError) throw error;
      const response = typeof error === 'object' && error !== null && 'response' in error
        ? error.response : undefined;
      const status = typeof response === 'object' && response !== null && 'status' in response
        ? response.status : undefined;
      // Network errors have a code; never forward their URLs, tokens or messages.
      if ((typeof status === 'number' && (status >= 500 || status === 429)) ||
          (typeof error === 'object' && error !== null && 'code' in error &&
          ['ETIMEDOUT', 'ECONNRESET', 'ENOTFOUND', 'EAI_AGAIN', 'ECONNREFUSED'].includes(String(error.code)))) {
        throw new AppError(503, 'IDENTITY_UNAVAILABLE', 'Google verification is unavailable. Please retry later.');
      }
      throw new AppError(401, 'INVALID_IDENTITY', 'Google sign-in could not be verified.');
    }
  }
}
