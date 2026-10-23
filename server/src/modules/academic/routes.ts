import type { FastifyInstance, FastifyRequest } from 'fastify';
import { AppError } from '../../errors.js';
import type { AuthService } from '../auth/service.js';
import type { AcademicService } from './service.js';

export function registerAcademicRoutes(
  app: FastifyInstance,
  auth: AuthService | undefined,
  academic: AcademicService | undefined,
  production: boolean = false,
) {
  const session = async (request: FastifyRequest) => {
    if (!auth) throw new AppError(503, 'AUTH_NOT_CONFIGURED', 'Sign-in is not available yet.');
    const verified = await auth.authenticate(request.headers.authorization);
    if (!academic) throw new AppError(503, 'SERVICE_NOT_READY', 'Academic storage is not available yet.');
    if (production) throw new AppError(503, 'PRIVACY_NOT_READY', 'Public academic onboarding is not available yet.');
    return verified;
  };

  // Subjects
  app.get('/api/v1/subjects', async request => {
    const verified = await session(request);
    return { data: await academic!.listSubjects(verified), meta: { requestId: request.id } };
  });

  app.post('/api/v1/subjects', async request => {
    const verified = await session(request);
    return { data: await academic!.createSubject(verified, request.body as any), meta: { requestId: request.id } };
  });

  app.delete('/api/v1/subjects/:id', async request => {
    const verified = await session(request);
    const { id } = request.params as { id: string };
    return { data: await academic!.deleteSubject(verified, id), meta: { requestId: request.id } };
  });

  // Courses
  app.get('/api/v1/courses', async request => {
    const verified = await session(request);
    return { data: await academic!.listCourses(verified), meta: { requestId: request.id } };
  });

  app.post('/api/v1/courses', async request => {
    const verified = await session(request);
    return { data: await academic!.createCourse(verified, request.body as any), meta: { requestId: request.id } };
  });

  app.delete('/api/v1/courses/:id', async request => {
    const verified = await session(request);
    const { id } = request.params as { id: string };
    return { data: await academic!.deleteCourse(verified, id), meta: { requestId: request.id } };
  });

  // Timetable
  app.get('/api/v1/timetable', async request => {
    const verified = await session(request);
    return { data: await academic!.listClasses(verified), meta: { requestId: request.id } };
  });

  app.post('/api/v1/timetable', async request => {
    const verified = await session(request);
    return { data: await academic!.createClass(verified, request.body as any), meta: { requestId: request.id } };
  });

  app.patch('/api/v1/timetable/:id', async request => {
    const verified = await session(request);
    const { id } = request.params as { id: string };
    return { data: await academic!.updateClass(verified, id, request.body as any), meta: { requestId: request.id } };
  });

  app.delete('/api/v1/timetable/:id', async request => {
    const verified = await session(request);
    const { id } = request.params as { id: string };
    const { expectedRevision } = (request.body as { expectedRevision?: number }) ?? {};
    return { data: await academic!.deleteClass(verified, id, expectedRevision ?? 0), meta: { requestId: request.id } };
  });

  // Attendance
  app.get('/api/v1/attendance', async request => {
    const verified = await session(request);
    return { data: await academic!.listAttendance(verified), meta: { requestId: request.id } };
  });

  app.post('/api/v1/attendance', async request => {
    const verified = await session(request);
    return { data: await academic!.saveAttendance(verified, request.body as any), meta: { requestId: request.id } };
  });

  app.patch('/api/v1/attendance/:id', async request => {
    const verified = await session(request);
    const { id } = request.params as { id: string };
    return { data: await academic!.updateAttendance(verified, id, request.body as any), meta: { requestId: request.id } };
  });

  // Assignments
  app.get('/api/v1/assignments', async request => {
    const verified = await session(request);
    return { data: await academic!.listAssignments(verified), meta: { requestId: request.id } };
  });

  app.post('/api/v1/assignments', async request => {
    const verified = await session(request);
    return { data: await academic!.createAssignment(verified, request.body as any), meta: { requestId: request.id } };
  });

  app.patch('/api/v1/assignments/:id', async request => {
    const verified = await session(request);
    const { id } = request.params as { id: string };
    return { data: await academic!.updateAssignment(verified, id, request.body as any), meta: { requestId: request.id } };
  });

  app.delete('/api/v1/assignments/:id', async request => {
    const verified = await session(request);
    const { id } = request.params as { id: string };
    const { expectedRevision } = (request.body as { expectedRevision?: number }) ?? {};
    return { data: await academic!.deleteAssignment(verified, id, expectedRevision ?? 0), meta: { requestId: request.id } };
  });

  // Announcements
  app.get('/api/v1/announcements', async request => {
    const verified = await session(request);
    const { scope } = (request.query as { scope?: string }) ?? {};
    return { data: await academic!.listAnnouncements(verified, scope), meta: { requestId: request.id } };
  });

  // Bulk Academic Sync
  app.post('/api/v1/sync/academic', async request => {
    const verified = await session(request);
    return { data: await academic!.syncAcademic(verified, request.body as any), meta: { requestId: request.id } };
  });
}
