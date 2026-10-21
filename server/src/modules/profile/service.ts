import { z } from 'zod';
import { createHash } from 'node:crypto';
import { AppError } from '../../errors.js';
import type { Session } from '../auth/types.js';

export const academicNotice = {
  version: 'server-academic-dev-1',
  developmentOnly: true,
  text: `Campus Sārathi development academic profile processing. If you explicitly consent, this server stores your programme, semester number, semester dates and timezone to organise your academic information. These records are student-entered, not university-verified. Profile data is not sent to Gemini or the university. Google identity/session processing is separate. Local-only academic consent does not authorise an upload. Your latest server consent choice and its notice version/time are retained as evidence. Withdrawal immediately blocks further profile reads and writes; it does not itself erase stored records. Profile and consent records remain in the configured development PostgreSQL database until account deletion or development data cleanup. Server account deletion, backup expiry, operator privacy contact and production notices are not ready; do not use this build for public onboarding. No claim of legal compliance or provider-controlled deletion is made.`,
} as const;

const day = z.string().regex(/^\d{4}-\d{2}-\d{2}$/).refine(value => {
  const parsed = new Date(`${value}T00:00:00.000Z`);
  return Number.isFinite(parsed.getTime()) && parsed.toISOString().slice(0, 10) === value
    && value >= '2000-01-01' && value <= '2100-12-31';
});
const sequence = z.string().regex(/^[1-9]\d{0,18}$/)
  .refine(value => /^[1-9]\d{0,18}$/.test(value) && BigInt(value) <= 9223372036854775807n);
export const consentInput = z.strictObject({
  purpose: z.literal('ACADEMIC_PROCESSING'),
  noticeVersion: z.string().min(1).max(100),
  granted: z.boolean(),
  expectedSequence: sequence.nullable(),
});
export const profileInput = z.strictObject({
  programme: z.string().trim().min(1).max(200).refine(value => !/[\u0000-\u001f\u007f]/.test(value)),
  semesterNumber: z.number().int().min(1).max(30),
  semesterStart: day,
  semesterEnd: day,
  timezone: z.literal('Asia/Kolkata'),
  expectedRevision: z.number().int().min(0).max(2147483646),
}).refine(value => value.semesterEnd >= value.semesterStart);
export type ConsentInput = z.infer<typeof consentInput>;
export type ProfileInput = z.infer<typeof profileInput>;
export type ConsentEvent = {sequence: string; granted: boolean; noticeVersion: string; eventAt: string};
export type AcademicProfile = Omit<ProfileInput, 'expectedRevision'> & {revision: number; updatedAt: string};
export const profileSyncInput = z.strictObject({operationId: z.uuid(),
  consentSequence: sequence, profile: profileInput});
export type ProfileSyncInput = z.infer<typeof profileSyncInput>;
export type ProfileReceipt = {payloadHash: string; result: AcademicProfile};

export interface ProfileTransaction {
  consent(): Promise<ConsentEvent | null>;
  recordConsent(input: ConsentInput): Promise<ConsentEvent>;
  profile(): Promise<AcademicProfile | null>;
  saveProfile(input: ProfileInput): Promise<AcademicProfile>;
  receipt(operationId: string): Promise<ProfileReceipt | null>;
  recordReceipt(operationId: string, payloadHash: string, result: AcademicProfile): Promise<void>;
}
export interface ProfileRepository {
  // Lock the authenticated user's academic lifecycle, verify the session again,
  // and commit/rollback the entire callback atomically. Never accept a body owner.
  withSession<T>(session: Session, action: (tx: ProfileTransaction) => Promise<T>): Promise<T>;
}

export class ProfileService {
  constructor(private readonly repository: ProfileRepository) {}

  consent(session: Session) {
    return this.repository.withSession(session, async tx => this.state(await tx.consent()));
  }

  setConsent(session: Session, input: ConsentInput) {
    const checked = consentInput.safeParse(input);
    if (!checked.success) throw new AppError(400, 'VALIDATION_ERROR', 'Check your consent request fields.');
    input = checked.data;
    return this.repository.withSession(session, async tx => {
      const current = await tx.consent();
      if ((current?.sequence ?? null) !== input.expectedSequence) {
        throw new AppError(409, 'CONSENT_CONFLICT', 'Your consent choice changed. Review the latest choice before trying again.');
      }
      if (input.granted && input.noticeVersion !== academicNotice.version) {
        throw new AppError(409, 'NOTICE_CHANGED', 'Read the current academic notice before consenting.');
      }
      return this.state(await tx.recordConsent(input));
    });
  }

  get(session: Session) {
    return this.repository.withSession(session, async tx => {
      await this.requireConsent(tx);
      return tx.profile();
    });
  }

  save(session: Session, input: ProfileInput) {
    const checked = profileInput.safeParse(input);
    if (!checked.success) throw new AppError(400, 'VALIDATION_ERROR', 'Check programme, semester and date fields.');
    input = checked.data;
    return this.repository.withSession(session, async tx => {
      await this.requireConsent(tx);
      const current = await tx.profile();
      if ((current?.revision ?? 0) !== input.expectedRevision) {
        throw new AppError(409, 'REVISION_CONFLICT', 'Your profile changed. Reload it and preserve your draft before trying again.');
      }
      return tx.saveProfile(input);
    });
  }

  sync(session: Session, input: ProfileSyncInput) {
    const checked = profileSyncInput.safeParse(input);
    if (!checked.success) throw new AppError(400, 'VALIDATION_ERROR', 'Check the profile sync operation.');
    const operation = checked.data;
    // Hash a canonical, validated field order, not arbitrary JSON key order.
    const payloadHash = createHash('sha256').update(JSON.stringify({
      consentSequence: operation.consentSequence,
      profile: operation.profile,
    })).digest('hex');
    return this.repository.withSession(session, async tx => {
      const consent = await tx.consent();
      if (!this.state(consent).granted || consent?.sequence !== operation.consentSequence) {
        throw new AppError(403, 'ACADEMIC_CONSENT_REQUIRED', 'Your server consent changed. Review it before resuming profile sync.');
      }
      // Even a replay must pass current auth/consent before receiving its result.
      const receipt = await tx.receipt(operation.operationId);
      if (receipt) {
        if (receipt.payloadHash !== payloadHash) {
          throw new AppError(409, 'IDEMPOTENCY_CONFLICT', 'This operation ID was already used for different profile data.');
        }
        return {operationId: operation.operationId, profile: receipt.result};
      }
      const current = await tx.profile();
      if ((current?.revision ?? 0) !== operation.profile.expectedRevision) {
        throw new AppError(409, 'REVISION_CONFLICT', 'Your cloud profile changed. Preserve your local draft and review both versions.');
      }
      const result = await tx.saveProfile(operation.profile);
      await tx.recordReceipt(operation.operationId, payloadHash, result);
      return {operationId: operation.operationId, profile: result};
    });
  }

  private state(event: ConsentEvent | null) {
    return {purpose: 'ACADEMIC_PROCESSING' as const, granted: event?.granted === true
      && event.noticeVersion === academicNotice.version, event};
  }

  private async requireConsent(tx: ProfileTransaction) {
    if (!this.state(await tx.consent()).granted) {
      throw new AppError(403, 'ACADEMIC_CONSENT_REQUIRED', 'Review and accept the server academic notice before using your cloud profile.');
    }
  }
}
