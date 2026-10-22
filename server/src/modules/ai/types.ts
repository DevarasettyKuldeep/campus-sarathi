export interface AcademicAssignment {
  id: string;
  title: string;
  subject: string;
  dueAt: string;
  complete: boolean;
}

export interface AcademicClass {
  id: string;
  subject: string;
  weekday: number;
  startMinute: number;
  endMinute: number;
  room: string;
}

export interface AcademicAttendance {
  subject: string;
  attended: number;
  conducted: number;
  percentage?: number | null | undefined;
  minimumPercentage?: number | null | undefined;
  safeToSkipNext?: boolean | null | undefined;
  classesNeededForMinimum?: number | null | undefined;
}

export interface AcademicContext {
  programme?: string | undefined;
  semesterNumber?: number | undefined;
  assignments?: AcademicAssignment[] | undefined;
  classes?: AcademicClass[] | undefined;
  attendance?: AcademicAttendance[] | undefined;
}

export interface ActionProposal {
  id: string;
  actionType: 'schedule_study' | 'add_assignment';
  title: string;
  description: string;
  payload: Record<string, unknown>;
  expiresAt: string;
}

export interface ChatMessage {
  id: string;
  sender: 'user' | 'assistant';
  content: string;
  references?: string[] | undefined;
  actionProposal?: ActionProposal | undefined;
  feedback?: ('helpful' | 'not_helpful') | undefined;
  createdAt: string;
}

export interface ChatRequest {
  clientMessageId: string;
  message: string;
  context?: Partial<AcademicContext> | undefined;
}

export interface ChatResponse {
  messageId: string;
  clientMessageId: string;
  reply: string;
  references: string[];
  actionProposal?: ActionProposal | undefined;
}
