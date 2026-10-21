import type { PrismaClient, Prisma } from '../../generated/prisma/client.js';
import { AppError } from '../../errors.js';
import type { Session } from '../auth/types.js';
import { profileInput, type ProfileRepository, type ProfileTransaction, type ProfileInput,
  type ConsentInput, type AcademicProfile } from './service.js';

export class PrismaProfileRepository implements ProfileRepository {
  constructor(private readonly database: PrismaClient) {}

  withSession<T>(session: Session, action: (tx: ProfileTransaction) => Promise<T>): Promise<T> {
    return this.database.$transaction(async tx => {
      // Consent withdrawal and profile work for the same user must serialize.
      // A future account deletion service must take this same lifecycle lock.
      await tx.$queryRaw`WITH locked AS MATERIALIZED (
        SELECT pg_advisory_xact_lock(hashtext(${`academic:${session.userId}`}))
      ) SELECT 1 AS acquired FROM locked`;
      const active = await tx.session.findFirst({where: {id: session.id,
        userId: session.userId, revokedAt: null, expiresAt: {gt: new Date()}}});
      if (!active) throw new AppError(401, 'INVALID_SESSION', 'Sign in again to continue.');
      return action(new PrismaProfileTransaction(tx, session.userId));
    });
  }
}

class PrismaProfileTransaction implements ProfileTransaction {
  constructor(private readonly tx: Prisma.TransactionClient, private readonly userId: string) {}

  async receipt(operationId: string) {
    const row = await this.tx.profileSyncReceipt.findUnique({where: {
      userId_operationId: {userId: this.userId, operationId}}});
    if (!row) return null;
    // Receipt data is application-owned, but corrupted storage must fail closed.
    const stored = row.result;
    if (!stored || typeof stored !== 'object' || Array.isArray(stored)) {
      throw new Error('Invalid profile sync receipt.');
    }
    const {revision, updatedAt, ...profile} = stored;
    const checked = profileInput.safeParse({...profile, expectedRevision: 0});
    if (!checked.success || typeof revision !== 'number' || !Number.isInteger(revision) ||
        revision < 1 || revision > 2147483647 ||
        typeof updatedAt !== 'string' || !Number.isFinite(Date.parse(updatedAt))) {
      throw new Error('Invalid profile sync receipt.');
    }
    const {expectedRevision: _, ...fields} = checked.data;
    return {payloadHash: Buffer.from(row.payloadHash).toString('hex'),
      result: {...fields, revision, updatedAt}};
  }

  async recordReceipt(operationId: string, payloadHash: string, result: AcademicProfile) {
    await this.tx.profileSyncReceipt.create({data: {userId: this.userId,
      operationId, payloadHash: new Uint8Array(Buffer.from(payloadHash, 'hex')), result}});
  }

  async consent() {
    const event = await this.tx.consentRecord.findFirst({where: {
      userId: this.userId, purpose: 'ACADEMIC_PROCESSING'}, orderBy: {sequence: 'desc'}});
    return event ? {sequence: event.sequence.toString(), granted: event.granted,
      noticeVersion: event.noticeVersion, eventAt: event.eventAt.toISOString()} : null;
  }

  async recordConsent(input: ConsentInput) {
    const event = await this.tx.consentRecord.create({data: {userId: this.userId,
      purpose: input.purpose, noticeVersion: input.noticeVersion, granted: input.granted}});
    return {sequence: event.sequence.toString(), granted: event.granted,
      noticeVersion: event.noticeVersion, eventAt: event.eventAt.toISOString()};
  }

  async profile() {
    const row = await this.tx.academicProfile.findUnique({where: {userId: this.userId}});
    return row ? {programme: row.programme, semesterNumber: row.semesterNumber,
      semesterStart: row.semesterStart.toISOString().slice(0, 10),
      semesterEnd: row.semesterEnd.toISOString().slice(0, 10), timezone: 'Asia/Kolkata' as const,
      revision: row.revision, updatedAt: row.updatedAt.toISOString()} : null;
  }

  async saveProfile(input: ProfileInput) {
    const data = {programme: input.programme, semesterNumber: input.semesterNumber,
      semesterStart: new Date(`${input.semesterStart}T00:00:00Z`),
      semesterEnd: new Date(`${input.semesterEnd}T00:00:00Z`), timezone: input.timezone};
    if (input.expectedRevision === 0) {
      await this.tx.academicProfile.create({data: {...data, userId: this.userId}});
    } else {
      const updated = await this.tx.academicProfile.updateMany({where: {
        userId: this.userId, revision: input.expectedRevision},
        data: {...data, revision: {increment: 1}}});
      if (updated.count !== 1) throw new AppError(409, 'REVISION_CONFLICT', 'Reload your profile before trying again.');
    }
    return (await this.profile())!;
  }
}
