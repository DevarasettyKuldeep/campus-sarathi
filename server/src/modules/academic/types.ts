import { z } from 'zod';
import type { Session } from '../auth/types.js';

export const day = z.string().regex(/^\d{4}-\d{2}-\d{2}$/).refine(value => {
  const parsed = new Date(`${value}T00:00:00.000Z`);
  return Number.isFinite(parsed.getTime()) && parsed.toISOString().slice(0, 10) === value
    && value >= '2000-01-01' && value <= '2100-12-31';
});

export const sequence = z.string().regex(/^[1-9]\d{0,18}$/)
  .refine(value => /^[1-9]\d{0,18}$/.test(value) && BigInt(value) <= 9223372036854775807n);

export const subjectInput = z.strictObject({
  code: z.string().trim().min(1).max(50).refine(v => !/[\u0000-\u001f\u007f]/.test(v)),
  name: z.string().trim().min(1).max(200).refine(v => !/[\u0000-\u001f\u007f]/.test(v)),
});

export const courseInput = z.strictObject({
  subjectId: z.string().uuid(),
  semesterLabel: z.string().trim().min(1).max(50),
  credits: z.number().int().min(0).max(30).nullable().optional(),
  attendanceThreshold: z.number().min(1).max(100).nullable().optional(),
});

export const classScheduleInput = z.strictObject({
  courseId: z.string().uuid().nullable().optional(),
  subjectName: z.string().trim().min(1).max(200),
  weekday: z.number().int().min(1).max(7),
  startMinute: z.number().int().min(0).max(1439),
  endMinute: z.number().int().min(0).max(1439),
  room: z.string().trim().min(1).max(200),
}).refine(v => v.endMinute > v.startMinute, {
  message: 'endMinute must be greater than startMinute',
});

export const patchClassScheduleInput = z.strictObject({
  weekday: z.number().int().min(1).max(7).optional(),
  startMinute: z.number().int().min(0).max(1439).optional(),
  endMinute: z.number().int().min(0).max(1439).optional(),
  room: z.string().trim().min(1).max(200).optional(),
  expectedRevision: z.number().int().min(1),
}).refine(v => {
  if (v.startMinute !== undefined && v.endMinute !== undefined) {
    return v.endMinute > v.startMinute;
  }
  return true;
}, {
  message: 'endMinute must be greater than startMinute',
});

export const attendanceInput = z.strictObject({
  courseId: z.string().uuid().nullable().optional(),
  subjectKey: z.string().trim().min(1).max(200),
  subjectName: z.string().trim().min(1).max(200),
  attended: z.number().int().min(0).max(100000),
  conducted: z.number().int().min(0).max(100000),
  minimumPercentage: z.number().min(0.01).max(100).nullable().optional(),
}).refine(v => v.attended <= v.conducted, {
  message: 'attended classes cannot exceed conducted classes',
});

export const patchAttendanceInput = z.strictObject({
  attended: z.number().int().min(0).max(100000),
  conducted: z.number().int().min(0).max(100000),
  minimumPercentage: z.number().min(0.01).max(100).nullable().optional(),
  expectedRevision: z.number().int().min(1),
}).refine(v => v.attended <= v.conducted, {
  message: 'attended classes cannot exceed conducted classes',
});

export const assignmentInput = z.strictObject({
  courseId: z.string().uuid().nullable().optional(),
  subjectName: z.string().trim().min(1).max(200),
  title: z.string().trim().min(1).max(200),
  notes: z.string().max(2000).nullable().optional(),
  dueAt: z.string().datetime(),
  completed: z.boolean().default(false).optional(),
  estimatedMinutes: z.number().int().min(0).max(10000).nullable().optional(),
  importance: z.enum(['low', 'medium', 'high']).default('medium').optional(),
});

export const patchAssignmentInput = z.strictObject({
  title: z.string().trim().min(1).max(200).optional(),
  notes: z.string().max(2000).nullable().optional(),
  dueAt: z.string().datetime().optional(),
  completed: z.boolean().optional(),
  estimatedMinutes: z.number().int().min(0).max(10000).nullable().optional(),
  importance: z.enum(['low', 'medium', 'high']).optional(),
  expectedRevision: z.number().int().min(1),
});

export const bulkAcademicSyncInput = z.strictObject({
  operationId: z.string().uuid(),
  consentSequence: sequence,
  subjects: z.array(subjectInput.extend({ id: z.string().uuid().optional() })).max(50).default([]),
  courses: z.array(courseInput.extend({ id: z.string().uuid().optional() })).max(50).default([]),
  classes: z.array(classScheduleInput.extend({ id: z.string().uuid().optional() })).max(100).default([]),
  attendance: z.array(attendanceInput.extend({ id: z.string().uuid().optional() })).max(50).default([]),
  assignments: z.array(assignmentInput.extend({ id: z.string().uuid().optional() })).max(200).default([]),
});

export type SubjectInput = z.infer<typeof subjectInput>;
export type CourseInput = z.infer<typeof courseInput>;
export type ClassScheduleInput = z.infer<typeof classScheduleInput>;
export type PatchClassScheduleInput = z.infer<typeof patchClassScheduleInput>;
export type AttendanceInput = z.infer<typeof attendanceInput>;
export type PatchAttendanceInput = z.infer<typeof patchAttendanceInput>;
export type AssignmentInput = z.infer<typeof assignmentInput>;
export type PatchAssignmentInput = z.infer<typeof patchAssignmentInput>;
export type BulkAcademicSyncInput = z.infer<typeof bulkAcademicSyncInput>;

export interface SubjectRecord {
  id: string;
  userId: string;
  code: string;
  name: string;
  revision: number;
  createdAt: string;
  updatedAt: string;
}

export interface CourseRecord {
  id: string;
  userId: string;
  subjectId: string;
  semesterLabel: string;
  credits: number | null;
  attendanceThreshold: number | null;
  revision: number;
  createdAt: string;
  updatedAt: string;
}

export interface ClassScheduleRecord {
  id: string;
  userId: string;
  courseId: string | null;
  subjectName: string;
  weekday: number;
  startMinute: number;
  endMinute: number;
  room: string;
  source: string;
  revision: number;
  createdAt: string;
  updatedAt: string;
}

export interface AttendanceRecordDTO {
  id: string;
  userId: string;
  courseId: string | null;
  subjectKey: string;
  subjectName: string;
  attended: number;
  conducted: number;
  minimumPercentage: number | null;
  source: string;
  revision: number;
  observedAt: string;
  createdAt: string;
  updatedAt: string;
}

export interface AssignmentRecordDTO {
  id: string;
  userId: string;
  courseId: string | null;
  subjectName: string;
  title: string;
  notes: string | null;
  dueAt: string;
  completed: boolean;
  estimatedMinutes: number | null;
  importance: 'low' | 'medium' | 'high';
  source: string;
  revision: number;
  createdAt: string;
  updatedAt: string;
}

export interface AnnouncementRecordDTO {
  id: string;
  scope: string;
  title: string;
  body: string;
  originUrl: string | null;
  publishedAt: string;
  fetchedAt: string;
}

export interface AcademicSyncReceipt {
  payloadHash: string;
  result: {
    syncedAt: string;
    subjectsCount: number;
    coursesCount: number;
    classesCount: number;
    attendanceCount: number;
    assignmentsCount: number;
  };
}

export interface AcademicTransaction {
  checkConsent(): Promise<{ granted: boolean; sequence: string } | null>;
  
  // Subjects
  listSubjects(): Promise<SubjectRecord[]>;
  createSubject(input: SubjectInput & { id?: string | undefined }): Promise<SubjectRecord>;
  deleteSubject(id: string): Promise<boolean>;

  // Courses
  listCourses(): Promise<CourseRecord[]>;
  createCourse(input: CourseInput & { id?: string | undefined }): Promise<CourseRecord>;
  deleteCourse(id: string): Promise<boolean>;

  // Timetable
  listClasses(): Promise<ClassScheduleRecord[]>;
  createClass(input: ClassScheduleInput & { id?: string | undefined }): Promise<ClassScheduleRecord>;
  updateClass(id: string, input: PatchClassScheduleInput): Promise<ClassScheduleRecord>;
  deleteClass(id: string, expectedRevision: number): Promise<boolean>;

  // Attendance
  listAttendance(): Promise<AttendanceRecordDTO[]>;
  saveAttendance(input: AttendanceInput & { id?: string | undefined }): Promise<AttendanceRecordDTO>;
  updateAttendance(id: string, input: PatchAttendanceInput): Promise<AttendanceRecordDTO>;

  // Assignments
  listAssignments(): Promise<AssignmentRecordDTO[]>;
  createAssignment(input: AssignmentInput & { id?: string | undefined }): Promise<AssignmentRecordDTO>;
  updateAssignment(id: string, input: PatchAssignmentInput): Promise<AssignmentRecordDTO>;
  deleteAssignment(id: string, expectedRevision: number): Promise<boolean>;

  // Announcements
  listAnnouncements(scope?: string): Promise<AnnouncementRecordDTO[]>;

  // Sync receipts
  receipt(operationId: string): Promise<AcademicSyncReceipt | null>;
  recordReceipt(operationId: string, payloadHash: string, result: AcademicSyncReceipt['result']): Promise<void>;
}

export interface AcademicRepository {
  withSession<T>(session: Session, action: (tx: AcademicTransaction) => Promise<T>): Promise<T>;
}
