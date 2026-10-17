# Flutter authentication client checkpoint

Implemented source under app/lib/features/auth:

- Official GoogleSignIn 7 adapter; returns an ID token for backend verification,
  with cancellation distinguished from failure. Client email/domain hints do
  not grant access. No Google ID token is persisted.
- HTTPS-only auth HTTP transport, pinned API base path, redirects disabled,
  bounded request/response duration and response size, validated DTOs, safe error
  messages and no automatic retries of token exchanges/refreshes.
- FlutterSecureStorage vault: one versioned JSON envelope for account + token
  pair, namespaced to the API server. No plaintext/SQLite token fallback.
- Session controller: restore/validate, sign-in, rotation, expiry, offline cached
  identity, logout and interrupted-erasure recovery. Persist a token-free
  checkpoint before sending a single-use refresh token. Ambiguous failure
  retains only cached account identity and requires sign-in for server access;
  restarting cannot replay the old token.
- Sign-out writes a denied-local-access marker before network/cache work. A
  failed erase remains denied and retries cleanup on restart. Remote revocation
  is reported unconfirmed if offline/expired, not shown as a server success.
- Canonical HTTPS/Google client configuration and SHA-256 server namespace;
  account/server-specific SQLite file factory with UUID/path validation.
- Android manifest adds normal INTERNET permission, forbids cleartext traffic,
  retains disabled backup, and respects secure-storage minimum SDK 23.

## Connected application shell

With valid auth configuration, the app now opens the sign-in screen, uses the
real Google SDK/HTTP/vault adapters, restores or validates its session, and
opens the verified account's SQLite workspace. Unchecked local consent follows
sign-in; identity notice and academic notice describe different processing.
Notice local-academic-3 requires renewed consent from earlier development
workspaces. Existing guest records are never silently imported.

The workspace manager serializes opens/erases/closes, waits for an active write,
and clears disposed in-memory records. Logout/revocation records denied local
access before erasure; account changes remove pushed editors/dialogs. Account
and FutureBuilder keys prevent the previous snapshot or consent from appearing
while another account's storage opens. Resume validates the session; cached
offline access is labelled and reconnect offers sign-in. Profile shows the
verified/cached identity and confirms that logout deletes unsynced local data.

Without configuration, debug builds retain the isolated local development
workspace. Release mode fails closed with a configuration message, not guest
access. No production fake provider is installed.

## Configuration and unfinished work

Set API_BASE_URL and GOOGLE_SERVER_CLIENT_ID together via dart defines.
API URL must be HTTPS and end in /api/v1. These are public client settings,
never server signing keys or OAuth client secrets. See app/README.md.

The local Node HTTP listener supports loopback checks, not live Android sign-in.
A trusted HTTPS development endpoint or approved deployed backend, real
PostgreSQL, registered Google audiences and eligible student identity are still
required. No public tunnel, deployment or paid resource was provisioned.

Offline academic profile and server academic consent/profile routes are now
implemented separately. Mobile cloud consent, profile transport/sync, server
deletion and broader privacy/security audit remain incomplete. Academic records currently stay on
the device; sign-in does not imply upload or synchronization.

## Verification boundaries

Flutter analysis is clean; all 42 tests pass. Seven shell tests exercise workspace
lifecycle, fail-closed release configuration, sign-in/consent/entry/logout,
consent decline/cancel, revoked-editor removal and slow-account-switch isolation. Widget identity/API/
vault fixtures are explicit, not live Google/backend evidence. Secure-storage
wrapper tests use its plugin mock, not Android Keystore.

Real file-backed SQLite tests verify account/server files, reopen, committed
writes during account switching, late-write rejection and targeted erasure.
These are database and widget checks, not a device backup/encryption audit.
Five profile tests also cover validated calendar dates, file-backed restart,
v1-to-v2 migration, failed save/retry and small-screen draft confirmation.
Unsaved profile editors cannot block route removal on session revocation.
Android build/device verification remains blocked by incomplete NDK
28.2.13676358 and no configured Android test device. No APK is verified.

