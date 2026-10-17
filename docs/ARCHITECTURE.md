# Repository and Flutter architecture

## Target layout (introduced as each module is built)

```text
plan.txt                         authoritative product baseline
docs/                            decisions, contracts, phase reports
app/
  android/                       native Android host
  lib/
    main.dart                    bootstrap only after screen extraction
    core/                        theme, configuration, errors, clock
    data/local/                  Drift tables, migrations, account DB lifecycle
    data/remote/                 API transport, auth refresh, DTO validation
    data/sync/                   transactional outbox, pull cursor, conflicts
    features/
      auth/                      sign-in, notice/consent, onboarding
      profile/                   programme/semester, preferences, privacy
      courses/                   subject and semester offerings
      timetable/                 recurring classes, occurrence exceptions
      attendance/                record entry, source, deterministic insights
      assignments/               CRUD, completion, deadlines
      announcements/             permitted read-only sources
      assistant/                 conversations, plans, action confirmation
    shared/                      accessible reusable widgets
  test/                          domain, persistence, widget tests
  integration_test/              authenticated/offline/device journeys
server/
  prisma/                        schema, checked-in SQL migrations
  src/
    app.ts                       Fastify factory (testable without listening)
    main.ts                      process lifecycle
    config/                      Zod environment validation
    plugins/                     auth, errors, rate limits, Prisma
    modules/<module>/            routes, schemas, service, repository
    providers/gemini/            provider adapter only
    jobs/                        node-cron and bounded job execution
  test/                          API + real PostgreSQL integration tests
```

Current prototype models/repository remain until replaced module by module.
Use Flutter ChangeNotifier/controllers initially; dependencies are injected
through constructors. Avoid a state framework until a concrete need emerges.
Widgets call controllers; controllers call repositories; only repositories
access SQLite/network. UI errors distinguish validation, auth, offline,
conflict and service unavailability.

## Screen/navigation contract

Current Phase 1 checkpoint: configured bootstrap → SessionGate → Google sign-in
and identity notice → account/server-specific AccountWorkspaces → unselected
local academic consent → existing main shell. Decline offers confirmed sign-out
without granting consent. Academic profile onboarding and sync remain pending.
Resume validates the session; logout/revocation removes pushed private routes
and erases only the active account's local records. Release builds without
configuration cannot open the separate debug guest workspace.

The following describes the full target flow, not completed functionality.

Bootstrap checks local session/account state → sign-in → privacy notice and
unselected consent → academic profile → main shell. No private data is rendered
before the relevant session/consent gate. Offline unlock permits previously
authorised local records only; server access still requires live authentication.

Shell destinations: Today, Academic, Assistant, Profile. Today shows next class,
pending work and evidence-based insights. Academic has courses/subjects,
timetable, attendance and assignments; each has list, detail and validated
editor, with delete confirmation and unsaved-change handling. Announcements
appear only when a legitimate source is available. Assistant has history,
conversation, action confirmation, adjustable plan and helpful/not-helpful
feedback. Profile includes semester, preferences/memory, notice/consent,
clear-history, logout and account deletion.

Use scrollable editor routes for keyboard/small-screen reliability; fields have
labels, limits and inline errors. Expose source, last update, offline status and
unsynced changes without technical provider implementation details. Support
text scaling, screen readers, system back, safe areas, 48dp touch targets and
Material light/dark themes as screens are completed.

## Offline transaction contract

Write local record + operation in one SQLite transaction. Operation includes
UUID, account ID, entity ID/type, action, base revision, schema version and
payload. Retry with bounded exponential backoff/jitter; trigger on resume and
successful connection as well as user retry. Connectivity signals alone do not
prove API reachability. Apply ack + pull cursor transactionally. Keep conflicts
as local drafts until resolved. Server idempotency key includes authenticated
account and operation ID; same ID with changed content is rejected.

Every local read/write is account-scoped. Logout hides and clears sensitive
cache per policy; deletion clears the outbox before allowing new account use.
Never replay one account's queue under another account's session. Expired auth
pauses sync. Server session/account checks prevent a deleted account's old
queue from recreating data.
