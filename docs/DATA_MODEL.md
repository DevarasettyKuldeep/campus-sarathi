# Database design contract

PostgreSQL + Prisma is mandatory for the backend; Drift/SQLite is implemented
on the device. Initial users/profile/session/consent schema and SQL migrations
exist under server/prisma and pass Prisma validation. Execution against real
PostgreSQL remains pending configuration. Other rows below are target design,
not existing tables. Add migrations per module rather than all future tables.

All personal tables include `user_id` and ownership-scoped indexes. Child
references use composite foreign keys `(user_id, parent_id)` so application
bugs cannot relate two students' rows. UUID primary keys, UTC `created_at` and
`updated_at`, integer server revision, and source metadata on academic records.
Enforce immutable ownership; it cannot be patched by a client.

| Table | Essential columns and constraints |
|---|---|
| users | id, google_sub UNIQUE, verified email UNIQUE, display_name, created_at; exact eligible domain enforced during identity verification |
| academic_profiles | user_id PK/FK, programme, semester_number, semester_start/end, timezone; end >= start |
| sessions | id, user_id, refresh_hash UNIQUE, family_id, expires_at, revoked_at; cascade deletion |
| subjects | id, user_id, code, name; UNIQUE(user_id,code); UNIQUE(user_id,id) for scoped child FKs |
| courses | id, user_id, subject_id, semester label, credits nullable, attendance_threshold nullable; UNIQUE(user_id,subject_id,semester); threshold >0 and <=100 |
| timetable | id, user_id, course_id, weekday 1..7, start/end minute 0..1439, room, valid_from/to; end > start; source, source_updated_at, recorded_at |
| attendance | id, user_id, course_id, attended, conducted, observed_at; 0 <= attended <= conducted; UNIQUE(user_id,course_id,source); zero is unknown percentage |
| assignments | id, user_id, course_id, title, notes, due_at, status, estimated_minutes nullable, importance, progress 0..100; index(user_id,status,due_at) |
| announcements | id, scope, origin URL, published_at, fetched_at, title/body; only a verified importer writes official announcements; initial importer unavailable |
| consent_records | id, user_id, purpose, notice_version, granted, event_at; append consent events, derive effective state; delete with account |
| settings | user_id, preferred hours/session length, goals, response preferences; review/update/delete controls |
| sync_operations | user_id, operation_id, payload_digest, result, applied_at; UNIQUE(user_id,operation_id); no raw payloads in logs |
| change_log | monotonically increasing sequence, user_id, entity/type/id, revision, deletion marker; owner-scoped delta pull, bounded retention and reset protocol |
| chat_sessions/messages | owner + session composite reference; role enum, content, timestamps; private retention and clear-history |
| study_plans/ai_memories/feedback | introduced Phase 3; scoped, editable/deletable, consent-gated |

Academic provenance fields: source=`student` or server-controlled official
adapter identifier; `recorded_at` is when entered; `source_updated_at`/observed
time describes information freshness. Student edits never upgrade provenance.
Official and manual attendance can coexist; selected official snapshot takes
precedence without silently deleting the student's draft.

Database SQL CHECK constraints complement Zod and Dart validation. Count bounds,
date ordering, unique keys and ownership constraints must be verified against real
PostgreSQL, not only mocked Prisma calls. RLS follows stable schema/access
patterns as an independent layer with transaction-local user context; pooled
connections must not leak context.

Deletion invalidates sessions and academic processing first, then removes all
owned active rows and local caches. Sync tombstones expire according to a
documented cursor horizon; stale clients receive reset-required and rehydrate
instead of resurrecting deleted rows. Backup expiry/provider retention remain
release policy decisions and must not be described as immediate deletion.

## Implemented profile boundary

Profile dates are YYYY-MM-DD calendar days (2000–2100), not timezone-shifted
instants. Semester is 1–30, programme is trimmed 1–200 characters, timezone
Asia/Kolkata. Server profile revision starts at 1; expectedRevision 0 creates.
The second SQL migration adds bounds/control-character checks without rewriting
the original migration. It remains unexecuted until PostgreSQL is configured.

Consent uses the latest per-user ACADEMIC_PROCESSING event by BigInt sequence,
not timestamp ordering. A grant must accept server-academic-dev-1 and match
expectedSequence (null before the first event). Withdrawal/newer consent makes
old grants conflict. User lifecycle locks serialize profile and consent work;
account deletion must use the same academic:<userId> lock. Consent rechecks and
profile CAS occur within one transaction. A changed notice invalidates a grant.

Drift schema v2 adds local_academic_profiles, a single row in each isolated
account/server file (or separate guest file). Local-academic-3 covers its
processing; no cloud grant or sync is inferred. Tested v1 upgrade preserves
old assignments but does not expose them until renewed local consent.

