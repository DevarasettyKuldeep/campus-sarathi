import { buildApp } from './app.js';
import { readEnvironment } from './config/env.js';
import { createDatabase, probeDatabase } from './database.js';
import { PrismaAuthRepository } from './modules/auth/prisma_repository.js';
import { GoogleIdentityVerifier } from './modules/auth/google_identity.js';
import { AuthService } from './modules/auth/service.js';
import { ProfileService } from './modules/profile/service.js';
import { PrismaProfileRepository } from './modules/profile/prisma_repository.js';

async function main() {
  const config = readEnvironment(process.env);
  const database = config.DATABASE_URL ? createDatabase(config.DATABASE_URL) : undefined;
  const auth = database && config.GOOGLE_CLIENT_IDS && config.AUTH_SIGNING_KEY
    ? new AuthService(new PrismaAuthRepository(database),
        new GoogleIdentityVerifier(config.GOOGLE_CLIENT_IDS), config.AUTH_SIGNING_KEY)
    : undefined;
  const app = await buildApp({config,
    ...(database ? {readiness: () => probeDatabase(database)} : {}),
    ...(auth ? {auth} : {}),
    ...(database ? {profiles: new ProfileService(new PrismaProfileRepository(database))} : {})});
  if (database) app.addHook('onClose', async () => { await database.$disconnect(); });
  let closing = false;
  const shutdown = async () => {
    if (closing) return;
    closing = true;
    try { await app.close(); } catch { process.exitCode = 1; }
  };
  process.once('SIGINT', () => { void shutdown(); });
  process.once('SIGTERM', () => { void shutdown(); });
  await app.listen({host: config.HOST, port: config.PORT});
}

main().catch((error: unknown) => {
  // Environment errors expose field names only; network errors may contain
  // deployment details, so do not indiscriminately print arbitrary messages.
  if (error instanceof Error && error.message.startsWith('Invalid environment fields:')) {
    console.error(error.message);
  } else {
    console.error('API startup failed. Check infrastructure and port configuration.');
  }
  process.exitCode = 1;
});
