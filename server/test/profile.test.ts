import assert from 'node:assert/strict';
import { randomBytes, randomUUID } from 'node:crypto';
import { test } from 'node:test';
import { buildApp } from '../src/app.js';
import { readEnvironment } from '../src/config/env.js';
import { AuthService } from '../src/modules/auth/service.js';
import type { Account, AuthRepository, Session, VerifiedIdentity, Rotation } from '../src/modules/auth/types.js';
import { academicNotice, ProfileService, type AcademicProfile, type ConsentEvent,
  type ProfileRepository, type ProfileTransaction, type ProfileReceipt } from '../src/modules/profile/service.js';

// Explicit storage/identity fixtures. Production uses Prisma and Google;
// these tests prove route/service policy, NOT PostgreSQL locking or live OAuth.
class IdentityFixture implements AuthRepository {
  accounts = new Map<string, Account>();
  sessions = new Map<string, Session>();
  async login(identity: VerifiedIdentity, _hash: Buffer, _now: Date, expiresAt: Date) {
    let account = this.accounts.get(identity.googleSubject);
    if (!account) {
      account = {id: randomUUID(), email: identity.email, displayName: identity.displayName};
      this.accounts.set(identity.googleSubject, account);
    }
    const session = {id: randomUUID(), familyId: randomUUID(), userId: account.id, expiresAt};
    this.sessions.set(session.id, session);
    return {account, session};
  }
  async rotate(): Promise<Rotation> { return {kind: 'invalid'}; }
  async activeSession(id: string, userId: string, now: Date) {
    const session = this.sessions.get(id);
    return session?.userId === userId && session.expiresAt > now ? session : null;
  }
  async account(id: string) { return [...this.accounts.values()].find(row => row.id === id) ?? null; }
  async revokeFamily(userId: string, familyId: string) {
    for (const [id, row] of this.sessions) {
      if (row.userId === userId && row.familyId === familyId) this.sessions.delete(id);
    }
  }
  async deleteAccount(userId: string) {
    for (const [id, row] of this.sessions) {
      if (row.userId === userId) this.sessions.delete(id);
    }
    for (const [sub, row] of this.accounts) {
      if (row.id === userId) this.accounts.delete(sub);
    }
  }
}

class AcademicFixture implements ProfileRepository {
  events = new Map<string, ConsentEvent>();
  profiles = new Map<string, AcademicProfile>();
  sequence = 0;
  receipts = new Map<string, ProfileReceipt>();
  calls = 0;
  async withSession<T>(session: Session, action: (tx: ProfileTransaction) => Promise<T>) {
    this.calls++;
    const id = session.userId;
    return action({
      receipt: async operationId => this.receipts.get(`${id}:${operationId}`) ?? null,
      recordReceipt: async (operationId, payloadHash, result) => {
        this.receipts.set(`${id}:${operationId}`, {payloadHash, result});
      },
      consent: async () => this.events.get(id) ?? null,
      recordConsent: async input => {
        const event = {sequence: String(++this.sequence), granted: input.granted,
          noticeVersion: input.noticeVersion, eventAt: new Date().toISOString()};
        this.events.set(id, event);
        return event;
      },
      profile: async () => this.profiles.get(id) ?? null,
      saveProfile: async ({expectedRevision, ...input}) => {
        const profile = {...input, revision: expectedRevision + 1, updatedAt: new Date().toISOString()};
        this.profiles.set(id, profile);
        return profile;
      },
    });
  }
}

const profile = {programme: 'B.Tech Computer Science', semesterNumber: 3,
  semesterStart: '2026-07-20', semesterEnd: '2026-12-10', timezone: 'Asia/Kolkata', expectedRevision: 0};
const grant = {purpose: 'ACADEMIC_PROCESSING', noticeVersion: academicNotice.version,
  granted: true, expectedSequence: null};

async function fixture(production = false) {
  const identity = new IdentityFixture();
  const repository = new AcademicFixture();
  const signingKey = randomBytes(32).toString('base64url');
  const auth = new AuthService(identity, {verify: async token => ({googleSubject: token,
    email: `${token}@cb.students.amrita.edu`, displayName: token})}, signingKey);
  const config = readEnvironment(production ? {NODE_ENV: 'production', LOG_LEVEL: 'silent',
    DATABASE_URL: 'postgresql://fixture:fixture@localhost/fixture',
    AUTH_SIGNING_KEY: signingKey, GOOGLE_CLIENT_IDS: 'fixture.apps.googleusercontent.com'}
    : {NODE_ENV: 'test', LOG_LEVEL: 'silent'});
  const app = await buildApp({config, auth, profiles: new ProfileService(repository)});
  const loginA = await auth.login('alice');
  const loginB = await auth.login('bob');
  const headersA = {authorization: `Bearer ${loginA.accessToken}`};
  const headersB = {authorization: `Bearer ${loginB.accessToken}`};
  return {app, repository, auth, headersA, headersB};
}

test('academic profile requires its own current server consent; withdrawal blocks reads and writes', async t => {
  const {app, headersA, repository} = await fixture();
  t.after(() => app.close());
  const before = await app.inject({url: '/api/v1/privacy/consent', headers: headersA});
  assert.deepEqual(before.json().data, {purpose: 'ACADEMIC_PROCESSING', granted: false, event: null});
  assert.equal((await app.inject({url: '/api/v1/users/me/profile', headers: headersA})).statusCode, 403);
  assert.equal((await app.inject({method: 'PUT', url: '/api/v1/users/me/profile', headers: headersA, payload: profile})).statusCode, 403);
  assert.equal(repository.profiles.size, 0);
  const accepted = await app.inject({method: 'POST', url: '/api/v1/privacy/consent', headers: headersA, payload: grant});
  assert.equal(accepted.statusCode, 200);
  assert.equal((await app.inject({url: '/api/v1/users/me/profile', headers: headersA})).json().data, null);
  const saved = await app.inject({method: 'PUT', url: '/api/v1/users/me/profile', headers: headersA, payload: profile});
  assert.equal(saved.statusCode, 200);
  assert.equal(saved.json().data.revision, 1);
  assert(!saved.body.includes('userId'));
  const withdrawn = await app.inject({method: 'POST', url: '/api/v1/privacy/consent', headers: headersA,
    payload: {...grant, granted: false, expectedSequence: accepted.json().data.event.sequence}});
  assert.equal(withdrawn.statusCode, 200);
  assert.equal(withdrawn.json().data.granted, false);
  assert.equal((await app.inject({url: '/api/v1/users/me/profile', headers: headersA})).statusCode, 403);
  assert.equal((await app.inject({method: 'PUT', url: '/api/v1/users/me/profile', headers: headersA,
    payload: {...profile, expectedRevision: 1}})).statusCode, 403);
  assert.equal(repository.profiles.size, 1, 'Withdrawal is not falsely reported as hard deletion.');
  assert.equal((await app.inject({method: 'POST', url: '/api/v1/privacy/consent', headers: headersA, payload: grant})).statusCode, 409,
    'An old grant cannot resurrect consent after withdrawal.');
});

test('two authenticated users cannot read or overwrite each other; client ownership fields fail', async t => {
  const {app, headersA, headersB, repository} = await fixture();
  t.after(() => app.close());
  for (const headers of [headersA, headersB]) {
    assert.equal((await app.inject({method: 'POST', url: '/api/v1/privacy/consent', headers, payload: grant})).statusCode, 200);
  }
  assert.equal((await app.inject({method: 'PUT', url: '/api/v1/users/me/profile', headers: headersA, payload: profile})).statusCode, 200);
  assert.equal((await app.inject({url: '/api/v1/users/me/profile', headers: headersB})).json().data, null);
  const bob = await app.inject({method: 'PUT', url: '/api/v1/users/me/profile', headers: headersB,
    payload: {...profile, programme: 'B.Sc Mathematics'}});
  assert.equal(bob.statusCode, 200);
  assert.equal((await app.inject({url: '/api/v1/users/me/profile', headers: headersA})).json().data.programme, profile.programme);
  const ids = [...repository.profiles.keys()];
  assert.equal((await app.inject({method: 'PUT', url: '/api/v1/users/me/profile', headers: headersB,
    payload: {...profile, userId: ids[0]}})).statusCode, 400);
  assert.equal((await app.inject({method: 'POST', url: '/api/v1/privacy/consent', headers: headersB,
    payload: {...grant, userId: ids[0]}})).statusCode, 400);
  assert.equal((await app.inject(`/api/v1/users/${ids[0]}/profile`)).statusCode, 404);
});

test('profile validation rejects impossible dates, unknown fields, invalid semesters and stale revisions', async t => {
  const {app, headersA} = await fixture();
  t.after(() => app.close());
  await app.inject({method: 'POST', url: '/api/v1/privacy/consent', headers: headersA, payload: grant});
  for (const change of [{programme: '  '}, {programme: 'Secret\u0000'}, {semesterNumber: 0}, {semesterNumber: 31},
    {semesterNumber: 1.5}, {semesterStart: '2026-02-30'}, {semesterEnd: '2026-01-01'},
    {semesterStart: '1999-01-01'}, {timezone: 'UTC'}, {revision: 999}, {expectedRevision: -1}]) {
    const response = await app.inject({method: 'PUT', url: '/api/v1/users/me/profile', headers: headersA,
      payload: {...profile, ...change}});
    assert.equal(response.statusCode, 400, JSON.stringify(change));
    assert(!response.body.includes('Secret'));
  }
  const saved = await app.inject({method: 'PUT', url: '/api/v1/users/me/profile', headers: headersA,
    payload: {...profile, programme: '  My Programme  '}});
  assert.equal(saved.json().data.programme, 'My Programme');
  const stale = await app.inject({method: 'PUT', url: '/api/v1/users/me/profile', headers: headersA, payload: profile});
  assert.equal(stale.statusCode, 409);
  const next = await app.inject({method: 'PUT', url: '/api/v1/users/me/profile', headers: headersA,
    payload: {...profile, expectedRevision: 1, semesterNumber: 4}});
  assert.equal(next.json().data.revision, 2);
});

test('consent rejects stale notices, forged purposes/sequences and never grants Gemini access', async t => {
  const {app, headersA} = await fixture();
  t.after(() => app.close());
  for (const change of [{purpose: 'GEMINI_PROCESSING'}, {granted: 'true'}, {expectedSequence: '0'},
    {expectedSequence: '9223372036854775808'}, {expectedSequence: 'not-a-number'},
    {expectedSequence: ''}, {expectedSequence: 1}]) {
    assert.equal((await app.inject({method: 'POST', url: '/api/v1/privacy/consent', headers: headersA,
      payload: {...grant, ...change}})).statusCode, 400);
  }
  assert.equal((await app.inject({method: 'POST', url: '/api/v1/privacy/consent', headers: headersA,
    payload: {...grant, noticeVersion: 'old-version'}})).statusCode, 409);
  assert.equal((await app.inject({url: '/api/v1/privacy/consent', headers: headersA})).json().data.granted, false);
  assert.equal((await app.inject('/api/v1/privacy/notice')).json().data.version, academicNotice.version);
});

test('missing/revoked credentials never reach academic storage; public onboarding fails closed', async t => {
  const {app, headersA, auth, repository} = await fixture();
  t.after(() => app.close());
  for (const url of ['/api/v1/privacy/consent', '/api/v1/users/me/profile']) {
    assert.equal((await app.inject(url)).statusCode, 401);
  }
  assert.equal(repository.calls, 0);
  await auth.logout(headersA.authorization);
  assert.equal((await app.inject({url: '/api/v1/users/me/profile', headers: headersA})).statusCode, 401);
  assert.equal(repository.calls, 0);
  const production = await fixture(true);
  t.after(() => production.app.close());
  const response = await production.app.inject({method: 'POST', url: '/api/v1/privacy/consent',
    headers: production.headersA, payload: grant});
  assert.equal(response.statusCode, 503);
  assert.equal(response.json().error.code, 'PRIVACY_NOT_READY');
  assert.equal(production.repository.calls, 0);
});

test('profile sync retry returns its original receipt without another write; changed content conflicts', async t => {
  const {app, headersA, repository} = await fixture();
  t.after(() => app.close());
  const accepted = await app.inject({method: 'POST', url: '/api/v1/privacy/consent', headers: headersA, payload: grant});
  const operation = {operationId: randomUUID(), consentSequence: accepted.json().data.event.sequence, profile};
  const send = (payload: unknown) => app.inject({method: 'POST', url: '/api/v1/sync/profile', headers: headersA,
    payload: payload as Record<string, unknown>});
  const first = await send(operation);
  assert.equal(first.statusCode, 200);
  const retry = await send(operation);
  assert.equal(retry.statusCode, 200);
  assert.deepEqual(retry.json().data, first.json().data);
  assert.equal(repository.receipts.size, 1);
  assert.equal([...repository.profiles.values()][0]!.revision, 1);
  const changed = await send({...operation, profile: {...profile, programme: 'Changed under same operation'}});
  assert.equal(changed.statusCode, 409);
  assert.equal(changed.json().error.code, 'IDEMPOTENCY_CONFLICT');
  const edit = await send({...operation, operationId: randomUUID(), profile: {...profile, expectedRevision: 1, semesterNumber: 4}});
  assert.equal(edit.json().data.profile.revision, 2);
  const oldReplay = await send(operation);
  assert.equal(oldReplay.json().data.profile.revision, 1, 'A receipt is a historic acknowledgement, not the latest profile.');
  assert.equal([...repository.profiles.values()][0]!.revision, 2);
});

test('sync receipts and consent generations are owner-scoped; withdrawal invalidates old queued uploads', async t => {
  const {app, headersA, headersB} = await fixture();
  t.after(() => app.close());
  const accept = (headers: typeof headersA) => app.inject({method: 'POST', url: '/api/v1/privacy/consent', headers, payload: grant});
  const a = (await accept(headersA)).json().data;
  const b = (await accept(headersB)).json().data;
  const operationId = randomUUID();
  const operation = {operationId, consentSequence: a.event.sequence, profile};
  const send = (headers: typeof headersA, payload: Record<string, unknown>) => app.inject({
    method: 'POST', url: '/api/v1/sync/profile', headers, payload});
  assert.equal((await send(headersA, operation)).statusCode, 200);
  assert.equal((await send(headersB, operation)).statusCode, 403);
  const bob = await send(headersB, {...operation, consentSequence: b.event.sequence,
    profile: {...profile, programme: 'Bobs programme'}});
  assert.equal(bob.statusCode, 200);
  assert.equal(bob.json().data.profile.programme, 'Bobs programme');
  assert.equal((await send(headersA, {...operation, userId: randomUUID()})).statusCode, 400);
  const withdrawal = await app.inject({method: 'POST', url: '/api/v1/privacy/consent', headers: headersA,
    payload: {...grant, granted: false, expectedSequence: a.event.sequence}});
  assert.equal((await send(headersA, operation)).statusCode, 403);
  const renewed = await app.inject({method: 'POST', url: '/api/v1/privacy/consent', headers: headersA,
    payload: {...grant, expectedSequence: withdrawal.json().data.event.sequence}});
  assert.equal(renewed.statusCode, 200);
  assert.equal((await send(headersA, operation)).statusCode, 403,
    'Regrant must not silently authorise uploads queued under an earlier consent.');
});
