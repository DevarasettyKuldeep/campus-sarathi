# Campus Sārathi implementation plan

Baseline: `plan.txt`, sections 1–27. Recorded 2026-10-17. This document makes
implementation choices within that baseline; it does not replace the brief.

## Initial audit

The workspace contained an unverified Flutter source prototype, not a complete
application. It has four tabs, transient academic lists, and a rule-based reply
that ignores the question. There was no backend, database, authentication,
consent gate, persistent offline storage, sync, or Android project. The earlier
implementation-status checklist overstated completion. Existing source will be
improved incrementally rather than treated as production functionality.

Android platform files and dependency resolution are now generated. Flutter
requires approved access to its SDK cache outside this workspace. No AGENTS.md
was found in the project. No seeded student data will be added.

## Unspecified details and decisions

| Detail | Implementation decision / dependency |
|---|---|
| Official APIs and permission | Unverified. No scraping, university password collection, or unofficial connectors. Use student-entered records until a documented authorised integration exists. |
| Academic calendar and curriculum | Student supplies programme, semester dates, subjects and class schedule. Do not seed invented university curriculum. |
| Course versus subject | Course is the student's semester-specific offering; subject is the curricular identity/code. Both are student-owned initially. |
| Attendance policy | Configurable per course. No official minimum inferred from the prototype's 75%. Zero conducted classes means unknown percentage. |
| Attendance precision | Store integer attended/conducted teaching units; display without rounding away risk. Period-weighted institutional rules need confirmation before official forecasting. |
| IDs and clocks | UUID record/operation IDs. UTC instants for server timestamps/deadlines; Asia/Kolkata for initial academic wall-clock schedules. Server revisions arbitrate sync, not device timestamps. |
| Timetable exceptions | Weekly sessions bounded by semester dates; cancelled/rescheduled occurrence exceptions in Phase 2. No overnight sessions initially. |
| Authentication | Google native sign-in; server validates signature, issuer, audience, expiry, verified email, exact domain and signed Workspace hd claim per Google guidance. Google subject is identity key. Actual student Workspace membership needs live verification; client domain hints grant no access. |
| App sessions | Short-lived access token (15 minutes), rotating opaque refresh token (30 days), hashed server storage; token-family reuse revokes sessions. Defaults subject to security testing. |
| Android ID | Generated development ID `edu.amrita.campussarathi.campus_sarathi`; branding must not imply university endorsement. Final public ID/signing identity must be confirmed before OAuth/release registration. |
| Consent | Versioned academic-processing consent required before records are collected, including locally. Gemini consent separate and optional. Withdrawal stops relevant processing and jobs immediately. |
| Underage users | Age eligibility/guardian-consent handling and applicable law require review before public onboarding. Do not silently assume all university students are adults. |
| Storage security | Per-account SQLite/Drift database; Android backup disabled for personal caches; secure OS token storage. Encryption/key lifecycle assessed in Phase 1.5. No tokens in SQLite/plain preferences. |
| Sync conflicts | Revision-based optimistic concurrency. Return conflict with current revision and preserve local draft for explicit resolution. Official records reject student writes. |
| Deletion | Reauthentication + explicit confirmation; revoke sessions, cascade active personal records, clear local DB/queue/tokens. Keep only non-identifying deletion job outcomes. Provider/backup retention must be documented accurately. |
| Logging/retention | Never log request bodies, tokens, emails or AI text. Default application chat retention 30 days, user clear-history control; backup expiry and operator/legal contacts remain release decisions. |
| Exams and available time | Upcoming exam dates and explicit study availability belong to academic planning (Phase 3); a timetable gap alone is not assumed free time. |
| AI configuration | Server-only Gemini credentials/model configuration. Confirm provider terms, quotas and model before live testing; no OpenAI/provider substitution. |
| Hosting / operations | Railway or Render remains undecided. Local PostgreSQL first; no external resources provisioned during Phase 0. |
| Release targets | Android first. Debug build/device verification precedes signing, Play disclosures and release bundle. iOS is deferred by the baseline. |

## Sequential execution gates

| Phase | Ordered modules | Evidence required to pass |
|---|---|---|
| 0 — data validation | Public source investigation → source/validation contract → usable manual capture | Provenance and timestamps retained; invalid academic values rejected; form errors visible; records survive restart before claiming reliable collection; authorised path documented. |
| 1 — infrastructure | Fastify health/config → Prisma identity/profile → Google identity/session → Flutter onboarding/profile → Drift per-account cache → sync queue | Real PostgreSQL migrations; expired/wrong-domain/replayed credentials rejected; two students isolated; offline edits survive kill/restart; reconnect applies once and preserves conflicts. |
| 1.5 — privacy/security | Notice/consent enforcement → withdrawal → deletion → secure cache/token lifecycle → IDOR/RLS review | Consent version recorded; denied processing makes no provider call; revoked sessions fail; all active user rows/chats/local queues removed; backup/provider limitations disclosed; security tests pass. Minimum auth/consent safeguards are implemented with Phase 1, not postponed until this audit. |
| 2 — academic modules | Courses/subjects → timetable → attendance → assignments → available announcements | Each module separately passes CRUD, owner isolation, restart, conflict, validation, offline and small-screen tests before starting the next. Official data is read-only. |
| 3 — assistant | Read tools/calculations → Gemini adapter → context/reply validation → confirmed write actions → daily planning/preferences → scheduled in-app insights/feedback | Behaviour scenarios in AI_BEHAVIOUR.md pass; no unsupported academic claims or cross-user tools; missing/stale data acknowledged; provider/network failures honest. |
| 4 — validation | Student pilot → reliability fixes → retention/usefulness review | Real participant feedback and measured adoption/retention; 100 DAU milestone reported only from actual measurements. No feature expansion. |

For every module: define acceptance criteria → implement → lint/unit/integration
tests → run/build → inspect relevant UI → update status. Failed gates remain
open. A debug APK is not a signed release and a passing widget test is not a
device test.

## First module

Phase 0 manual academic capture validation: retain the existing input paths,
centralise domain validation, expose actionable field errors, label data as
student-entered, and remove the misleading chat simulation. Establish domain
and widget tests before adding persistence. Then complete reliable manual
capture with Drift and restart tests as the next module; Phase 0 stays open
until those pass.

See ARCHITECTURE.md, DATA_MODEL.md, API_SPEC.md, PHASE_0_DATA_SOURCES.md and
AI_BEHAVIOUR.md for contracts. These specify future work; they are not claims
that the backend, DB, sync or AI already exists.
