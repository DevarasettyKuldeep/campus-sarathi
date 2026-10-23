import { createHash } from 'node:crypto';
import { AppError } from '../../errors.js';
import type { Session } from '../auth/types.js';
import {
  type AcademicRepository,
  type AcademicTransaction,
  type SubjectInput,
  type CourseInput,
  type ClassScheduleInput,
  type PatchClassScheduleInput,
  type AttendanceInput,
  type PatchAttendanceInput,
  type AssignmentInput,
  type PatchAssignmentInput,
  type BulkAcademicSyncInput,
  subjectInput,
  courseInput,
  classScheduleInput,
  patchClassScheduleInput,
  attendanceInput,
  patchAttendanceInput,
  assignmentInput,
  patchAssignmentInput,
  bulkAcademicSyncInput,
} from './types.js';

export class AcademicService {
  constructor(private readonly repository: AcademicRepository) {}

  private async requireConsent(tx: AcademicTransaction) {
    const consent = await tx.checkConsent();
    if (!consent?.granted) {
      throw new AppError(403, 'CONSENT_REQUIRED', 'Academic processing consent is required.');
    }
    return consent;
  }

  // --- Subjects ---
  async listSubjects(session: Session) {
    return this.repository.withSession(session, async tx => {
      await this.requireConsent(tx);
      return tx.listSubjects();
    });
  }

  async createSubject(session: Session, input: SubjectInput) {
    const parsed = subjectInput.safeParse(input);
    if (!parsed.success) {
      throw new AppError(400, 'VALIDATION_ERROR', 'Invalid subject code or name.');
    }
    return this.repository.withSession(session, async tx => {
      await this.requireConsent(tx);
      return tx.createSubject(parsed.data);
    });
  }

  async deleteSubject(session: Session, id: string) {
    return this.repository.withSession(session, async tx => {
      await this.requireConsent(tx);
      const deleted = await tx.deleteSubject(id);
      if (!deleted) throw new AppError(404, 'NOT_FOUND', 'Subject not found.');
      return { id };
    });
  }

  // --- Courses ---
  async listCourses(session: Session) {
    return this.repository.withSession(session, async tx => {
      await this.requireConsent(tx);
      return tx.listCourses();
    });
  }

  async createCourse(session: Session, input: CourseInput) {
    const parsed = courseInput.safeParse(input);
    if (!parsed.success) {
      throw new AppError(400, 'VALIDATION_ERROR', 'Invalid course details.');
    }
    return this.repository.withSession(session, async tx => {
      await this.requireConsent(tx);
      return tx.createCourse(parsed.data);
    });
  }

  async deleteCourse(session: Session, id: string) {
    return this.repository.withSession(session, async tx => {
      await this.requireConsent(tx);
      const deleted = await tx.deleteCourse(id);
      if (!deleted) throw new AppError(404, 'NOT_FOUND', 'Course not found.');
      return { id };
    });
  }

  // --- Timetable ---
  async listClasses(session: Session) {
    return this.repository.withSession(session, async tx => {
      await this.requireConsent(tx);
      return tx.listClasses();
    });
  }

  async createClass(session: Session, input: ClassScheduleInput) {
    const parsed = classScheduleInput.safeParse(input);
    if (!parsed.success) {
      throw new AppError(400, 'VALIDATION_ERROR', 'Invalid class schedule details.');
    }
    return this.repository.withSession(session, async tx => {
      await this.requireConsent(tx);
      return tx.createClass(parsed.data);
    });
  }

  async updateClass(session: Session, id: string, input: PatchClassScheduleInput) {
    const parsed = patchClassScheduleInput.safeParse(input);
    if (!parsed.success) {
      throw new AppError(400, 'VALIDATION_ERROR', 'Invalid class schedule update parameters.');
    }
    return this.repository.withSession(session, async tx => {
      await this.requireConsent(tx);
      return tx.updateClass(id, parsed.data);
    });
  }

  async deleteClass(session: Session, id: string, expectedRevision: number) {
    if (!expectedRevision || expectedRevision < 1) {
      throw new AppError(400, 'VALIDATION_ERROR', 'Expected revision is required for class deletion.');
    }
    return this.repository.withSession(session, async tx => {
      await this.requireConsent(tx);
      const deleted = await tx.deleteClass(id, expectedRevision);
      if (!deleted) throw new AppError(404, 'NOT_FOUND', 'Class session not found or revision mismatch.');
      return { id };
    });
  }

  // --- Attendance ---
  async listAttendance(session: Session) {
    return this.repository.withSession(session, async tx => {
      await this.requireConsent(tx);
      return tx.listAttendance();
    });
  }

  async saveAttendance(session: Session, input: AttendanceInput) {
    const parsed = attendanceInput.safeParse(input);
    if (!parsed.success) {
      throw new AppError(400, 'VALIDATION_ERROR', 'Invalid attendance counts or percentage.');
    }
    return this.repository.withSession(session, async tx => {
      await this.requireConsent(tx);
      return tx.saveAttendance(parsed.data);
    });
  }

  async updateAttendance(session: Session, id: string, input: PatchAttendanceInput) {
    const parsed = patchAttendanceInput.safeParse(input);
    if (!parsed.success) {
      throw new AppError(400, 'VALIDATION_ERROR', 'Invalid attendance update parameters.');
    }
    return this.repository.withSession(session, async tx => {
      await this.requireConsent(tx);
      return tx.updateAttendance(id, parsed.data);
    });
  }

  // --- Assignments ---
  async listAssignments(session: Session) {
    return this.repository.withSession(session, async tx => {
      await this.requireConsent(tx);
      return tx.listAssignments();
    });
  }

  async createAssignment(session: Session, input: AssignmentInput) {
    const parsed = assignmentInput.safeParse(input);
    if (!parsed.success) {
      throw new AppError(400, 'VALIDATION_ERROR', 'Invalid assignment fields or due date.');
    }
    return this.repository.withSession(session, async tx => {
      await this.requireConsent(tx);
      return tx.createAssignment(parsed.data);
    });
  }

  async updateAssignment(session: Session, id: string, input: PatchAssignmentInput) {
    const parsed = patchAssignmentInput.safeParse(input);
    if (!parsed.success) {
      throw new AppError(400, 'VALIDATION_ERROR', 'Invalid assignment update fields.');
    }
    return this.repository.withSession(session, async tx => {
      await this.requireConsent(tx);
      return tx.updateAssignment(id, parsed.data);
    });
  }

  async deleteAssignment(session: Session, id: string, expectedRevision: number) {
    if (!expectedRevision || expectedRevision < 1) {
      throw new AppError(400, 'VALIDATION_ERROR', 'Expected revision is required for assignment deletion.');
    }
    return this.repository.withSession(session, async tx => {
      await this.requireConsent(tx);
      const deleted = await tx.deleteAssignment(id, expectedRevision);
      if (!deleted) throw new AppError(404, 'NOT_FOUND', 'Assignment not found or revision mismatch.');
      return { id };
    });
  }

  // --- Announcements ---
  async listAnnouncements(session: Session, scope?: string) {
    return this.repository.withSession(session, async tx => {
      return tx.listAnnouncements(scope);
    });
  }

  // --- Bulk Sync Push ---
  async syncAcademic(session: Session, input: BulkAcademicSyncInput) {
    const parsed = bulkAcademicSyncInput.safeParse(input);
    if (!parsed.success) {
      throw new AppError(400, 'VALIDATION_ERROR', 'Invalid academic sync payload structure.');
    }
    const operation = parsed.data;

    // Canonical payload hash
    const payloadHash = createHash('sha256').update(JSON.stringify({
      consentSequence: operation.consentSequence,
      subjects: operation.subjects,
      courses: operation.courses,
      classes: operation.classes,
      attendance: operation.attendance,
      assignments: operation.assignments,
    })).digest('hex');

    return this.repository.withSession(session, async tx => {
      const consent = await tx.checkConsent();
      if (!consent?.granted) {
        throw new AppError(403, 'CONSENT_REQUIRED', 'Academic processing consent is required.');
      }
      if (consent.sequence !== operation.consentSequence) {
        throw new AppError(409, 'CONSENT_MISMATCH', 'Consent sequence mismatch; please re-synchronize consent.');
      }

      const existingReceipt = await tx.receipt(operation.operationId);
      if (existingReceipt) {
        if (existingReceipt.payloadHash !== payloadHash) {
          throw new AppError(409, 'SYNC_CONFLICT', 'Operation ID reused with conflicting payload.');
        }
        return existingReceipt.result;
      }

      // Apply batch items
      for (const sub of operation.subjects) {
        await tx.createSubject(sub);
      }
      for (const crs of operation.courses) {
        await tx.createCourse(crs);
      }
      for (const cls of operation.classes) {
        await tx.createClass(cls);
      }
      for (const att of operation.attendance) {
        await tx.saveAttendance(att);
      }
      for (const asgn of operation.assignments) {
        await tx.createAssignment(asgn);
      }

      const result = {
        syncedAt: new Date().toISOString(),
        subjectsCount: operation.subjects.length,
        coursesCount: operation.courses.length,
        classesCount: operation.classes.length,
        attendanceCount: operation.attendance.length,
        assignmentsCount: operation.assignments.length,
      };

      await tx.recordReceipt(operation.operationId, payloadHash, result);
      return result;
    });
  }
}
