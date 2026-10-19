# Campus Sārathi API

Phase 1 foundation: Fastify, TypeScript, Zod and a Prisma/PostgreSQL identity
schema, Google verification adapter and application session endpoints. Auth is
fixture-tested; live Google and real DB integration remain unverified. Health
never implies database or full application readiness.

Requires Node 22.12+ (Node 24 is available in this Codex runtime). The system
Node 20.18.1 is too old for the selected dependencies. Use a supported Node in
your terminal before these commands:

```powershell
npm ci
npm run check
npm test
npm run build
npm start
```

Defaults to 127.0.0.1:3000. GET /api/v1/health reports process liveness.
GET /api/v1/ready returns 503 without DATABASE_URL or when schema probes fail.
Academic resources remain unavailable, never mock student data. Security headers,
request size/time limits, rate limiting, safe errors and server-generated
request IDs are present. Logs omit bodies, query strings and credentials.
Proxy trust and CORS are not opened indiscriminately.

For local configuration copy .env.example to .env and edit locally. Never
commit or paste credentials. Install PostgreSQL using the official Windows
installer, create a dedicated development database/role and set DATABASE_URL.
The initial migration creates users, academic profiles, hashed-token session
storage and separate academic/Gemini consent events, with SQL constraints and
cascading deletion. Sign-in, refresh, logout and basic /users/me server code is
implemented. Development academic consent and GET/PUT own academic profile are now implemented.
They use authenticated owner context, strict Zod schemas, transaction consent
checks, per-user lifecycle locking and optimistic profile revisions. The second
migration tightens semester/date/programme constraints; apply all migrations to
both development and test databases. Server account deletion remains open.

GET /privacy/notice and GET/POST /privacy/consent are separate from local mobile
consent. See ../docs/API_SPEC.md for expectedSequence/expectedRevision contracts.
Academic routes deliberately return PRIVACY_NOT_READY under NODE_ENV=production
until public privacy/deletion prerequisites are implemented. The development
notice does not establish compliance or production readiness.

Current backend evidence: check/build pass, 19 tests pass, 3 real PostgreSQL
tests skipped without TEST_DATABASE_URL. No migrations or live DB locks have
been verified. Flutter profile editing is device-only; upload/sync is pending.

See ../docs/GOOGLE_AUTH_SETUP.md for client registration, signing-key configuration
and verification limits. Development returns AUTH_NOT_CONFIGURED until all auth
settings exist. Production requires DB and auth settings at boot.

After creating the dedicated development database/role and setting DATABASE_URL:

```powershell
npm run db:validate
npm run db:migrate
npm run db:generate
npm run check
npm test
npm run build
npm start
```

Create a separate test database and set TEST_DATABASE_URL locally. Apply the
same migration to it before running integration tests. In a separate PowerShell
session where TEST_DATABASE_URL is already a process environment variable:

```powershell
$env:DATABASE_URL = $env:TEST_DATABASE_URL
npm run db:migrate
```

Alternatively configure DATABASE_URL to the test URL in that session before
migration. Review the target carefully; .env is loaded without overriding an
existing process variable. The real PostgreSQL test creates UUID-scoped test
records and deletes only its own records, never resets/drops a database. If
TEST_DATABASE_URL is absent it is explicitly SKIPPED. No production resources
have been provisioned.
