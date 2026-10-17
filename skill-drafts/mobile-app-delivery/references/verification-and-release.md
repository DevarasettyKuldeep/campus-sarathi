# Verification and release evidence

Use the product brief to select applicable checks. This is a decision guide,
not a requirement to add every test or platform to every application.

## Module acceptance evidence

| Area | Meaningful evidence |
|---|---|
| Navigation and input | Traverse the real route, enter valid/invalid data, observe field errors and final state; verify back/cancel and duplicate submissions. |
| Identity and access | Valid, expired and wrong-audience identities; two distinct users; forbidden object IDs; server rejects every unauthorised path. No client-only access check counts as protection. |
| Persistence | Commit data, destroy the store/process where supported, reopen the actual database, and verify values and IDs. Test migration/version behaviour and failure without silent data loss. |
| API/database | Verify actual request/response contracts and configured database constraints. Repository mocks alone cannot prove migrations, transactions or access rules. |
| Offline sync | Edit without network, restart, reconnect, retry the same operation, and verify one server-side effect. Test conflict preservation and account changes. |
| Privacy/deletion | Consent initially unselected; processing denied before grant/after withdrawal; confirmed deletion removes app-controlled active records, tokens and pending operations; reopening does not resurrect them. |
| AI | Missing/stale context, unsupported claims, inaccurate calculations, wrong-owner tools, provider timeout/quota, and consequential action confirmation. Validate against the project's behaviour specification, not fluent text alone. |
| Network/lifecycle | Slow, failed, malformed and interrupted requests; session expiry; background/resume; listeners/resources disposed; retries bounded and safe. |
| Mobile UI | Inspect target-size rendering with keyboard, safe areas, scrolling, text scaling and accessibility; exercise system back and permission denial/revocation where used. |
| Performance | Identify a practical symptom and compare relevant measurements, such as startup, frame timing, query count or memory. Avoid speculative complexity. |

For each check record the command/environment, expected behaviour, observed
result and untested boundaries. Do not report an unavailable emulator test as
passed because widget tests succeed. When no device is available, use narrower
checks and state the remaining device gate explicitly.

## Release audit

Before claiming platform readiness, check applicable items:

- Application name, icon, splash, package/bundle ID and version.
- Production endpoint/configuration validation and no bundled private secrets.
- Least-required permissions and accurate explanations/disclosures.
- Signing configuration and credential handling; no debug key labelled as
  production signing. Verify the actual artifact's variant and identity.
- Error reporting with sensitive data redacted; useful production error paths.
- Privacy notice/contact, consent and deletion behaviour consistent with the
  deployed system and provider/backup capabilities.
- Database migrations and supported upgrade paths; tested rollback/recovery
  approach where needed.
- Relevant analysis, automated suites and end-to-end journeys pass; no known
  critical crashes, broken routes, fake successes or unfinished required flows.
- Actual Android APK/AAB or supported iOS build generated and verified in the
  available environment. iOS signing/build verification may require macOS and
  account access; a cross-platform source tree does not establish it.
- Store-specific checks and manual disclosures assessed before claiming Play
  Store or App Store submission readiness.

An external blocker is an explicit outcome, not a fabricated success. Identify
the exact credential, infrastructure, software or human action needed, keep
unblocked work moving, and preserve the original acceptance criteria.
