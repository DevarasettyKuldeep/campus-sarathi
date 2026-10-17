# Campus Sārathi

Android-first academic companion for Amrita Coimbatore.

- Product authority: [plan.txt](plan.txt).
- Phases and unspecified decisions: [implementation plan](docs/IMPLEMENTATION_PLAN.md).
- Repository and screens: [architecture](docs/ARCHITECTURE.md).
- Relational/ownership design: [data model](docs/DATA_MODEL.md).
- Versioned contracts: [API specification](docs/API_SPEC.md).
- Source/access investigation: [Phase 0](docs/PHASE_0_DATA_SOURCES.md).
- Assistant acceptance gates: [AI behaviour](docs/AI_BEHAVIOUR.md).
- Current functionality: [status](app/IMPLEMENTATION_STATUS.md).
- Flutter run commands: [app README](app/README.md).
- Backend run commands: [API README](server/README.md).

Architecture documents describe the target, not features already delivered.
Manual capture, local consent/erasure and actual SQLite restart behaviour are
verified by automated tests. The Fastify foundation and server auth module pass
TypeScript checks, fixture/HTTP tests and compilation. Live Google sign-in,
Android device/build checks,
PostgreSQL, authenticated sync and the overall MVP remain incomplete.
