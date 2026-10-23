import type { PrismaClient, Prisma } from '../../generated/prisma/client.js';
import { AppError } from '../../errors.js';
import type { Session } from '../auth/types.js';
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
} from './types.js';

export class PrismaAcademicRepository implements AcademicRepository {
  constructor(private readonly database: PrismaClient) {}

  withSession<T>(session: Session, action: (tx: AcademicTransaction) => Promise<T>): Promise<T> {
    return this.database.$transaction(async tx => {
      // Advisory xact lock on academic lifecycle
      await tx.$queryRaw`WITH locked AS MATERIALIZED (
        SELECT pg_advisory_xact_lock(hashtext(${`academic:${session.userId}`}))
      ) SELECT 1 AS acquired FROM locked`;

      const active = await tx.session.findFirst({
        where: { id: session.id, userId: session.userId, revokedAt: null, expiresAt: { gt: new Date() } },
      });
      if (!active) throw new AppError(401, 'INVALID_SESSION', 'Sign in again to continue.');

      return action(new PrismaAcademicTransaction(tx, session.userId));
    });
  }
}

class PrismaAcademicTransaction implements AcademicTransaction {
  constructor(private readonly tx: Prisma.TransactionClient, private readonly userId: string) {}

  async checkConsent() {
    const event = await this.tx.consentRecord.findFirst({
      where: { userId: this.userId, purpose: 'ACADEMIC_PROCESSING' },
      orderBy: { sequence: 'desc' },
    });
    return event ? { sequence: event.sequence.toString(), granted: event.granted } : null;
  }

  // Subjects
  async listSubjects(): Promise<SubjectRecord[]> {
    const rows = await this.tx.subject.findMany({
      where: { userId: this.userId },
      orderBy: { code: 'asc' },
    });
    return rows.map(r => ({
      id: r.id,
      userId: r.userId,
      code: r.code,
      name: r.name,
      revision: r.revision,
      createdAt: r.createdAt.toISOString(),
      updatedAt: r.updatedAt.toISOString(),
    }));
  }

  async createSubject(input: SubjectInput & { id?: string | undefined }): Promise<SubjectRecord> {
    const row = await this.tx.subject.upsert({
      where: { userId_code: { userId: this.userId, code: input.code } },
      create: {
        ...(input.id ? { id: input.id } : {}),
        userId: this.userId,
        code: input.code,
        name: input.name,
      },
      update: {
        name: input.name,
        revision: { increment: 1 },
      },
    });
    return {
      id: row.id,
      userId: row.userId,
      code: row.code,
      name: row.name,
      revision: row.revision,
      createdAt: row.createdAt.toISOString(),
      updatedAt: row.updatedAt.toISOString(),
    };
  }

  async deleteSubject(id: string): Promise<boolean> {
    const res = await this.tx.subject.deleteMany({
      where: { id, userId: this.userId },
    });
    return res.count > 0;
  }

  // Courses
  async listCourses(): Promise<CourseRecord[]> {
    const rows = await this.tx.course.findMany({
      where: { userId: this.userId },
      orderBy: { semesterLabel: 'asc' },
    });
    return rows.map(r => ({
      id: r.id,
      userId: r.userId,
      subjectId: r.subjectId,
      semesterLabel: r.semesterLabel,
      credits: r.credits,
      attendanceThreshold: r.attendanceThreshold ? Number(r.attendanceThreshold) : null,
      revision: r.revision,
      createdAt: r.createdAt.toISOString(),
      updatedAt: r.updatedAt.toISOString(),
    }));
  }

  async createCourse(input: CourseInput & { id?: string | undefined }): Promise<CourseRecord> {
    const row = await this.tx.course.upsert({
      where: {
        userId_subjectId_semesterLabel: {
          userId: this.userId,
          subjectId: input.subjectId,
          semesterLabel: input.semesterLabel,
        },
      },
      create: {
        ...(input.id ? { id: input.id } : {}),
        userId: this.userId,
        subjectId: input.subjectId,
        semesterLabel: input.semesterLabel,
        credits: input.credits ?? null,
        attendanceThreshold: input.attendanceThreshold ?? null,
      },
      update: {
        credits: input.credits ?? null,
        attendanceThreshold: input.attendanceThreshold ?? null,
        revision: { increment: 1 },
      },
    });
    return {
      id: row.id,
      userId: row.userId,
      subjectId: row.subjectId,
      semesterLabel: row.semesterLabel,
      credits: row.credits,
      attendanceThreshold: row.attendanceThreshold ? Number(row.attendanceThreshold) : null,
      revision: row.revision,
      createdAt: row.createdAt.toISOString(),
      updatedAt: row.updatedAt.toISOString(),
    };
  }

  async deleteCourse(id: string): Promise<boolean> {
    const res = await this.tx.course.deleteMany({
      where: { id, userId: this.userId },
    });
    return res.count > 0;
  }

  // Timetable
  async listClasses(): Promise<ClassScheduleRecord[]> {
    const rows = await this.tx.classSchedule.findMany({
      where: { userId: this.userId },
      orderBy: [{ weekday: 'asc' }, { startMinute: 'asc' }],
    });
    return rows.map(r => ({
      id: r.id,
      userId: r.userId,
      courseId: r.courseId,
      subjectName: r.subjectName,
      weekday: r.weekday,
      startMinute: r.startMinute,
      endMinute: r.endMinute,
      room: r.room,
      source: r.source,
      revision: r.revision,
      createdAt: r.createdAt.toISOString(),
      updatedAt: r.updatedAt.toISOString(),
    }));
  }

  async createClass(input: ClassScheduleInput & { id?: string | undefined }): Promise<ClassScheduleRecord> {
    const row = await this.tx.classSchedule.create({
      data: {
        ...(input.id ? { id: input.id } : {}),
        userId: this.userId,
        courseId: input.courseId ?? null,
        subjectName: input.subjectName,
        weekday: input.weekday,
        startMinute: input.startMinute,
        endMinute: input.endMinute,
        room: input.room,
        source: 'student',
      },
    });
    return {
      id: row.id,
      userId: row.userId,
      courseId: row.courseId,
      subjectName: row.subjectName,
      weekday: row.weekday,
      startMinute: row.startMinute,
      endMinute: row.endMinute,
      room: row.room,
      source: row.source,
      revision: row.revision,
      createdAt: row.createdAt.toISOString(),
      updatedAt: row.updatedAt.toISOString(),
    };
  }

  async updateClass(id: string, input: PatchClassScheduleInput): Promise<ClassScheduleRecord> {
    const current = await this.tx.classSchedule.findFirst({
      where: { id, userId: this.userId },
    });
    if (!current) throw new AppError(404, 'NOT_FOUND', 'Class schedule not found.');
    if (current.revision !== input.expectedRevision) {
      throw new AppError(409, 'REVISION_CONFLICT', 'Class schedule has been modified. Reload before updating.');
    }

    const row = await this.tx.classSchedule.update({
      where: { id },
      data: {
        weekday: input.weekday ?? current.weekday,
        startMinute: input.startMinute ?? current.startMinute,
        endMinute: input.endMinute ?? current.endMinute,
        room: input.room ?? current.room,
        revision: { increment: 1 },
      },
    });
    return {
      id: row.id,
      userId: row.userId,
      courseId: row.courseId,
      subjectName: row.subjectName,
      weekday: row.weekday,
      startMinute: row.startMinute,
      endMinute: row.endMinute,
      room: row.room,
      source: row.source,
      revision: row.revision,
      createdAt: row.createdAt.toISOString(),
      updatedAt: row.updatedAt.toISOString(),
    };
  }

  async deleteClass(id: string, expectedRevision: number): Promise<boolean> {
    const current = await this.tx.classSchedule.findFirst({
      where: { id, userId: this.userId },
    });
    if (!current) return false;
    if (current.revision !== expectedRevision) {
      throw new AppError(409, 'REVISION_CONFLICT', 'Class schedule has been modified. Reload before deleting.');
    }
    await this.tx.classSchedule.delete({ where: { id } });
    return true;
  }

  // Attendance
  async listAttendance(): Promise<AttendanceRecordDTO[]> {
    const rows = await this.tx.attendanceRecord.findMany({
      where: { userId: this.userId },
      orderBy: { subjectName: 'asc' },
    });
    return rows.map(r => ({
      id: r.id,
      userId: r.userId,
      courseId: r.courseId,
      subjectKey: r.subjectKey,
      subjectName: r.subjectName,
      attended: r.attended,
      conducted: r.conducted,
      minimumPercentage: r.minimumPercentage ? Number(r.minimumPercentage) : null,
      source: r.source,
      revision: r.revision,
      observedAt: r.observedAt.toISOString(),
      createdAt: r.createdAt.toISOString(),
      updatedAt: r.updatedAt.toISOString(),
    }));
  }

  async saveAttendance(input: AttendanceInput & { id?: string | undefined }): Promise<AttendanceRecordDTO> {
    const row = await this.tx.attendanceRecord.upsert({
      where: {
        userId_subjectKey_source: {
          userId: this.userId,
          subjectKey: input.subjectKey.toLowerCase(),
          source: 'student',
        },
      },
      create: {
        ...(input.id ? { id: input.id } : {}),
        userId: this.userId,
        courseId: input.courseId ?? null,
        subjectKey: input.subjectKey.toLowerCase(),
        subjectName: input.subjectName,
        attended: input.attended,
        conducted: input.conducted,
        minimumPercentage: input.minimumPercentage ?? null,
        source: 'student',
      },
      update: {
        subjectName: input.subjectName,
        attended: input.attended,
        conducted: input.conducted,
        minimumPercentage: input.minimumPercentage ?? null,
        revision: { increment: 1 },
      },
    });
    return {
      id: row.id,
      userId: row.userId,
      courseId: row.courseId,
      subjectKey: row.subjectKey,
      subjectName: row.subjectName,
      attended: row.attended,
      conducted: row.conducted,
      minimumPercentage: row.minimumPercentage ? Number(row.minimumPercentage) : null,
      source: row.source,
      revision: row.revision,
      observedAt: row.observedAt.toISOString(),
      createdAt: row.createdAt.toISOString(),
      updatedAt: row.updatedAt.toISOString(),
    };
  }

  async updateAttendance(id: string, input: PatchAttendanceInput): Promise<AttendanceRecordDTO> {
    const current = await this.tx.attendanceRecord.findFirst({
      where: { id, userId: this.userId },
    });
    if (!current) throw new AppError(404, 'NOT_FOUND', 'Attendance record not found.');
    if (current.revision !== input.expectedRevision) {
      throw new AppError(409, 'REVISION_CONFLICT', 'Attendance record has been modified. Reload before updating.');
    }

    const row = await this.tx.attendanceRecord.update({
      where: { id },
      data: {
        attended: input.attended,
        conducted: input.conducted,
        minimumPercentage: input.minimumPercentage ?? null,
        revision: { increment: 1 },
      },
    });
    return {
      id: row.id,
      userId: row.userId,
      courseId: row.courseId,
      subjectKey: row.subjectKey,
      subjectName: row.subjectName,
      attended: row.attended,
      conducted: row.conducted,
      minimumPercentage: row.minimumPercentage ? Number(row.minimumPercentage) : null,
      source: row.source,
      revision: row.revision,
      observedAt: row.observedAt.toISOString(),
      createdAt: row.createdAt.toISOString(),
      updatedAt: row.updatedAt.toISOString(),
    };
  }

  // Assignments
  async listAssignments(): Promise<AssignmentRecordDTO[]> {
    const rows = await this.tx.assignmentRecord.findMany({
      where: { userId: this.userId },
      orderBy: [{ completed: 'asc' }, { dueAt: 'asc' }],
    });
    return rows.map(r => ({
      id: r.id,
      userId: r.userId,
      courseId: r.courseId,
      subjectName: r.subjectName,
      title: r.title,
      notes: r.notes,
      dueAt: r.dueAt.toISOString(),
      completed: r.completed,
      estimatedMinutes: r.estimatedMinutes,
      importance: r.importance as 'low' | 'medium' | 'high',
      source: r.source,
      revision: r.revision,
      createdAt: r.createdAt.toISOString(),
      updatedAt: r.updatedAt.toISOString(),
    }));
  }

  async createAssignment(input: AssignmentInput & { id?: string | undefined }): Promise<AssignmentRecordDTO> {
    const row = await this.tx.assignmentRecord.create({
      data: {
        ...(input.id ? { id: input.id } : {}),
        userId: this.userId,
        courseId: input.courseId ?? null,
        subjectName: input.subjectName,
        title: input.title,
        notes: input.notes ?? null,
        dueAt: new Date(input.dueAt),
        completed: input.completed ?? false,
        estimatedMinutes: input.estimatedMinutes ?? null,
        importance: input.importance ?? 'medium',
        source: 'student',
      },
    });
    return {
      id: row.id,
      userId: row.userId,
      courseId: row.courseId,
      subjectName: row.subjectName,
      title: row.title,
      notes: row.notes,
      dueAt: row.dueAt.toISOString(),
      completed: row.completed,
      estimatedMinutes: row.estimatedMinutes,
      importance: row.importance as 'low' | 'medium' | 'high',
      source: row.source,
      revision: row.revision,
      createdAt: row.createdAt.toISOString(),
      updatedAt: row.updatedAt.toISOString(),
    };
  }

  async updateAssignment(id: string, input: PatchAssignmentInput): Promise<AssignmentRecordDTO> {
    const current = await this.tx.assignmentRecord.findFirst({
      where: { id, userId: this.userId },
    });
    if (!current) throw new AppError(404, 'NOT_FOUND', 'Assignment not found.');
    if (current.revision !== input.expectedRevision) {
      throw new AppError(409, 'REVISION_CONFLICT', 'Assignment has been modified. Reload before updating.');
    }

    const row = await this.tx.assignmentRecord.update({
      where: { id },
      data: {
        title: input.title ?? current.title,
        notes: input.notes !== undefined ? input.notes : current.notes,
        dueAt: input.dueAt ? new Date(input.dueAt) : current.dueAt,
        completed: input.completed !== undefined ? input.completed : current.completed,
        estimatedMinutes: input.estimatedMinutes !== undefined ? input.estimatedMinutes : current.estimatedMinutes,
        importance: input.importance ?? current.importance,
        revision: { increment: 1 },
      },
    });
    return {
      id: row.id,
      userId: row.userId,
      courseId: row.courseId,
      subjectName: row.subjectName,
      title: row.title,
      notes: row.notes,
      dueAt: row.dueAt.toISOString(),
      completed: row.completed,
      estimatedMinutes: row.estimatedMinutes,
      importance: row.importance as 'low' | 'medium' | 'high',
      source: row.source,
      revision: row.revision,
      createdAt: row.createdAt.toISOString(),
      updatedAt: row.updatedAt.toISOString(),
    };
  }

  async deleteAssignment(id: string, expectedRevision: number): Promise<boolean> {
    const current = await this.tx.assignmentRecord.findFirst({
      where: { id, userId: this.userId },
    });
    if (!current) return false;
    if (current.revision !== expectedRevision) {
      throw new AppError(409, 'REVISION_CONFLICT', 'Assignment has been modified. Reload before deleting.');
    }
    await this.tx.assignmentRecord.delete({ where: { id } });
    return true;
  }

  // Announcements
  async listAnnouncements(scope?: string): Promise<AnnouncementRecordDTO[]> {
    const rows = await this.tx.announcementRecord.findMany({
      ...(scope ? { where: { scope } } : {}),
      orderBy: { publishedAt: 'desc' },
      take: 50,
    });
    return rows.map(r => ({
      id: r.id,
      scope: r.scope,
      title: r.title,
      body: r.body,
      originUrl: r.originUrl,
      publishedAt: r.publishedAt.toISOString(),
      fetchedAt: r.fetchedAt.toISOString(),
    }));
  }

  // Sync receipts
  async receipt(operationId: string): Promise<AcademicSyncReceipt | null> {
    const row = await this.tx.academicSyncReceipt.findUnique({
      where: { userId_operationId: { userId: this.userId, operationId } },
    });
    if (!row) return null;
    return {
      payloadHash: Buffer.from(row.payloadHash).toString('hex'),
      result: row.result as any,
    };
  }

  async recordReceipt(operationId: string, payloadHash: string, result: AcademicSyncReceipt['result']): Promise<void> {
    await this.tx.academicSyncReceipt.create({
      data: {
        userId: this.userId,
        operationId,
        payloadHash: new Uint8Array(Buffer.from(payloadHash, 'hex')),
        result,
      },
    });
  }
}
