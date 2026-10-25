# Phase checkpoint — 2026-10-17

## Latest checkpoint — Phase 1 academic profile and server consent

Implemented offline semester profile: programme, semester number, calendar
dates and Asia/Kolkata context; validated editor, unsaved-change confirmation,
SQLite persistence/update/erasure and account isolation. Schema v2 adds only
the profile table; the v1 upgrade preserves existing records. Notice
local-academic-3 requires renewed local consent before the new processing.

Implemented server profile/consent routes and Prisma repository. Separate
development notice, authenticated owner context, session revalidation,
per-user transaction lock, current-notice consent gate, withdrawal and
revision conflicts. Stale consent grants cannot override a newer withdrawal.
Production academic routes deliberately fail PRIVACY_NOT_READY until production
privacy/deletion prerequisites are completed. No Gemini permission is granted.

Verification: Flutter analysis clean; 42 tests pass, including actual file-backed
SQLite upgrade/reopen, failure rollback, profile account isolation and revoked
unsaved-editor removal. Backend type checks/build pass; 19 tests pass and
3 PostgreSQL tests are explicitly skipped without TEST_DATABASE_URL.
The new DB migration has not been executed. No live Google/device test or APK.

Incomplete: mobile cloud-consent UI, profile HTTP adapter and reliable
profile/outbox synchronization. Saving the local profile does not upload it.
Server consent withdrawal stops server processing but does not claim erasure.
Server account deletion and broader Phase 1.5 review remain pending.
External blockers unchanged: incomplete NDK 28.2.13676358, Android test device,
PostgreSQL and Google/HTTPS configuration. Phase 1 is not complete.

## Earlier checkpoint — authenticated mobile shell (historical)

The Google/HTTP/protected-storage adapters are now connected to the configured
Flutter shell. Implemented sign-in notice, per-account consent/storage,
offline/reconnect state, lifecycle validation and confirmed logout. Release
configuration fails closed; debug guest records remain separate. Private
editors disappear on revocation/account change; pending writes finish before
storage closes and old snapshots cannot appear for a new account.

Verification: Flutter static analysis clean, 36 tests pass. Six new tests cover
the journey, decline-without-consent and account lifecycle using explicit auth fixtures and actual
SQLite. All body and cleanup assertions complete; the initial fake-async test
teardown stall was fixed by draining its microtasks before awaiting closure,
not by skipping disposal. No live OAuth, Android Keystore or device claim.
See MOBILE_AUTH_CLIENT.md.

Authentication checkpoint: server Google identity adapter, signed access tokens,
hashed/rotating refresh tokens, family revocation, logout and basic /users/me
routes are now implemented. Zod rejects client ownership fields and partial
auth configuration. Production requires DB, registered Google audiences and a
server signing key. Google's actual verifier runs in local RSA-fixture tests;
these are not live student logins. PostgreSQL rotation uses a family transaction
lock, with committed revocation on replay. Its concurrent/replay/logout test
is explicitly skipped until a real test DB is configured. Current backend:
14 tests pass, 2 PostgreSQL tests skipped; type checking and compilation pass.
The Google certificate-fetch outage test uses a real local HTTP endpoint and
verifies one request with retries disabled, without contacting Google.
Manual Google OAuth/client/Workspace feasibility setup is documented in
GOOGLE_AUTH_SETUP.md. Phase 1 remains incomplete pending real integrations,
live Flutter sign-in/storage verification, academic profile and sync.

Drift/SQLite persistence is implemented and wired to application startup and
manual-entry screens. Local privacy notice/unchecked consent precedes entry;
repository writes also require consent. Profile has confirmed local erasure
and withdrawal, with no account-deletion or legal-compliance claim. File-backed
database reopen tests prove values, UUIDs, source timestamps and consent survive;
erasure survives another reopen. CHECK constraints and transaction rollback are
tested. Earlier persistence-only checkpoint: analysis clean; all 16 tests passed, including a failed
save followed by a safe retry without phantom or duplicate records.

Android build remains blocked by the incomplete NDK 28.2.13676358. The stalled
SDK-manager command was identified and stopped; no SDK directory was deleted.
User notified immediately about SDK licenses, Android device/AVD setup and NDK
repair through Android Studio. No APK/device run is verified. Phase 1 backend
foundation is now implemented; local PostgreSQL was not found and user notified
to install it. Cloud authentication source is now implemented but not live-verified; sync
and Gemini remain unimplemented.

Earlier API-foundation verification: TypeScript checks pass, six Node tests pass and the
compiled JavaScript build succeeds. Tests include an actual localhost TCP
request, environment rejection without secret disclosure, readiness success and
failure through an explicitly injected test probe, malformed/oversized requests,
safe internal errors, security headers and rate limits. The real entrypoint has
no configured DB and returns readiness 503; this is not DB integration evidence.
Node 24.19.0 from the available bundled runtime was used for verification.

Earlier database-preparation checkpoint: initial Prisma users/profile/sessions/consent schema,
SQL migration with domain/date/digest constraints and cascading deletion,
generated typed client, and bounded PostgreSQL connection pool/schema readiness
probe. Prisma validation, TypeScript checks and compilation passed. At that
checkpoint: 6 passed, 1 real PostgreSQL test explicitly SKIPPED because
TEST_DATABASE_URL is absent. Migration execution, constraint enforcement and
cascade behaviour are not claimed verified. Configure dev/test PostgreSQL URLs,
migrate both targets and run the real integration test before completing this
module. See server/README.md.

Compiled entrypoint smoke check: started dist/main.js on loopback port 3189,
received HTTP 200 from /api/v1/health and HTTP 503 SERVICE_NOT_READY from
/api/v1/ready without a database. Request logs contained only generated ID,
route template and status. No development server is required to remain running
after this check.

## Earlier capture-only checkpoint (historical)

## Phase 0: in progress

Read the full master brief and audited all existing prototype source/config.
Created implementation decisions, phased gates, target repository/screen
architecture, database constraints, versioned API contracts, source evidence and
AI behaviour acceptance criteria. These designs do not imply implemented APIs.

First implemented module: manual academic capture validation. Existing transient
assignment/class/attendance paths now use scrollable full-screen forms with
inline errors. Repository guards reject invalid input independently of widgets.
Class ordering uses day and minute precision. Attendance supports unknown data,
optional student-supplied minimum and manual provenance. Unknown policy does
not display a healthy/risky conclusion. Dashboard lists a deadline without
claiming intelligent prioritisation. Canned chat was removed.

## Actual verification

- Dependencies resolved; Android platform scaffold generated.
- Final flutter analyze: no issues, exit 0.
- Final flutter test: 11 passed, exit 0. Test file:
  app/test/manual_capture_test.dart.
- Tested impossible counts, non-finite/out-of-range policies, zero counts,
  exact threshold comparison, blank fields, attendance updates, invalid class
  ranges, minute ordering, assignment completion, form error/success paths,
  320x568 editor with simulated keyboard insets, and empty-start/navigation.
- Android build apk --debug: failed, Gradle CXX1101. Installed NDK
  28.2.13676358 lacks source.properties; its only content was an old .installer
  directory. This happened before application compilation, so no APK verified.
- flutter doctor: SDK available, some licenses unaccepted; no Android device
  connected; emulator list empty. No device runtime or release verification.

Flutter cache access was approved; previous claims of broken OS cache
permissions were not established. Do not alter ACLs. SDK-manager NDK repair was
attempted with Android Studio's JDK; no automatic license acceptance or SDK
deletion was performed. A repair is not complete until source.properties exists
and the debug build succeeds.

## Incomplete / next module

At this historical checkpoint, reliable manual acquisition still needed
Drift/SQLite storage, persistence and
migration tests, edit/delete paths and complete provenance. Consent/account
gates are not present in this local development prototype; use synthetic test
entries only. Phase 0 exit gate is not claimed. Then proceed sequentially to
Phase 1 backend/auth/profile/sync with relevant privacy safeguards from the
start. No excluded MVP integrations were added.

## External dependencies

Official university API authorisation and credentials remain unverified. Manual
entry is the baseline path while that access is unavailable. Google OAuth
client IDs, a valid student test identity, PostgreSQL and Gemini configuration
are required for later integration verification. Final privacy/legal/operator
and backup-retention policies, SDK licenses, device testing and release signing
must be resolved before production release. No legal-compliance claim is made.

---

# Phase 1 & 1.5 Completion Addendum

### Implemented & Verified
1. **Account Deletion (Phase 1 / Right to Erasure):**
   - Fastify Backend: `DELETE /api/v1/account` route and repository method with strict confirmation payload (`{"confirm": "DELETE_MY_ACCOUNT"}`) and transaction advisory lock (`pg_advisory_xact_lock(hashtext('academic:' || userId))`). Hard-deletes academic profiles, consent records, sessions, and user records.
   - Flutter App: `deleteAccount` API client method in `AuthApi` / `SessionController`. Interactive confirmation modal on `ProfileScreen`.
2. **Cloud Academic Consent & Outbox Synchronization (Phase 1.5):**
   - Drift schema updated with `LocalSyncOutbox` table and migration to version 3.
   - Flutter `ProfileSyncController`: manages local transactional outbox, server notice retrieval (`GET /api/v1/privacy/notice`), consent granting/withdrawal (`GET/POST /api/v1/privacy/consent`), and profile sync with conflict detection (`POST /api/v1/sync/profile`).
   - ProfileScreen shows Cloud privacy notice, terms dialog, and data processing terms.
3. **Automated Verification:**
   - Server: All 30 tests pass (`npm run check`, `npm test`).
   - Flutter: All 48 existing tests pass with 0 analyze warnings.

---

# Phase 3 Campus Sārathi AI Assistant Completion Addendum

### Architecture & Capabilities
1. **Backend AI Module (`server/src/modules/ai/`):**
   - `academic_calculator.ts`: Deterministic calculation of attendance margin, safe-to-skip status, consecutive classes required to restore minimum percentage, urgent vs. upcoming assignment triage, and today's timetable filtering.
   - `service.ts`: `AiService` enforcing prompt injection protection, bounded output, action proposal generation, and student rating feedback.
   - `routes.ts`: `POST /api/v1/ai/chat`, `POST /api/v1/ai/actions/:id/confirm`, `POST /api/v1/ai/feedback`.
2. **Flutter AI Companion (`app/lib/features/assistant/`):**
   - `LocalAssistantEngine`: Deterministic on-device reasoning engine matching server calculations for offline-first resilience.
   - `HttpAssistantApi`: REST client communicating with Fastify backend.
   - `AssistantController`: Live context builder from `AcademicStore`, online/offline hybrid dispatch, action confirmation and store mutations (study block scheduling & assignment creation), and feedback rating.
   - `AssistantScreen`: Rich UI featuring status banner (Cloud AI connected vs On-Device mode), quick suggestion chips, message bubbles with citations/references, interactive Action Proposal cards with Confirm/Dismiss buttons, and thumbs-up/down feedback.
3. **Automated Verification:**
   - Flutter: 61/61 tests pass (`flutter analyze` clean, 0 warnings).
   - Backend: 30/30 tests pass (`npm run check` clean, 0 errors).

---

# Phase 2 Academic Cloud Modules & Mobile Sync Completion Addendum

### Implemented & Verified
1. **Backend Academic Cloud Modules (`server/src/modules/academic/`):**
   - **Prisma Schema & PostgreSQL Migration:** Migration `20261023000100_academic_cloud_modules` adding `subjects`, `courses`, `class_schedules`, `attendance_records`, `assignment_records`, `announcement_records`, and `academic_sync_receipts` with strict CHECK constraints, foreign key cascades, and revision tracking.
   - **Academic Service & Routes:** CRUD and bulk sync endpoints with strict Zod validation schemas, advisory lifecycle locks, owner isolation (no client user IDs), optimistic revision checks (409 REVISION_CONFLICT), and academic consent gates.
   - **Bulk Sync Push (`POST /api/v1/sync/academic`):** Idempotent transaction processing with SHA-256 payload hashing and receipt caching.
2. **Mobile Cloud Synchronization & Academic UI (`app/lib/features/academic/`):**
   - **Academic HTTP Client (`HttpAcademicApi`):** Typed API client communicating with backend endpoints and mapping HTTP error codes into domain failures.
   - **Sync Coordinator (`AcademicSyncCoordinator`):** Manages local outbox state, checks cloud consent, bundles academic records for sync push, and fetches official university announcements.
   - **Expanded Academic Screen:** Material 3 tabbed interface upgraded to 4 tabs (`Assignments`, `Timetable`, `Attendance`, and `Announcements`) with responsive layouts, scope badges, and empty states.
3. **AI Assistant Live Context Hydration:**
   - Connected `AiService` with `AcademicService` to automatically fetch live student timetable, attendance, and assignments when client context is omitted.
4. **Automated Verification:**
   - **Flutter Test Suite:** **67/67 tests passing**, `flutter analyze` 0 issues.
   - **Fastify Backend Suite:** **35/35 tests passing**, `npm run check` 0 errors.
   - **Total Verification:** 102 passing automated tests across frontend and backend.

