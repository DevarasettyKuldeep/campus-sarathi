---
name: mobile-app-delivery
description: "Implement and verify a mobile application incrementally from its product brief or existing codebase, including backend integration and supported release builds. Use for end-to-end mobile app delivery, completing a partially built app, or a requested launch-readiness audit; not for conceptual questions or isolated small fixes."
---

# Mobile App Delivery

Deliver working, maintainable mobile software with evidence for completed user
journeys. Preserve the project's product requirements, chosen stack and phase
order. This workflow does not authorise publication, production changes,
messages to others, new paid resources or license acceptance.

## Establish the baseline

Read the complete authoritative brief and applicable repository instructions.
Inspect source, manifests, configuration, navigation, state/persistence,
authentication, backend contracts, database migrations, tests and existing
documentation. Keep existing user changes and working behaviour.

Identify what is implemented, partial, missing and broken using current files
and actual checks. Treat earlier status reports as leads, not proof. For a new
app, derive the architecture from the brief rather than imposing a preferred
framework. Separate settled choices from unresolved details and release
decisions. Make routine choices explicitly; ask only when missing information
materially affects scope or cannot be safely inferred.

Create a practical checklist with requirements, module order, acceptance
criteria, current evidence and blockers. Document repository boundaries,
database ownership/constraints, API validation/error/retry contracts and screen
architecture to the extent needed for the next modules. Do not generate every
future feature merely because it appears in the long-term plan.

## Implement vertical modules

Follow the project's phases. Complete one useful module through UI, state,
persistence, authorised backend operations and verification before claiming it
finished. Keep a runnable app throughout the work and rerun relevant checks
after changes. Avoid stopping at recommendations when implementation is
authorised and feasible.

For each required journey, trace the user's action through navigation,
validation, business logic, storage/network and visible outcome. Buttons and
forms must perform their intended action. Include loading, empty, error,
retry, cancellation and duplicate-tap behaviour where relevant. A displayed
success must reflect a committed operation, not merely a button press.

Use real services when configured. If external access is unavailable, implement
the adapter, configuration validation and failure path where possible. Label
test fixtures and mock integrations clearly; do not silently substitute them
for production behaviour or count fixture tests as live integration evidence.
An unavailable feature should communicate its actual state without pretending
to execute it.

Refactor where required for correctness and maintainability. Separate UI,
business logic, data access and provider-specific code without introducing
unneeded frameworks or infrastructure. Preserve existing migrations, lockfiles
and platform configuration. Keep decisions and phase status current.

## Preserve security and data lifecycle

Enforce identity, ownership and permissions at the backend for every protected
operation, including sync, jobs and AI tools. Never treat a client-supplied
student/user identifier as permission. Keep secrets out of clients and logs;
use server configuration and platform-appropriate protected token storage.

Where offline support is required, commit local edits durably and define
retry/idempotency, conflicts, source precedence and reconnect behaviour.
Pending operations must remain account-scoped; logout, revoked consent or
deletion must not let them run as another user or resurrect deleted data.
Do not describe an in-memory repository as offline persistence.

Implement relevant notice/consent, retention, withdrawal and deletion paths.
Distinguish app-controlled deletion from provider/backup retention. Do not claim
legal compliance from a consent checkbox or promise provider-side deletion
without verified capabilities. Apply the brief's actual AI behaviour, context,
calculation and action-confirmation rules independently of model prompts.

## Verify the product, not only the compiler

Read [verification-and-release.md](references/verification-and-release.md) when
planning module acceptance tests, investigating a failed journey or preparing
release artifacts. Choose tests proportional to actual behaviour and risk.
Use the available framework's build, analysis, test and emulator/device tools.
Fix observed failures and rerun the affected checks. Tests that only repeat
implementation wording are not evidence of functional correctness.

Review the actual mobile UI: keyboard and scrolling, safe areas, small/large
screens, text scaling, accessibility, back navigation and state restoration.
Use consistent typography, spacing, colour, forms and reusable components.
Avoid excessive decoration; optimise startup, scrolling, requests and resource
cleanup based on measured or observed problems.

After each phase report what is implemented, the checks actually executed and
their results, what remains incomplete, and blockers. Keep these distinctions:
source implemented / unit-tested / integrated / device-verified / release-ready.
A narrow test must not support a wider claim.

## Handle external blockers promptly

Tell the user immediately when manual setup, software installation, credential
configuration, license review or platform access is necessary. Give the exact
component/version, why it is needed, and concrete steps; never ask them to
paste secret values into chat. Continue independent work while waiting.

Differentiate a sandbox boundary from a broken installation. Use the normal
approval mechanism for required access rather than broad ACL changes or
permission workarounds. Prefer repairing the specific dependency over
rewriting the product to avoid it.

Track a running command by its live session/process handle. Observation
timeouts do not prove failure. Inspect existing state before starting another
installer/build. For repeated failures without new evidence, stop repeating
the same command, diagnose or document the external blocker, and continue
unaffected work. Stop only a process identified as belonging to this task.

## Release and handoff

Audit against the original requirements, not the subset currently implemented.
Generate supported release artifacts only after relevant checks pass. Keep
debug builds, signed release builds, device verification and store submission
distinct. Obtain required authority before external publication or production
mutation; skill invocation alone grants none.

Provide a concise handoff covering completed features, key UI/technical
changes, executed tests and limitations, platform build results/artifacts,
remaining external blockers, and exact run/configuration/deployment commands.
Keep incomplete requirements visible. Do not call the app release-ready while
required journeys, security gates or platform checks remain unverified.
