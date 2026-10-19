import { defineConfig } from 'prisma/config';

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: {path: 'prisma/migrations'},
  // Schema validation/generation must work without a database. Migration
  // commands fail explicitly until DATABASE_URL is set; no fallback DB.
  ...(process.env.DATABASE_URL ? {datasource: {url: process.env.DATABASE_URL}} : {}),
});
