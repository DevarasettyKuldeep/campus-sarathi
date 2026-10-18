# Implementation status — 2026-10-17

Product authority: ../plan.txt. Overall Android MVP remains incomplete.

## Phase 0 manual data acquisition

Implemented: validated local capture of assignments, recurring classes and
attendance; configurable attendance minimum with unknown-data handling; source
labels and recorded timestamps; UUID record IDs; durable Drift/SQLite storage.
Application startup loads committed records, with retry on storage failure.
Records are not uploaded or represented as university-verified.

Local privacy notice is available before collection. Consent is unchecked by
default, stored with notice version/time, and required at the repository
boundary. Profile can erase all active local academic records and consent in
one transaction, returning to onboarding. This is local erasure, not server
account deletion or a claim of full legal compliance.

## Verified evidence

- Flutter 3.44.8 / Dart 3.12.2; dependencies and typed Drift code generated.
- flutter analyze: no issues.
- flutter test: 42 passing auth, domain, SQLite and widget tests.
- Actual file-backed SQLite close/reopen retains assignment ID/completion,
  deadline, class times, attendance minimum, provenance timestamps and consent.
- Local erasure remains effective after database reopen/re-consent.
- SQLite CHECK constraints reject invalid counts and class ranges.
- Failed SQL transaction rolls back earlier writes and preserves existing data.
- Failed local save publishes no in-memory success and permits one safe retry.
- UI tests verify unchecked consent, notice access, gated academic screens,
  erasure confirmation/cancel, manual validation and small-screen keyboard layout.

Android build attempted: fails before app compilation because NDK
28.2.13676358 is incomplete (missing source.properties). SDK-manager repair
stalled and only this task's identified repair process was stopped. No SDK
directory was deleted or license accepted. User notified to repair through
Android Studio. No Android device/AVD available at last check; device runtime
and release checks remain open.

## Phase 1: beginning with backend foundation

Fastify/TypeScript/Zod server foundation passes type checks, six tests and
compilation, including an actual TCP request. It has safe errors, security
headers, rate limits and honest liveness/readiness. The Prisma identity schema
and initial SQL migration are prepared and validated; database integration
has not yet been verified (three PostgreSQL tests skipped).
Google verification, login/refresh/logout and basic account server routes are
implemented and fixture-tested. Real Google and PostgreSQL sessions and Android protected-storage behaviour
remain unverified; academic profile endpoints are source/policy-tested but not
DB-integrated. Sync remains incomplete. Backend suite: 19 passing tests,
3 PostgreSQL tests skipped.
No mock authenticated backend or Gemini response is substituted.

Mobile auth is now wired into the configured shell: sign-in/identity notice,
per-account SQLite lifecycle and unchecked local consent, cached offline state,
resume validation, reconnect and confirmed logout. Revocation closes private
editors; switching accounts cannot render the previous snapshot/consent.
Local writes finish before closure and old disposed stores reject late writes.
Seven shell tests cover these gates, with explicit auth fixtures and real SQLite.
SDK Google/Keystore and live backend behaviour are not proven by widget tests.
Without auth defines debug builds use the separate local development workspace;
release builds fail closed. See ../docs/MOBILE_AUTH_CLIENT.md.

Offline semester profile now supports programme/semester/calendar dates,
validated create/update, unsaved-draft cancel/discard, actual SQLite restart,
migration and erasure. Schema v2 preserves v1 academic rows. Notice v3 requires
renewed consent; profiles never auto-upload. Five profile tests and expanded
account/revocation checks pass.

Server academic notice/consent and own profile GET/PUT are implemented with
strict validation, transaction ownership/session checks, consent withdrawal
serialization and optimistic revisions. They use Prisma in production source,
not a mock. Public academic processing remains fail-closed until production
privacy/deletion readiness. Mobile server-consent/profile sync is not wired.

Remaining: live per-account device/backend verification, conflict/idempotent sync,
privacy/security audit and server deletion; complete academic CRUD; Gemini
adapter/tools/plans/memory/feedback; real student validation and release signing.

## Configuration blockers

PostgreSQL/Docker were not found locally. User notified about PostgreSQL setup.
Google OAuth registration/test identity, Gemini configuration/provider terms,
production privacy contacts/backup policy, Android SDK/device and release
identity/signing are required for their respective later verification gates.
Official university adapters require documented authorised access.

Local-only records belong to this device workspace. They must not be silently
attached to a future signed-in account; account import must be explicit.
