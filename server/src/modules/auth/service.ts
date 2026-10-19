import { createHash, randomBytes } from 'node:crypto';
import { SignJWT, jwtVerify, errors as joseErrors } from 'jose';
import { z } from 'zod';
import { AppError } from '../../errors.js';
import type { AuthRepository, IdentityVerifier, Session } from './types.js';

const issuer = 'campus-sarathi-api';
const audience = 'campus-sarathi-mobile';
const accessSeconds = 15 * 60;
const refreshMilliseconds = 30 * 24 * 60 * 60 * 1000;
const claims = z.object({sub: z.uuid(), sid: z.uuid(), iat: z.number(), exp: z.number()});

export const hashRefreshToken = (token: string) => createHash('sha256').update(token).digest();

export class AuthService {
  private readonly key: Uint8Array;
  constructor(private readonly repository: AuthRepository, private readonly identity: IdentityVerifier,
    signingKey: string, private readonly clock: () => Date = () => new Date()) {
    this.key = Buffer.from(signingKey, 'base64url');
    if (this.key.byteLength < 32) throw new Error('Session signing key must contain at least 32 random bytes.');
  }

  async login(idToken: string) {
    const identity = await this.identity.verify(idToken);
    const now = this.clock();
    const refreshToken = randomBytes(32).toString('base64url');
    const login = await this.repository.login(identity, hashRefreshToken(refreshToken), now,
      new Date(now.getTime() + refreshMilliseconds));
    return {account: login.account, ...await this.tokens(login.session, refreshToken, now)};
  }

  async refresh(refreshToken: string) {
    const nextToken = randomBytes(32).toString('base64url');
    const now = this.clock();
    const result = await this.repository.rotate(hashRefreshToken(refreshToken), hashRefreshToken(nextToken), now);
    if (result.kind !== 'ok') throw new AppError(401, 'INVALID_SESSION', 'Sign in again to continue.');
    return this.tokens(result.session, nextToken, now);
  }

  async authenticate(authorization: string | undefined): Promise<Session> {
    if (!authorization || !/^Bearer [A-Za-z0-9_.-]+$/.test(authorization) || authorization.length > 4096) {
      throw new AppError(401, 'INVALID_SESSION', 'Sign in to continue.');
    }
    try {
      const now = this.clock();
      const {payload} = await jwtVerify(authorization.slice(7), this.key, {
        algorithms: ['HS256'], issuer, audience, currentDate: now,
        requiredClaims: ['iat', 'exp', 'sub', 'sid'], maxTokenAge: '15m',
      });
      const verified = claims.parse(payload);
      const session = await this.repository.activeSession(verified.sid, verified.sub, now);
      if (!session) throw new AppError(401, 'INVALID_SESSION', 'Sign in again to continue.');
      return session;
    } catch (error) {
      if (error instanceof AppError) throw error;
      // JWT/claim failures are unauthorised; DB errors must not masquerade as a
      // successful offline session. The route safely maps unknown errors to 500.
      if (error instanceof z.ZodError || error instanceof joseErrors.JOSEError) {
        throw new AppError(401, 'INVALID_SESSION', 'Sign in again to continue.');
      }
      throw error;
    }
  }

  async me(authorization: string | undefined) {
    const session = await this.authenticate(authorization);
    const account = await this.repository.account(session.userId);
    if (!account) throw new AppError(401, 'INVALID_SESSION', 'Sign in again to continue.');
    return account;
  }

  async logout(authorization: string | undefined) {
    const session = await this.authenticate(authorization);
    await this.repository.revokeFamily(session.userId, session.familyId, this.clock());
  }

  async deleteAccount(authorization: string | undefined, confirmation: string) {
    const session = await this.authenticate(authorization);
    if (confirmation !== 'DELETE_MY_ACCOUNT') {
      throw new AppError(400, 'VALIDATION_ERROR', 'Explicit confirmation DELETE_MY_ACCOUNT is required.');
    }
    await this.repository.deleteAccount(session.userId);
  }

  private async tokens(session: Session, refreshToken: string, now: Date) {
    const expiresAt = Math.min(Math.floor(now.getTime() / 1000) + accessSeconds,
      Math.floor(session.expiresAt.getTime() / 1000));
    const accessToken = await new SignJWT({sid: session.id})
      .setProtectedHeader({alg: 'HS256', typ: 'JWT'})
      .setIssuer(issuer).setAudience(audience).setSubject(session.userId)
      .setIssuedAt(Math.floor(now.getTime() / 1000)).setExpirationTime(expiresAt).sign(this.key);
    return {accessToken, refreshToken, tokenType: 'Bearer',
      expiresIn: expiresAt - Math.floor(now.getTime() / 1000),
      refreshExpiresAt: session.expiresAt.toISOString()};
  }
}
