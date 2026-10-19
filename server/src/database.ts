import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from './generated/prisma/client.js';

/** No connection-string fallback: absent configuration never targets a default DB. */
export function createDatabase(connectionString: string) {
  const adapter = new PrismaPg({
    connectionString,
    max: 5,
    connectionTimeoutMillis: 2_000,
    statement_timeout: 2_000,
    query_timeout: 2_500,
  });
  return new PrismaClient({adapter, log: []});
}

export async function probeDatabase(database: PrismaClient): Promise<boolean> {
  // Probe tables, not just TCP reachability: an unmigrated database is not ready.
  try {
    await database.$transaction([
      database.user.findFirst({select: {id: true}}),
      database.academicProfile.findFirst({select: {userId: true}}),
      database.session.findFirst({select: {id: true}}),
      database.consentRecord.findFirst({select: {id: true}}),
    ]);
    return true;
  } catch {
    return false;
  }
}
