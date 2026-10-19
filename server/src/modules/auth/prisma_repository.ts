import { randomUUID } from 'node:crypto';
import type { PrismaClient } from '../../generated/prisma/client.js';
import type { AuthRepository, VerifiedIdentity, Rotation } from './types.js';

export class PrismaAuthRepository implements AuthRepository {
  constructor(private readonly database: PrismaClient) {}

  async login(identity: VerifiedIdentity, refreshHash: Buffer, now: Date, expiresAt: Date) {
    return this.database.$transaction(async (transaction) => {
      // Never identify or merge accounts by a client email or an email collision.
      const user = await transaction.user.upsert({
        where: {googleSubject: identity.googleSubject},
        create: {...identity, emailVerifiedAt: now},
        update: {email: identity.email, displayName: identity.displayName, emailVerifiedAt: now},
        select: {id: true, email: true, displayName: true},
      });
      const session = await transaction.session.create({data: {
        userId: user.id, familyId: randomUUID(), refreshHash: new Uint8Array(refreshHash), createdAt: now, expiresAt,
      }});
      return {account: user, session};
    });
  }

  async rotate(refreshHash: Buffer, nextHash: Buffer, now: Date): Promise<Rotation> {
    return this.database.$transaction(async (transaction): Promise<Rotation> => {
      const candidate = await transaction.session.findUnique({where: {refreshHash: new Uint8Array(refreshHash)}});
      if (!candidate) return {kind: 'invalid'};
      // Serialize every refresh in a family, including replays of older tokens.
      // Without a family lock, a concurrent rotation can escape replay revocation.
      await transaction.$queryRaw`
        WITH locked AS MATERIALIZED (
          SELECT pg_advisory_xact_lock(hashtext(${candidate.familyId}))
        ) SELECT 1 AS acquired FROM locked`;
      const current = await transaction.session.findUnique({where: {id: candidate.id}});
      if (!current) return {kind: 'invalid'};
      if (current.revokedAt) {
        await transaction.session.updateMany({where: {userId: current.userId,
          familyId: current.familyId, revokedAt: null}, data: {revokedAt: now}});
        // Return, do not throw here: revocation must COMMIT before rejecting.
        return {kind: 'replayed'};
      }
      if (current.expiresAt <= now) return {kind: 'invalid'};
      await transaction.session.update({where: {id: current.id}, data: {revokedAt: now}});
      const session = await transaction.session.create({data: {
        userId: current.userId, familyId: current.familyId, refreshHash: new Uint8Array(nextHash),
        createdAt: now, expiresAt: current.expiresAt,
      }});
      return {kind: 'ok', session};
    });
  }

  async activeSession(sessionId: string, userId: string, now: Date) {
    return this.database.session.findFirst({where: {
      id: sessionId, userId, revokedAt: null, expiresAt: {gt: now},
    }});
  }

  async account(userId: string) {
    return this.database.user.findUnique({where: {id: userId},
      select: {id: true, email: true, displayName: true}});
  }

  async revokeFamily(userId: string, familyId: string, now: Date) {
    await this.database.$transaction(async (transaction) => {
      await transaction.$queryRaw`
        WITH locked AS MATERIALIZED (
          SELECT pg_advisory_xact_lock(hashtext(${familyId}))
        ) SELECT 1 AS acquired FROM locked`;
      await transaction.session.updateMany({where: {userId, familyId, revokedAt: null},
        data: {revokedAt: now}});
    });
  }

  async deleteAccount(userId: string) {
    await this.database.$transaction(async (transaction) => {
      await transaction.$queryRaw`
        WITH locked AS MATERIALIZED (
          SELECT pg_advisory_xact_lock(hashtext(${`academic:${userId}`}))
        ) SELECT 1 AS acquired FROM locked`;
      await transaction.user.delete({where: {id: userId}});
    });
  }
}
