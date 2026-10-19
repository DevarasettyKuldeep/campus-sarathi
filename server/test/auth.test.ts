import assert from 'node:assert/strict';
import { generateKeyPairSync, randomBytes, randomUUID } from 'node:crypto';
import { test } from 'node:test';
import { createServer } from 'node:http';
import { once } from 'node:events';
import { SignJWT } from 'jose';
import { OAuth2Client } from 'google-auth-library';
import { buildApp } from '../src/app.js';
import { readEnvironment } from '../src/config/env.js';
import { AppError } from '../src/errors.js';
import { GoogleIdentityVerifier } from '../src/modules/auth/google_identity.js';
import { AuthService } from '../src/modules/auth/service.js';
import type { Account, AuthRepository, Session, VerifiedIdentity, Rotation } from '../src/modules/auth/types.js';

const clientId = '123456-fixture.apps.googleusercontent.com';
const identity: VerifiedIdentity = {googleSubject: 'google-fixture-sub',
  email: 'student@cb.students.amrita.edu', displayName: 'Student'};

// Explicit unit-test double. Production always uses PrismaAuthRepository.
class TestRepository implements AuthRepository {
  readonly user: Account = {id: randomUUID(), email: identity.email, displayName: identity.displayName};
  readonly sessions = new Map<string, Session & {hash: string; revoked: boolean}>();
  loginCalls = 0;
  async login(_identity: VerifiedIdentity, hash: Buffer, _now: Date, expiresAt: Date) {
    this.loginCalls++;
    const session = {id: randomUUID(), userId: this.user.id, familyId: randomUUID(), expiresAt,
      hash: hash.toString('hex'), revoked: false};
    this.sessions.set(session.id, session);
    return {account: this.user, session};
  }
  async rotate(hash: Buffer, next: Buffer, now: Date): Promise<Rotation> {
    const current = [...this.sessions.values()].find((row) => row.hash === hash.toString('hex'));
    if (!current || current.expiresAt <= now) return {kind: 'invalid'};
    if (current.revoked) {
      await this.revokeFamily(current.userId, current.familyId, now);
      return {kind: 'replayed'};
    }
    current.revoked = true;
    const session = {...current, id: randomUUID(), hash: next.toString('hex'), revoked: false};
    this.sessions.set(session.id, session);
    return {kind: 'ok', session};
  }
  async activeSession(id: string, userId: string, now: Date) {
    const row = this.sessions.get(id);
    return row && row.userId === userId && !row.revoked && row.expiresAt > now ? row : null;
  }
  async account(userId: string) { return userId === this.user.id ? this.user : null; }
  async revokeFamily(userId: string, familyId: string, _now: Date) {
    for (const row of this.sessions.values()) {
      if (row.userId === userId && row.familyId === familyId) row.revoked = true;
    }
  }
  deleted = false;
  async deleteAccount(userId: string) {
    if (userId === this.user.id) {
      this.deleted = true;
      for (const row of this.sessions.values()) {
        if (row.userId === userId) row.revoked = true;
      }
    }
  }
}

function fixture() {
  const repo = new TestRepository();
  const key = randomBytes(32).toString('base64url');
  let now = new Date();
  const service = new AuthService(repo, {verify: async () => identity}, key, () => now);
  return {repo, service, key, advance: (milliseconds: number) => {now = new Date(now.getTime() + milliseconds);}};
}

test('session tokens are signed and hashed; expiry/revocation/owner binding are checked', async () => {
  const {repo, service, key, advance} = fixture();
  const login = await service.login('unit-fixture');
  assert.equal(login.expiresIn, 900);
  assert.match(login.refreshToken, /^[A-Za-z0-9_-]{43}$/);
  const stored = [...repo.sessions.values()][0]!;
  assert.equal(stored.hash.length, 64);
  assert.notEqual(stored.hash, login.refreshToken);
  assert.equal((await service.me(`Bearer ${login.accessToken}`)).id, repo.user.id);
  await assert.rejects(service.me(`Bearer ${login.accessToken}x`), (e: unknown) => e instanceof AppError && e.statusCode === 401);
  const wrongOwner = await new SignJWT({sid: stored.id}).setProtectedHeader({alg: 'HS256'})
    .setIssuer('campus-sarathi-api').setAudience('campus-sarathi-mobile')
    .setSubject(randomUUID()).setIssuedAt().setExpirationTime('15m').sign(Buffer.from(key, 'base64url'));
  await assert.rejects(service.me(`Bearer ${wrongOwner}`));
  const wrongAlgorithm = await new SignJWT({sid: stored.id}).setProtectedHeader({alg: 'HS384'})
    .setIssuer('campus-sarathi-api').setAudience('campus-sarathi-mobile')
    .setSubject(repo.user.id).setIssuedAt().setExpirationTime('15m').sign(Buffer.from(key, 'base64url'));
  await assert.rejects(service.me(`Bearer ${wrongAlgorithm}`), (e: unknown) => e instanceof AppError && e.statusCode === 401);
  advance(16 * 60 * 1000);
  await assert.rejects(service.me(`Bearer ${login.accessToken}`));
  const renewed = await service.refresh(login.refreshToken);
  assert.equal((await service.me(`Bearer ${renewed.accessToken}`)).id, repo.user.id);
  await service.logout(`Bearer ${renewed.accessToken}`);
  await assert.rejects(service.me(`Bearer ${renewed.accessToken}`));
  await assert.rejects(service.refresh(renewed.refreshToken));
});

test('refresh replay rejects access to the replacement session without extending family expiry', async () => {
  const {service, advance} = fixture();
  const first = await service.login('unit-fixture');
  advance(1000);
  const next = await service.refresh(first.refreshToken);
  assert.notEqual(next.refreshToken, first.refreshToken);
  assert.equal(next.refreshExpiresAt, first.refreshExpiresAt);
  await assert.rejects(service.me(`Bearer ${first.accessToken}`));
  await assert.rejects(service.refresh(first.refreshToken));
  await assert.rejects(service.me(`Bearer ${next.accessToken}`));
});

test('failed identity verification creates no application session', async () => {
  const repo = new TestRepository();
  const service = new AuthService(repo, {verify: async () => {throw new AppError(403, 'STUDENT_ACCOUNT_REQUIRED', 'Use a student account.');}},
    randomBytes(32).toString('base64url'));
  await assert.rejects(service.login('fixture'));
  assert.equal(repo.loginCalls, 0);
});

test('auth routes reject client ownership fields and verify bearer auth for account/logout', async (t) => {
  const {service, repo} = fixture();
  const app = await buildApp({config: readEnvironment({NODE_ENV: 'test', LOG_LEVEL: 'silent'}), auth: service});
  t.after(() => app.close());
  assert.equal((await app.inject({method: 'POST', url: '/api/v1/auth/google', payload: {idToken: 'fixture', userId: 'forged'}})).statusCode, 400);
  assert.equal(repo.loginCalls, 0);
  assert.equal((await app.inject('/api/v1/users/me')).statusCode, 401);
  const response = await app.inject({method: 'POST', url: '/api/v1/auth/google', payload: {idToken: 'fixture'}});
  assert.equal(response.statusCode, 200);
  const tokens = response.json().data;
  const account = await app.inject({url: '/api/v1/users/me', headers: {authorization: `Bearer ${tokens.accessToken}`}});
  assert.equal(account.json().data.id, repo.user.id);
  assert(!account.body.includes('refresh'));
  const logout = await app.inject({method: 'POST', url: '/api/v1/auth/logout', headers: {authorization: `Bearer ${tokens.accessToken}`}});
  assert.equal(logout.statusCode, 200);
  assert.equal((await app.inject({url: '/api/v1/users/me', headers: {authorization: `Bearer ${tokens.accessToken}`}})).statusCode, 401);
});

test('partial auth configuration fails without disclosing a signing key', () => {
  const key = randomBytes(32).toString('base64url');
  assert.throws(() => readEnvironment({AUTH_SIGNING_KEY: key}), (error: unknown) => {
    assert(error instanceof Error);
    assert(!error.message.includes(key));
    return error.message.includes('GOOGLE_CLIENT_IDS') && error.message.includes('DATABASE_URL');
  });
});

test('Google library verifies signed local fixtures; domain and verified-email checks fail closed', async (t) => {
  const {privateKey, publicKey} = generateKeyPairSync('rsa', {modulusLength: 2048});
  const client = new OAuth2Client();
  // Replace only the certificate fetch. Google's actual RSA/issuer/audience/
  // expiry validation runs; these are test certificates, NOT Google live keys.
  t.mock.method(client, 'getFederatedSignonCertsAsync', async () => ({certs: {
    fixture: publicKey.export({type: 'spki', format: 'pem'}).toString(),
  }}));
  const verifier = new GoogleIdentityVerifier([clientId], client);
  const sign = (payload: Record<string, unknown> = {}, options: {aud?: string; iss?: string; exp?: number} = {}) =>
    new SignJWT({email: identity.email, email_verified: true, hd: 'cb.students.amrita.edu', name: 'Student', ...payload})
      .setProtectedHeader({alg: 'RS256', kid: 'fixture'})
      .setSubject(identity.googleSubject).setIssuedAt()
      .setIssuer(options.iss ?? 'https://accounts.google.com').setAudience(options.aud ?? clientId)
      .setExpirationTime(options.exp ?? Math.floor(Date.now() / 1000) + 3600).sign(privateKey);
  assert.deepEqual(await verifier.verify(await sign()), identity);
  for (const payload of [{email: 'student@example.com'}, {email_verified: false},
    {hd: 'example.com'}, {hd: undefined}]) {
    await assert.rejects(verifier.verify(await sign(payload)));
  }
  await assert.rejects(verifier.verify(await sign({}, {aud: 'wrong-client'})));
  await assert.rejects(verifier.verify(await sign({}, {iss: 'https://attacker.example'})));
  await assert.rejects(verifier.verify(await sign({}, {exp: Math.floor(Date.now() / 1000) - 1000})));
  await assert.rejects(verifier.verify(`${await sign()}x`));
});

test('Google key-fetch network failure is unavailable and reveals no provider details', async (t) => {
  const client = new OAuth2Client();
  t.mock.method(client, 'getFederatedSignonCertsAsync', async () => {
    throw Object.assign(new Error('sensitive upstream URL or token'), {code: 'ETIMEDOUT'});
  });
  const verifier = new GoogleIdentityVerifier([clientId], client);
  await assert.rejects(verifier.verify('fixture'), (error: unknown) => {
    assert(error instanceof AppError);
    assert.equal(error.statusCode, 503);
    assert(!error.message.includes('sensitive'));
    return true;
  });
});

test('certificate-fetch upstream failure makes one bounded attempt over real HTTP', async (t) => {
  let requests = 0;
  const upstream = createServer((_request, response) => {
    requests++;
    response.writeHead(503, {'content-type': 'application/json'});
    response.end('{"error":"fixture unavailable"}');
  });
  upstream.listen(0, '127.0.0.1');
  await once(upstream, 'listening');
  t.after(() => new Promise<void>((resolve) => upstream.close(() => resolve())));
  const address = upstream.address();
  assert(address && typeof address !== 'string');
  const url = new URL(`http://127.0.0.1:${address.port}/fixture-certificates`);
  const client = new OAuth2Client({endpoints: {
    oauth2FederatedSignonPemCertsUrl: url, oauth2FederatedSignonJwkCertsUrl: url,
  }});
  const verifier = new GoogleIdentityVerifier([clientId], client);
  await assert.rejects(verifier.verify('fixture-token'), (error: unknown) => error instanceof AppError && error.statusCode === 503);
  assert.equal(requests, 1, 'A certificate outage must not trigger library-level retries.');
});

test('account deletion requires explicit confirmation and bearer authentication', async () => {
  const {service, repo} = fixture();
  const config = readEnvironment({
    DATABASE_URL: 'postgresql://fixture/app',
    GOOGLE_CLIENT_IDS: clientId,
    AUTH_SIGNING_KEY: randomBytes(32).toString('base64url'),
  });
  const app = await buildApp({config, auth: service});
  const login = await service.login('valid-token');
  const bearer = `Bearer ${login.accessToken}`;

  // Missing bearer auth
  const unauthorized = await app.inject({
    method: 'DELETE',
    url: '/api/v1/account',
    payload: {confirmation: 'DELETE_MY_ACCOUNT'},
  });
  assert.equal(unauthorized.statusCode, 401);

  // Missing / invalid confirmation
  const badConfirmation = await app.inject({
    method: 'DELETE',
    url: '/api/v1/account',
    headers: {authorization: bearer},
    payload: {confirmation: 'YES'},
  });
  assert.equal(badConfirmation.statusCode, 400);

  // Successful deletion
  const deleted = await app.inject({
    method: 'DELETE',
    url: '/api/v1/account',
    headers: {authorization: bearer},
    payload: {confirmation: 'DELETE_MY_ACCOUNT'},
  });
  assert.equal(deleted.statusCode, 200);
  assert.equal(deleted.json().data.deleted, true);
  assert.equal(repo.deleted, true);

  // Token is now revoked / account is gone
  const after = await app.inject({
    method: 'GET',
    url: '/api/v1/users/me',
    headers: {authorization: bearer},
  });
  assert.equal(after.statusCode, 401);
});
