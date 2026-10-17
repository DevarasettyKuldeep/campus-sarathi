# Versioned API implementation specification

Base `/api/v1`, JSON over HTTPS in deployment. Implemented server routes:
GET `/health`, GET `/ready`, POST `/auth/google`, POST `/auth/refresh`,
POST `/auth/logout`, GET `/users/me` (basic account only), GET `/privacy/notice`,
GET/POST `/privacy/consent`, GET/PUT `/users/me/profile`. Auth remains
fixture-tested, not live-verified; unconfigured auth returns 503. Other rows
below are planned contracts. DB readiness probes require actual migrated tables.
Zod strict schemas reject unknown ownership/source fields. Max request size,
rate limits and bounded pagination apply. Every private route resolves identity
from server authentication, then checks active account and required consent.

Success: `{ "data": ..., "meta": { "requestId": "..." } }`.
Error: `{ "error": { "code": "VALIDATION_ERROR", "message": "...",
"fields": { "title": "Required" } }, "requestId": "..." }`.
No stacks, SQL, credentials or provider response internals in public errors.

| Method/path | Request / response and access |
|---|---|
| GET /health | liveness, no secrets; readiness separately verifies DB |
| POST /auth/google | `{idToken}` → access token + rotating refresh token; backend Google verification, exact domain, no client userId |
| POST /auth/refresh | `{refreshToken}` → rotated tokens; reuse revokes family |
| POST /auth/logout | revoke current verified session |
| GET /users/me | verified basic identity only; no academic data |
| GET/PUT /users/me/profile | own academic profile after current server consent; PUT complete fields + expectedRevision |
| GET /privacy/notice | current version and readable notice |
| POST /privacy/consent | `{purpose,noticeVersion,granted}`; record event; no academic processing before grant |
| GET /privacy/consent | own effective academic consent + latest event; paged history remains future work |
| DELETE /account | recent reauth + explicit confirmation; revoke access, hard-delete active records, report external cleanup status honestly |
| GET/POST /subjects, /courses | owner-scoped lists/create; code/title limits, semester reference |
| GET/PATCH/DELETE /subjects/:id, /courses/:id | owner scope; reject dangling-reference delete or require explicit cascade confirmation |
| GET/POST /timetable | week/day filters; courseId, weekday, startMinute, endMinute, room, validity dates |
| PATCH/DELETE /timetable/:id | revision required; student records only |
| GET/POST /attendance | courseId, attended, conducted, observedAt; counts constrained; student source only |
| PATCH/DELETE /attendance/:id | revision required; official snapshots cannot be client-mutated |
| GET/POST /assignments | filters status/course, cursor pagination; courseId,title,dueAt,estimatedMinutes,importance |
| GET/PATCH/DELETE /assignments/:id | allowed editable fields, expected revision |
| GET /announcements | explicitly authorised public/course scope only; unavailable source yields empty with source status, never invented announcements |
| POST /sync/push | <=50 operations; UUID, entityId/type, action, baseRevision,payload; each authorised and transactionally applied with idempotency receipt |
| GET /sync/pull?cursor=... | <=100 owner-scoped changes/tombstones, nextCursor,hasMore; retention-expired cursor requires full reset |
| POST /ai/chat | sessionId optional,message,clientMessageId; context-first server tools and Gemini adapter; returns validated answer with evidence references or honest unavailable error |
| POST /ai/actions/:id/confirm | action preview token scoped to user, expiry and record revision; confirmation cannot authorise official writes |
| GET/POST/PATCH /ai/plans | read, create, adjust own plans with explicit availability; implementation in Phase 3 |
| POST /ai/feedback | messageId and helpful/not_helpful; enforce message ownership |

Semantics: 400 invalid shape, 401 invalid/expired session, 403 eligible identity
without permission/consent or official write, 404 missing/non-owned resource
(avoid ID enumeration), 409 revision/idempotency conflict, 429 rate limit with
Retry-After, 503 provider/infrastructure unavailable. Lists return empty arrays,
never other users' records. PATCH requires expected revision; update matches
id+owner+revision atomically. All retries use UUID operation keys; same operation
and payload return saved result; changed payload under the same key conflicts.

Offline writes use the same validation and service as online CRUD. No separate
sync route may bypass ownership, consent, source permissions or invariants.
Server side changes emit owner-scoped change-log entries in the same transaction.

## Implemented development profile/consent contract

GET /privacy/notice returns {version,developmentOnly,text}. It is a development
notice, not a production compliance claim. Academic routes return 503
PRIVACY_NOT_READY in production until privacy/deletion readiness is resolved.

GET /privacy/consent returns {purpose:"ACADEMIC_PROCESSING",granted,event}.
Event is null or {sequence,noticeVersion,granted,eventAt}; sequence is a decimal
string, never a JS floating-point number. POST accepts exactly purpose,
noticeVersion, granted, expectedSequence (current sequence or null initially).
Current sequence is required for both grant and withdrawal. Old/ambiguous
requests are not automatically retried: refetch and ask the student again.
Grant requires the current notice; withdrawal does not require accepting a new
notice. Gemini consent is not enabled by this endpoint. Withdrawal blocks
profile reads/writes immediately after commit but is not hard deletion.

GET /users/me/profile returns null if no profile exists, or {programme,
semesterNumber,semesterStart,semesterEnd,timezone,revision,updatedAt}.
PUT requires the first five fields and expectedRevision (0 to create).
Dates must be real YYYY-MM-DD days in 2000–2100, end >= start; programme
1–200 trimmed characters; semester integer 1–30; timezone Asia/Kolkata.
Owner, source, updatedAt and revision cannot be supplied by the client.
Stale revision yields 409, preserving the newer row and the client's draft.
GET/PUT require academic consent; local-device consent is not sufficient.

These routes have policy tests with explicit repositories; real PostgreSQL
transaction/constraint integration remains skipped without TEST_DATABASE_URL.
The mobile profile currently stays local; its cloud consent/transport/outbox
module is not implemented. No automatic retries or fake upload success.

