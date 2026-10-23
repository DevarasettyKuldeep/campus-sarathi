import { randomUUID } from 'node:crypto';
import { z } from 'zod';
import { AppError } from '../../errors.js';
import type { Session } from '../auth/types.js';
import type {
  ActionProposal,
  ChatRequest,
  ChatResponse,
} from './types.js';
import {
  calculateAttendanceMetrics,
  sortPendingAssignments,
  getTodayClasses,
} from './academic_calculator.js';
import type { AcademicService } from '../academic/service.js';

export const chatRequestSchema = z.strictObject({
  clientMessageId: z.string().min(1).max(100),
  message: z.string().trim().min(1).max(2000),
  context: z
    .object({
      programme: z.string().optional(),
      semesterNumber: z.number().optional(),
      assignments: z
        .array(
          z.object({
            id: z.string(),
            title: z.string(),
            subject: z.string(),
            dueAt: z.string(),
            complete: z.boolean(),
          })
        )
        .optional(),
      classes: z
        .array(
          z.object({
            id: z.string(),
            subject: z.string(),
            weekday: z.number(),
            startMinute: z.number(),
            endMinute: z.number(),
            room: z.string(),
          })
        )
        .optional(),
      attendance: z
        .array(
          z.object({
            subject: z.string(),
            attended: z.number(),
            conducted: z.number(),
            percentage: z.number().nullable().optional(),
            minimumPercentage: z.number().nullable().optional(),
            safeToSkipNext: z.boolean().nullable().optional(),
            classesNeededForMinimum: z.number().nullable().optional(),
          })
        )
        .optional(),
    })
    .optional(),
});

export const feedbackSchema = z.strictObject({
  messageId: z.string().min(1).max(100),
  helpful: z.boolean(),
});

export const actionConfirmSchema = z.strictObject({
  actionId: z.string().uuid(),
});

export interface AiProposalRecord {
  proposal: ActionProposal;
  consumed: boolean;
}

export interface AiRepository {
  recordMessage(userId: string, messageId: string, role: string, content: string): Promise<void>;
  saveActionProposal(userId: string, proposal: ActionProposal): Promise<void>;
  getActionProposal(userId: string, actionId: string): Promise<AiProposalRecord | null>;
  consumeActionProposal(userId: string, actionId: string): Promise<boolean>;
  recordFeedback(userId: string, messageId: string, helpful: boolean): Promise<void>;
}

export class InMemoryAiRepository implements AiRepository {
  private proposals = new Map<string, { userId: string; proposal: ActionProposal; consumed: boolean }>();
  private feedback = new Map<string, { userId: string; helpful: boolean }>();

  async recordMessage(): Promise<void> {}

  async saveActionProposal(userId: string, proposal: ActionProposal): Promise<void> {
    this.proposals.set(proposal.id, { userId, proposal, consumed: false });
  }

  async getActionProposal(userId: string, actionId: string): Promise<AiProposalRecord | null> {
    const entry = this.proposals.get(actionId);
    if (!entry || entry.userId !== userId) return null;
    return { proposal: entry.proposal, consumed: entry.consumed };
  }

  async consumeActionProposal(userId: string, actionId: string): Promise<boolean> {
    const entry = this.proposals.get(actionId);
    if (!entry || entry.userId !== userId || entry.consumed) return false;
    entry.consumed = true;
    return true;
  }

  async recordFeedback(userId: string, messageId: string, helpful: boolean): Promise<void> {
    this.feedback.set(`${userId}:${messageId}`, { userId, helpful });
  }
}

export class AiService {
  constructor(
    private readonly repository: AiRepository = new InMemoryAiRepository(),
    private readonly clock: () => Date = () => new Date(),
    private readonly academic?: AcademicService
  ) {}

  async chat(session: Session, request: ChatRequest): Promise<ChatResponse> {
    const parsed = chatRequestSchema.safeParse(request);
    if (!parsed.success) {
      throw new AppError(400, 'VALIDATION_ERROR', 'Invalid chat request structure.');
    }

    const { message, clientMessageId } = parsed.data;
    let context = parsed.data.context;

    if (!context && this.academic) {
      try {
        const [dbClasses, dbAtt, dbAsgn] = await Promise.all([
          this.academic.listClasses(session),
          this.academic.listAttendance(session),
          this.academic.listAssignments(session),
        ]);
        context = {
          classes: dbClasses.map(c => ({
            id: c.id,
            subject: c.subjectName,
            weekday: c.weekday,
            startMinute: c.startMinute,
            endMinute: c.endMinute,
            room: c.room,
          })),
          attendance: dbAtt.map(a => ({
            subject: a.subjectName,
            attended: a.attended,
            conducted: a.conducted,
            minimumPercentage: a.minimumPercentage ?? undefined,
          })),
          assignments: dbAsgn.map(as => ({
            id: as.id,
            title: as.title,
            subject: as.subjectName,
            dueAt: as.dueAt,
            complete: as.completed,
          })),
        };
      } catch {
        // Fall back gracefully if academic storage is unconsented or offline
      }
    }

    context ??= {
      assignments: [],
      classes: [],
      attendance: [],
    };

    // Sanitize and detect prompt injection attempts
    if (
      /ignore\s+(all\s+)?(previous|prior)\s+instructions/i.test(message) ||
      /system\s+prompt/i.test(message) ||
      /select\s+.*\s+from\s+users/i.test(message) ||
      /drop\s+table/i.test(message)
    ) {
      return {
        messageId: randomUUID(),
        clientMessageId,
        reply: "I am your Campus Sārathi academic companion. I can only assist with your personal academic schedule, attendance, and coursework planning.",
        references: [],
      };
    }

    const lower = message.toLowerCase();
    const references: string[] = [];
    let reply = '';
    let actionProposal: ActionProposal | undefined;

    // 1. Skip class / attendance questions
    if (lower.includes('skip') || lower.includes('miss') || lower.includes('attendance')) {
      const attendanceList = context.attendance ?? [];
      const matchedAtt = attendanceList.find((att) =>
        lower.includes(att.subject.toLowerCase())
      );

      if (matchedAtt) {
        references.push(`attendance:${matchedAtt.subject}`);
        const metrics = calculateAttendanceMetrics(
          matchedAtt.attended,
          matchedAtt.conducted,
          matchedAtt.minimumPercentage ?? null
        );

        if (metrics.percentage === null) {
          reply = `No classes have been recorded for ${matchedAtt.subject} yet, so attendance risk cannot be calculated.`;
        } else if (matchedAtt.minimumPercentage == null) {
          reply = `Your recorded attendance for ${matchedAtt.subject} is ${matchedAtt.attended}/${matchedAtt.conducted} (${metrics.percentage.toFixed(1)}%). However, no minimum threshold is configured for this course, so the safety risk cannot be determined.`;
        } else if (metrics.safeToSkipNext === true) {
          const nextPercent = ((matchedAtt.attended / (matchedAtt.conducted + 1)) * 100).toFixed(1);
          reply = `Your recorded attendance for ${matchedAtt.subject} is ${matchedAtt.attended}/${matchedAtt.conducted} (${metrics.percentage.toFixed(1)}%). If you miss the next class, it will drop to ${nextPercent}%, which is still above your ${matchedAtt.minimumPercentage}% requirement. You can safely afford to miss it if necessary, but attending is still advised.`;
        } else {
          const needed = metrics.classesNeededForMinimum ?? 1;
          reply = `Your recorded attendance for ${matchedAtt.subject} is ${matchedAtt.attended}/${matchedAtt.conducted} (${metrics.percentage.toFixed(1)}%), which is close to or below your ${matchedAtt.minimumPercentage}% requirement. Missing the next class would put you at serious attendance risk. You need to attend the next ${needed} consecutive class(es) to maintain the required threshold.`;
        }
      } else if (attendanceList.length > 0) {
        references.push('attendance:summary');
        const summary = attendanceList
          .map((a) => {
            const p = a.conducted > 0 ? `${((a.attended / a.conducted) * 100).toFixed(1)}%` : 'No classes';
            return `${a.subject}: ${p} (${a.attended}/${a.conducted})`;
          })
          .join('\n');
        reply = `Here is your currently recorded attendance:\n${summary}\n\nAsk me specifically about any course to calculate whether you can afford to miss an upcoming session.`;
      } else {
        reply = "You haven't saved any attendance records yet. Add your courses and attendance in the Academic tab to calculate skip margins and risk alerts.";
      }
    }
    // 2. What should I do / focus on / today schedule
    else if (
      lower.includes('today') ||
      lower.includes('what should i do') ||
      lower.includes('focus') ||
      lower.includes('schedule')
    ) {
      const todayClasses = getTodayClasses(context.classes ?? []);
      const { urgent, upcoming } = sortPendingAssignments(context.assignments ?? []);

      const parts: string[] = [];

      if (todayClasses.length > 0) {
        references.push('timetable:today');
        const classStr = todayClasses
          .map((c) => {
            const startH = Math.floor(c.startMinute / 60).toString().padStart(2, '0');
            const startM = (c.startMinute % 60).toString().padStart(2, '0');
            return `• ${c.subject} at ${startH}:${startM} (${c.room})`;
          })
          .join('\n');
        parts.push(`Today's classes:\n${classStr}`);
      } else {
        parts.push("You have no classes scheduled for today.");
      }

      const firstUrgent = urgent[0];
      if (firstUrgent) {
        references.push('assignments:urgent');
        parts.push(`Urgent assignments:\n` + urgent.map((a) => `• ${a.title} (${a.subject}) due ${a.dueAt.slice(0, 10)}`).join('\n'));
        parts.push(`Recommendation: Focus on completing ${firstUrgent.title} first.`);

        // Action proposal to schedule study session
        actionProposal = {
          id: randomUUID(),
          actionType: 'schedule_study',
          title: `Schedule Study for ${firstUrgent.subject}`,
          description: `Dedicate a 90-minute study block today for "${firstUrgent.title}".`,
          payload: {
            subject: firstUrgent.subject,
            assignmentId: firstUrgent.id,
            durationMinutes: 90,
          },
          expiresAt: new Date(this.clock().getTime() + 60 * 60 * 1000).toISOString(),
        };
      } else if (upcoming.length > 0) {
        const firstUpcoming = upcoming[0];
        references.push('assignments:upcoming');
        parts.push(`No urgent deadlines in the next 3 days. Your next upcoming task is ${firstUpcoming ? `${firstUpcoming.title} (${firstUpcoming.subject})` : 'on track'}.`);
      } else {
        parts.push("You have no pending assignments on record. Great job staying ahead!");
      }

      reply = parts.join('\n\n');
    }
    // 3. Overwhelmed / triage
    else if (
      lower.includes('overwhelm') ||
      lower.includes('stress') ||
      lower.includes('too much') ||
      lower.includes('assignments')
    ) {
      const { urgent, upcoming } = sortPendingAssignments(context.assignments ?? []);
      const total = urgent.length + upcoming.length;

      if (total === 0) {
        reply = "You have no pending assignments recorded. Take a breath and relax, or add any new assignments in the Academic tab.";
      } else {
        references.push('assignments:triage');
        const firstUrgent = urgent[0];
        const firstUpcoming = upcoming[0];
        const primaryTask = firstUrgent?.title ?? firstUpcoming?.title ?? 'your current task';
        reply = `You have ${total} pending assignment(s): ${urgent.length} urgent and ${upcoming.length} further out. Let's break this down into manageable steps: first focus only on ${primaryTask}, and leave the remaining tasks for tomorrow.`;

        if (firstUrgent) {
          actionProposal = {
            id: randomUUID(),
            actionType: 'schedule_study',
            title: `Plan Focus Block: ${firstUrgent.title}`,
            description: `Divide workload into a focused 1-hour session today.`,
            payload: {
              subject: firstUrgent.subject,
              assignmentId: firstUrgent.id,
              durationMinutes: 60,
            },
            expiresAt: new Date(this.clock().getTime() + 60 * 60 * 1000).toISOString(),
          };
        }
      }
    }
    // 4. Default academic assistance
    else {
      reply = `Hello! I am Campus Sārathi, your academic companion. You can ask me:\n• "What should I do today?"\n• "Can I skip tomorrow's Networks class?"\n• "I am overwhelmed with assignments."\n• "What is my current attendance summary?"`;
    }

    const messageId = randomUUID();
    if (actionProposal) {
      await this.repository.saveActionProposal(session.userId, actionProposal);
    }
    await this.repository.recordMessage(session.userId, messageId, 'assistant', reply);

    const result: ChatResponse = {
      messageId,
      clientMessageId,
      reply,
      references,
    };
    if (actionProposal) {
      result.actionProposal = actionProposal;
    }
    return result;
  }

  async confirmAction(session: Session, actionId: string): Promise<{ confirmed: boolean; proposal: ActionProposal }> {
    const record = await this.repository.getActionProposal(session.userId, actionId);
    if (!record) {
      throw new AppError(404, 'NOT_FOUND', 'Action proposal not found.');
    }
    if (record.consumed) {
      throw new AppError(409, 'ALREADY_EXECUTED', 'Action has already been confirmed.');
    }

    const expires = new Date(record.proposal.expiresAt).getTime();
    if (expires < this.clock().getTime()) {
      throw new AppError(410, 'PROPOSAL_EXPIRED', 'Action proposal has expired. Please ask the assistant again.');
    }

    const consumed = await this.repository.consumeActionProposal(session.userId, actionId);
    if (!consumed) {
      throw new AppError(409, 'ALREADY_EXECUTED', 'Action has already been confirmed.');
    }

    return { confirmed: true, proposal: record.proposal };
  }

  async recordFeedback(session: Session, messageId: string, helpful: boolean): Promise<void> {
    await this.repository.recordFeedback(session.userId, messageId, helpful);
  }
}
