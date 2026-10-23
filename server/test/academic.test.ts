import assert from 'node:assert/strict';
import { randomBytes, randomUUID } from 'node:crypto';
import { test } from 'node:test';
import { buildApp } from '../src/app.js';
import { readEnvironment } from '../src/config/env.js';
import { AuthService } from '../src/modules/auth/service.js';
import type { Account, AuthRepository, Session, VerifiedIdentity, Rotation } from '../src/modules/auth/types.js';
import { AcademicService } from '../src/modules/academic/service.js';
import type {
  AcademicRepository,
  AcademicTransaction,
  SubjectRecord,
  SubjectInput,
  CourseRecord,
  CourseInput,
  ClassScheduleRecord,
  ClassScheduleInput,
  PatchClassScheduleInput,
  AttendanceRecordDTO,
  AttendanceInput,
  PatchAttendanceInput,
  AssignmentRecordDTO,
  AssignmentInput,
  PatchAssignmentInput,
  AnnouncementRecordDTO,
  AcademicSyncReceipt,
} from '../src/modules/academic/types.js';

class IdentityFixture implements AuthRepository {
  accounts = new Map<string, Account>();
  sessions = new Map<string, Session>();

  async login(identity: VerifiedIdentity, _hash: Buffer, _now: Date, expiresAt: Date) {
    let account = this.accounts.get(identity.googleSubject);
    if (!account) {
      account = { id: randomUUID(), email: identity.email, displayName: identity.displayName };
      this.accounts.set(identity.googleSubject, account);
    }
    const session = { id: randomUUID(), familyId: randomUUID(), userId: account.id, expiresAt };
    this.sessions.set(session.id, session);
    return { account, session };
  }

  async rotate(): Promise<Rotation> { return { kind: 'invalid' }; }

  async activeSession(id: string, userId: string, now: Date) {
    const session = this.sessions.get(id);
    return session?.userId === userId && session.expiresAt > now ? session : null;
  }

  async account(id: string) { return [...this.accounts.values()].find(row => row.id === id) ?? null; }
  async revokeFamily() {}
  async deleteAccount() {}
}

class AcademicFixture implements AcademicRepository {
  consents = new Map<string, { granted: boolean; sequence: string }>();
  subjects = new Map<string, SubjectRecord[]>();
  courses = new Map<string, CourseRecord[]>();
  classes = new Map<string, ClassScheduleRecord[]>();
  attendance = new Map<string, AttendanceRecordDTO[]>();
  assignments = new Map<string, AssignmentRecordDTO[]>();
  announcements: AnnouncementRecordDTO[] = [
    {
      id: randomUUID(),
      scope: 'public',
      title: 'Mid-term schedule published',
      body: 'Mid-term exams begin on 10 November 2026.',
      originUrl: 'https://amrita.edu/announcements/midterm',
      publishedAt: '2026-10-18T10:00:00.000Z',
      fetchedAt: '2026-10-18T10:00:00.000Z',
    },
  ];
  receipts = new Map<string, AcademicSyncReceipt>();

  grantConsent(userId: string, sequence: string = '1') {
    this.consents.set(userId, { granted: true, sequence });
  }

  revokeConsent(userId: string) {
    this.consents.set(userId, { granted: false, sequence: '2' });
  }

  async withSession<T>(session: Session, action: (tx: AcademicTransaction) => Promise<T>): Promise<T> {
    const uid = session.userId;
    const self = this;

    const tx: AcademicTransaction = {
      async checkConsent() {
        return self.consents.get(uid) ?? null;
      },

      // Subjects
      async listSubjects() {
        return self.subjects.get(uid) ?? [];
      },
      async createSubject(input: SubjectInput & { id?: string }) {
        const list = self.subjects.get(uid) ?? [];
        const existing = list.find(s => s.code === input.code);
        if (existing) {
          existing.name = input.name;
          existing.revision += 1;
          existing.updatedAt = new Date().toISOString();
          return existing;
        }
        const record: SubjectRecord = {
          id: input.id ?? randomUUID(),
          userId: uid,
          code: input.code,
          name: input.name,
          revision: 1,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        };
        list.push(record);
        self.subjects.set(uid, list);
        return record;
      },
      async deleteSubject(id: string) {
        const list = self.subjects.get(uid) ?? [];
        const index = list.findIndex(s => s.id === id);
        if (index === -1) return false;
        list.splice(index, 1);
        return true;
      },

      // Courses
      async listCourses() {
        return self.courses.get(uid) ?? [];
      },
      async createCourse(input: CourseInput & { id?: string }) {
        const list = self.courses.get(uid) ?? [];
        const record: CourseRecord = {
          id: input.id ?? randomUUID(),
          userId: uid,
          subjectId: input.subjectId,
          semesterLabel: input.semesterLabel,
          credits: input.credits ?? null,
          attendanceThreshold: input.attendanceThreshold ?? null,
          revision: 1,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        };
        list.push(record);
        self.courses.set(uid, list);
        return record;
      },
      async deleteCourse(id: string) {
        const list = self.courses.get(uid) ?? [];
        const index = list.findIndex(c => c.id === id);
        if (index === -1) return false;
        list.splice(index, 1);
        return true;
      },

      // Classes
      async listClasses() {
        return self.classes.get(uid) ?? [];
      },
      async createClass(input: ClassScheduleInput & { id?: string }) {
        const list = self.classes.get(uid) ?? [];
        const record: ClassScheduleRecord = {
          id: input.id ?? randomUUID(),
          userId: uid,
          courseId: input.courseId ?? null,
          subjectName: input.subjectName,
          weekday: input.weekday,
          startMinute: input.startMinute,
          endMinute: input.endMinute,
          room: input.room,
          source: 'student',
          revision: 1,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        };
        list.push(record);
        self.classes.set(uid, list);
        return record;
      },
      async updateClass(id: string, input: PatchClassScheduleInput) {
        const list = self.classes.get(uid) ?? [];
        const item = list.find(c => c.id === id);
        if (!item) throw new Error('Class not found');
        if (item.revision !== input.expectedRevision) {
          throw new (await import('../../server/src/errors.js')).AppError(409, 'REVISION_CONFLICT', 'Revision conflict');
        }
        if (input.weekday !== undefined) item.weekday = input.weekday;
        if (input.startMinute !== undefined) item.startMinute = input.startMinute;
        if (input.endMinute !== undefined) item.endMinute = input.endMinute;
        if (input.room !== undefined) item.room = input.room;
        item.revision += 1;
        item.updatedAt = new Date().toISOString();
        return item;
      },
      async deleteClass(id: string, expectedRevision: number) {
        const list = self.classes.get(uid) ?? [];
        const index = list.findIndex(c => c.id === id);
        if (index === -1) return false;
        const item = list[index];
        if (!item || item.revision !== expectedRevision) {
          throw new (await import('../../server/src/errors.js')).AppError(409, 'REVISION_CONFLICT', 'Revision conflict');
        }
        list.splice(index, 1);
        return true;
      },

      // Attendance
      async listAttendance() {
        return self.attendance.get(uid) ?? [];
      },
      async saveAttendance(input: AttendanceInput & { id?: string }) {
        const list = self.attendance.get(uid) ?? [];
        const existing = list.find(a => a.subjectKey === input.subjectKey.toLowerCase());
        if (existing) {
          existing.attended = input.attended;
          existing.conducted = input.conducted;
          existing.minimumPercentage = input.minimumPercentage ?? null;
          existing.revision += 1;
          existing.updatedAt = new Date().toISOString();
          return existing;
        }
        const record: AttendanceRecordDTO = {
          id: input.id ?? randomUUID(),
          userId: uid,
          courseId: input.courseId ?? null,
          subjectKey: input.subjectKey.toLowerCase(),
          subjectName: input.subjectName,
          attended: input.attended,
          conducted: input.conducted,
          minimumPercentage: input.minimumPercentage ?? null,
          source: 'student',
          revision: 1,
          observedAt: new Date().toISOString(),
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        };
        list.push(record);
        self.attendance.set(uid, list);
        return record;
      },
      async updateAttendance(id: string, input: PatchAttendanceInput) {
        const list = self.attendance.get(uid) ?? [];
        const item = list.find(a => a.id === id);
        if (!item) throw new Error('Attendance not found');
        if (item.revision !== input.expectedRevision) {
          throw new (await import('../../server/src/errors.js')).AppError(409, 'REVISION_CONFLICT', 'Revision conflict');
        }
        item.attended = input.attended;
        item.conducted = input.conducted;
        item.minimumPercentage = input.minimumPercentage ?? null;
        item.revision += 1;
        item.updatedAt = new Date().toISOString();
        return item;
      },

      // Assignments
      async listAssignments() {
        return self.assignments.get(uid) ?? [];
      },
      async createAssignment(input: AssignmentInput & { id?: string }) {
        const list = self.assignments.get(uid) ?? [];
        const record: AssignmentRecordDTO = {
          id: input.id ?? randomUUID(),
          userId: uid,
          courseId: input.courseId ?? null,
          subjectName: input.subjectName,
          title: input.title,
          notes: input.notes ?? null,
          dueAt: input.dueAt,
          completed: input.completed ?? false,
          estimatedMinutes: input.estimatedMinutes ?? null,
          importance: input.importance ?? 'medium',
          source: 'student',
          revision: 1,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        };
        list.push(record);
        self.assignments.set(uid, list);
        return record;
      },
      async updateAssignment(id: string, input: PatchAssignmentInput) {
        const list = self.assignments.get(uid) ?? [];
        const item = list.find(a => a.id === id);
        if (!item) throw new Error('Assignment not found');
        if (item.revision !== input.expectedRevision) {
          throw new (await import('../../server/src/errors.js')).AppError(409, 'REVISION_CONFLICT', 'Revision conflict');
        }
        if (input.title !== undefined) item.title = input.title;
        if (input.notes !== undefined) item.notes = input.notes;
        if (input.dueAt !== undefined) item.dueAt = input.dueAt;
        if (input.completed !== undefined) item.completed = input.completed;
        if (input.estimatedMinutes !== undefined) item.estimatedMinutes = input.estimatedMinutes;
        if (input.importance !== undefined) item.importance = input.importance;
        item.revision += 1;
        item.updatedAt = new Date().toISOString();
        return item;
      },
      async deleteAssignment(id: string, expectedRevision: number) {
        const list = self.assignments.get(uid) ?? [];
        const index = list.findIndex(a => a.id === id);
        if (index === -1) return false;
        const item = list[index];
        if (!item || item.revision !== expectedRevision) {
          throw new (await import('../../server/src/errors.js')).AppError(409, 'REVISION_CONFLICT', 'Revision conflict');
        }
        list.splice(index, 1);
        return true;
      },

      // Announcements
      async listAnnouncements() {
        return self.announcements;
      },

      // Sync receipts
      async receipt(operationId: string) {
        return self.receipts.get(`${uid}:${operationId}`) ?? null;
      },
      async recordReceipt(operationId: string, payloadHash: string, result: AcademicSyncReceipt['result']) {
        self.receipts.set(`${uid}:${operationId}`, { payloadHash, result });
      },
    };

    return action(tx);
  }
}

async function fixture() {
  const identity = new IdentityFixture();
  const repo = new AcademicFixture();
  const signingKey = randomBytes(32).toString('base64url');
  const auth = new AuthService(identity, {
    verify: async token => ({
      googleSubject: token,
      email: `${token}@cb.students.amrita.edu`,
      displayName: token,
    }),
  }, signingKey);
  const config = readEnvironment({ NODE_ENV: 'test', LOG_LEVEL: 'silent' });
  const academic = new AcademicService(repo);
  const app = await buildApp({ config, auth, academic });

  const loginA = await auth.login('alice');
  const loginB = await auth.login('bob');
  const headersA = { authorization: `Bearer ${loginA.accessToken}` };
  const headersB = { authorization: `Bearer ${loginB.accessToken}` };

  return { app, repo, auth, loginA, loginB, headersA, headersB };
}

test('academic endpoints require authentication and valid consent', async () => {
  const { app, repo, loginA, headersA } = await fixture();

  // No auth header -> 401
  const noAuth = await app.inject({ method: 'GET', url: '/api/v1/subjects' });
  assert.equal(noAuth.statusCode, 401);

  // Authenticated, but no consent -> 403
  const noConsent = await app.inject({
    method: 'GET',
    url: '/api/v1/subjects',
    headers: headersA,
  });
  assert.equal(noConsent.statusCode, 403);
  assert.equal(JSON.parse(noConsent.body).error.code, 'CONSENT_REQUIRED');

  // Grant consent
  repo.grantConsent(loginA.account.id, '1');

  // Now permitted -> 200 with empty list
  const permitted = await app.inject({
    method: 'GET',
    url: '/api/v1/subjects',
    headers: headersA,
  });
  assert.equal(permitted.statusCode, 200);
  assert.deepEqual(JSON.parse(permitted.body).data, []);
});

test('academic owner isolation enforces strict user segregation', async () => {
  const { app, repo, loginA, loginB, headersA, headersB } = await fixture();
  repo.grantConsent(loginA.account.id, '1');
  repo.grantConsent(loginB.account.id, '1');

  // Alice creates a subject
  const subRes = await app.inject({
    method: 'POST',
    url: '/api/v1/subjects',
    headers: headersA,
    payload: { code: '23CSE301', name: 'Design and Analysis of Algorithms' },
  });
  assert.equal(subRes.statusCode, 200);
  const subjectA = JSON.parse(subRes.body).data;

  // Bob lists subjects -> sees empty list, cannot see Alice's subject
  const bobSubs = await app.inject({
    method: 'GET',
    url: '/api/v1/subjects',
    headers: headersB,
  });
  assert.equal(bobSubs.statusCode, 200);
  assert.equal(JSON.parse(bobSubs.body).data.length, 0);

  // Bob cannot delete Alice's subject
  const bobDel = await app.inject({
    method: 'DELETE',
    url: `/api/v1/subjects/${subjectA.id}`,
    headers: headersB,
  });
  assert.equal(bobDel.statusCode, 404);
});

test('timetable, attendance, and assignments validate invariants and concurrency', async () => {
  const { app, repo, loginA, headersA } = await fixture();
  repo.grantConsent(loginA.account.id, '1');

  // Class schedule invalid time (endMinute <= startMinute) -> 400
  const invalidClass = await app.inject({
    method: 'POST',
    url: '/api/v1/timetable',
    headers: headersA,
    payload: {
      subjectName: 'Algorithms',
      weekday: 2,
      startMinute: 600,
      endMinute: 540,
      room: 'AB1-204',
    },
  });
  assert.equal(invalidClass.statusCode, 400);

  // Valid class schedule creation -> 200
  const validClass = await app.inject({
    method: 'POST',
    url: '/api/v1/timetable',
    headers: headersA,
    payload: {
      subjectName: 'Algorithms',
      weekday: 2,
      startMinute: 540,
      endMinute: 600,
      room: 'AB1-204',
    },
  });
  assert.equal(validClass.statusCode, 200);
  const createdClass = JSON.parse(validClass.body).data;
  assert.equal(createdClass.revision, 1);

  // Update with wrong expectedRevision -> 409
  const conflictUpdate = await app.inject({
    method: 'PATCH',
    url: `/api/v1/timetable/${createdClass.id}`,
    headers: headersA,
    payload: { room: 'AB1-205', expectedRevision: 99 },
  });
  assert.equal(conflictUpdate.statusCode, 409);

  // Update with correct expectedRevision -> 200
  const okUpdate = await app.inject({
    method: 'PATCH',
    url: `/api/v1/timetable/${createdClass.id}`,
    headers: headersA,
    payload: { room: 'AB1-205', expectedRevision: 1 },
  });
  assert.equal(okUpdate.statusCode, 200);
  assert.equal(JSON.parse(okUpdate.body).data.room, 'AB1-205');
  assert.equal(JSON.parse(okUpdate.body).data.revision, 2);

  // Attendance validation (attended > conducted) -> 400
  const badAttendance = await app.inject({
    method: 'POST',
    url: '/api/v1/attendance',
    headers: headersA,
    payload: {
      subjectKey: 'algorithms',
      subjectName: 'Algorithms',
      attended: 25,
      conducted: 20,
    },
  });
  assert.equal(badAttendance.statusCode, 400);

  // Valid attendance creation -> 200
  const goodAttendance = await app.inject({
    method: 'POST',
    url: '/api/v1/attendance',
    headers: headersA,
    payload: {
      subjectKey: 'algorithms',
      subjectName: 'Algorithms',
      attended: 18,
      conducted: 20,
      minimumPercentage: 75.0,
    },
  });
  assert.equal(goodAttendance.statusCode, 200);
  assert.equal(JSON.parse(goodAttendance.body).data.attended, 18);

  // Assignment creation and revision-guarded deletion
  const asgnRes = await app.inject({
    method: 'POST',
    url: '/api/v1/assignments',
    headers: headersA,
    payload: {
      subjectName: 'Algorithms',
      title: 'Dynamic Programming Problem Set',
      dueAt: '2026-10-25T18:30:00.000Z',
      importance: 'high',
    },
  });
  assert.equal(asgnRes.statusCode, 200);
  const createdAsgn = JSON.parse(asgnRes.body).data;

  // Stale delete -> 409
  const badDel = await app.inject({
    method: 'DELETE',
    url: `/api/v1/assignments/${createdAsgn.id}`,
    headers: headersA,
    payload: { expectedRevision: 2 },
  });
  assert.equal(badDel.statusCode, 409);

  // Valid delete -> 200
  const okDel = await app.inject({
    method: 'DELETE',
    url: `/api/v1/assignments/${createdAsgn.id}`,
    headers: headersA,
    payload: { expectedRevision: 1 },
  });
  assert.equal(okDel.statusCode, 200);
});

test('bulk academic sync applies records idempotently and handles duplicates', async () => {
  const { app, repo, loginA, headersA } = await fixture();
  repo.grantConsent(loginA.account.id, '10');

  const operationId = randomUUID();
  const syncPayload = {
    operationId,
    consentSequence: '10',
    subjects: [{ code: '23MAT201', name: 'Discrete Mathematics' }],
    courses: [],
    classes: [
      {
        subjectName: 'Discrete Mathematics',
        weekday: 1,
        startMinute: 480,
        endMinute: 540,
        room: 'Math Lab',
      },
    ],
    attendance: [
      {
        subjectKey: 'discrete-math',
        subjectName: 'Discrete Mathematics',
        attended: 10,
        conducted: 12,
        minimumPercentage: 80,
      },
    ],
    assignments: [
      {
        subjectName: 'Discrete Mathematics',
        title: 'Graph Theory Assignment',
        dueAt: '2026-10-24T18:00:00.000Z',
      },
    ],
  };

  // Initial sync push -> 200
  const pushRes = await app.inject({
    method: 'POST',
    url: '/api/v1/sync/academic',
    headers: headersA,
    payload: syncPayload,
  });
  assert.equal(pushRes.statusCode, 200);
  const receipt = JSON.parse(pushRes.body).data;
  assert.equal(receipt.subjectsCount, 1);
  assert.equal(receipt.classesCount, 1);
  assert.equal(receipt.attendanceCount, 1);
  assert.equal(receipt.assignmentsCount, 1);

  // Identical retry returns saved receipt without re-executing
  const retryRes = await app.inject({
    method: 'POST',
    url: '/api/v1/sync/academic',
    headers: headersA,
    payload: syncPayload,
  });
  assert.equal(retryRes.statusCode, 200);
  assert.deepEqual(JSON.parse(retryRes.body).data, receipt);

  // Conflicting payload under same operationId -> 409
  const conflictPayload = {
    ...syncPayload,
    subjects: [{ code: '23MAT201', name: 'Advanced Discrete Math' }],
  };
  const conflictRes = await app.inject({
    method: 'POST',
    url: '/api/v1/sync/academic',
    headers: headersA,
    payload: conflictPayload,
  });
  assert.equal(conflictRes.statusCode, 409);
  assert.equal(JSON.parse(conflictRes.body).error.code, 'SYNC_CONFLICT');
});

test('public announcements can be retrieved by students', async () => {
  const { app, repo, loginA, headersA } = await fixture();
  repo.grantConsent(loginA.account.id, '1');

  const res = await app.inject({
    method: 'GET',
    url: '/api/v1/announcements',
    headers: headersA,
  });
  assert.equal(res.statusCode, 200);
  const items = JSON.parse(res.body).data;
  assert.equal(items.length, 1);
  assert.equal(items[0].title, 'Mid-term schedule published');
});
