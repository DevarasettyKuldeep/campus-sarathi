import assert from 'node:assert/strict';
import { randomUUID, randomBytes } from 'node:crypto';
import { test } from 'node:test';
import { createDatabase, probeDatabase } from '../src/database.js';
import { PrismaAuthRepository } from '../src/modules/auth/prisma_repository.js';
import { PrismaProfileRepository } from '../src/modules/profile/prisma_repository.js';
import { ProfileService, academicNotice, profileInput } from '../src/modules/profile/service.js';
import { AppError } from '../src/errors.js';

const connectionString = process.env.TEST_DATABASE_URL;

test('PostgreSQL profile consent, ownership, concurrent revisions and lifecycle rollback',
  {skip: !connectionString}, async t => {
    assert(connectionString);
    const database = createDatabase(connectionString);
    const auth = new PrismaAuthRepository(database);
    const repository = new PrismaProfileRepository(database);
    const service = new ProfileService(repository);
    const users: string[] = [];
    t.after(async () => {
      try { await database.user.deleteMany({where: {id: {in: users}}}); }
      finally { await database.$disconnect(); }
    });
    const now = new Date();
    const login = async () => {
      const id = randomUUID();
      const result = await auth.login({googleSubject: `profile-${id}`,
        email: `${id}@cb.students.amrita.edu`, displayName: 'Profile integration'},
        randomBytes(32), now, new Date(now.getTime() + 120_000));
      users.push(result.account.id);
      return result.session;
    };
    const first = await login();
    const second = await login();
    await assert.rejects(service.get(first), (e: unknown) => e instanceof AppError && e.statusCode === 403);
    const accepted = await service.setConsent(first, {purpose: 'ACADEMIC_PROCESSING',
      noticeVersion: academicNotice.version, granted: true, expectedSequence: null});
    const input = profileInput.parse({programme: 'Integration programme', semesterNumber: 3,
      semesterStart: '2026-07-20', semesterEnd: '2026-12-10', timezone: 'Asia/Kolkata', expectedRevision: 0});
    assert.equal((await service.save(first, input)).revision, 1);
    await service.setConsent(second, {purpose: 'ACADEMIC_PROCESSING',
      noticeVersion: academicNotice.version, granted: true, expectedSequence: null});
    assert.equal(await service.get(second), null);
    const edits = await Promise.allSettled([
      service.save(first, {...input, expectedRevision: 1, programme: 'First competing draft'}),
      service.save(first, {...input, expectedRevision: 1, programme: 'Second competing draft'}),
    ]);
    assert.equal(edits.filter(result => result.status === 'fulfilled').length, 1);
    const rejected = edits.find(result => result.status === 'rejected');
    assert(rejected?.status === 'rejected' && rejected.reason instanceof AppError);
    assert.equal(rejected.reason.code, 'REVISION_CONFLICT');
    assert.equal((await service.get(first))?.revision, 2);
    // Verify the real transaction rolls back both audit and academic writes.
    await assert.rejects(repository.withSession(first, async tx => {
      await tx.recordConsent({purpose: 'ACADEMIC_PROCESSING', noticeVersion: academicNotice.version,
        granted: false, expectedSequence: accepted.event!.sequence});
      throw new Error('Intentional integration rollback');
    }));
    assert.equal((await service.consent(first)).granted, true);
    const withdrawal = await service.setConsent(first, {purpose: 'ACADEMIC_PROCESSING',
      noticeVersion: academicNotice.version, granted: false, expectedSequence: accepted.event!.sequence});
    assert.equal(withdrawal.granted, false);
    await assert.rejects(service.get(first), (e: unknown) => e instanceof AppError && e.statusCode === 403);
    await assert.rejects(service.save(first, {...input, expectedRevision: 2}));
    await assert.rejects(service.setConsent(first, {purpose: 'ACADEMIC_PROCESSING',
      noticeVersion: academicNotice.version, granted: true, expectedSequence: null}));
    assert.equal(await service.get(second), null);
    await assert.rejects(database.academicProfile.update({where: {userId: first.userId},
      data: {semesterNumber: 31}}), 'Apply the profile-limits migration first.');
    await auth.revokeFamily(second.userId, second.familyId, new Date());
    await assert.rejects(service.consent(second), (e: unknown) => e instanceof AppError && e.statusCode === 401);
  });

// These checks use a real migrated PostgreSQL database. Absence is reported as
// SKIPPED, never replaced by a mock database or counted as verified integration.
test('PostgreSQL identity constraints, transaction rollback and hard-delete cascade',
  {skip: !connectionString}, async (t) => {
    assert(connectionString);
    const database = createDatabase(connectionString);
    const userId = randomUUID();
    const invalidId = randomUUID();
    t.after(async () => {
      try { await database.user.deleteMany({where: {id: {in: [userId, invalidId]}}}); }
      finally { await database.$disconnect(); }
    });
    assert.equal(await probeDatabase(database), true, 'Apply migrations to the test database first.');
    await database.user.create({data: {
      id: userId, googleSubject: `integration-${userId}`,
      email: `${userId}@cb.students.amrita.edu`, displayName: 'Integration test',
      emailVerifiedAt: new Date(),
      profile: {create: {programme: 'Test programme', semesterNumber: 1,
        semesterStart: new Date('2026-07-01'), semesterEnd: new Date('2026-12-31')}},
      sessions: {create: {familyId: randomUUID(), refreshHash: randomBytes(32),
        expiresAt: new Date(Date.now() + 60_000)}},
      consentRecords: {create: {purpose: 'ACADEMIC_PROCESSING', noticeVersion: 'test-1', granted: true}},
    }});
    await assert.rejects(database.user.create({data: {
      id: invalidId, googleSubject: `invalid-${invalidId}`, email: `${invalidId}@example.com`,
      displayName: 'Invalid domain', emailVerifiedAt: new Date(),
    }}));
    await assert.rejects(database.$transaction(async (transaction) => {
      await transaction.user.update({where: {id: userId}, data: {displayName: 'Must roll back'}});
      await transaction.academicProfile.update({where: {userId}, data: {semesterNumber: 0}});
    }));
    assert.equal((await database.user.findUniqueOrThrow({where: {id: userId}})).displayName, 'Integration test');
    await database.user.delete({where: {id: userId}});
    assert.equal(await database.academicProfile.count({where: {userId}}), 0);
    assert.equal(await database.session.count({where: {userId}}), 0);
    assert.equal(await database.consentRecord.count({where: {userId}}), 0);
  });

test('PostgreSQL refresh rotation serializes concurrent replays and logout',
  {skip: !connectionString}, async (t) => {
    assert(connectionString);
    const database = createDatabase(connectionString);
    const repository = new PrismaAuthRepository(database);
    const identityId = randomUUID();
    let userId: string | undefined;
    t.after(async () => {
      try { if (userId) await database.user.deleteMany({where: {id: userId}}); }
      finally { await database.$disconnect(); }
    });
    const now = new Date();
    const initialHash = randomBytes(32);
    const login = await repository.login({googleSubject: `rotation-${identityId}`,
      email: `${identityId}@cb.students.amrita.edu`, displayName: 'Rotation test'},
      initialHash, now, new Date(now.getTime() + 60_000));
    userId = login.account.id;
    const firstNextHash = randomBytes(32);
    const secondNextHash = randomBytes(32);
    const outcomes = await Promise.all([
      repository.rotate(initialHash, firstNextHash, now),
      repository.rotate(initialHash, secondNextHash, now),
    ]);
    assert.equal(outcomes.filter((outcome) => outcome.kind === 'ok').length, 1);
    assert.equal(outcomes.filter((outcome) => outcome.kind === 'replayed').length, 1);
    assert.equal(await database.session.count({where: {userId, revokedAt: null}}), 0,
      'Replay revocation must commit and cover the concurrently issued session.');

    const secondHash = randomBytes(32);
    const secondLogin = await repository.login({googleSubject: `rotation-${identityId}`,
      email: `${identityId}@cb.students.amrita.edu`, displayName: 'Rotation test'},
      secondHash, now, new Date(now.getTime() + 60_000));
    assert.equal(await repository.activeSession(secondLogin.session.id, randomUUID(), now), null);
    await Promise.all([
      repository.rotate(secondHash, randomBytes(32), now),
      repository.revokeFamily(userId, secondLogin.session.familyId, now),
    ]);
    assert.equal(await database.session.count({where: {userId, revokedAt: null}}), 0,
      'Concurrent refresh must not escape logout revocation.');
  });
