# Google sign-in and session setup

Status: server adapter/routes and configured Flutter shell implemented and
fixture-tested. Live Google
identity verification, real PostgreSQL rotation and Android SDK sign-in remain
unverified. No fixture verifier or test repository is used in production.

## Manual configuration required

1. Choose the project's Google Cloud project and configure its OAuth consent
   screen/test users for the intended deployment stage. Request only identity
   scopes (openid, email, profile); Gmail/Calendar/Tasks are excluded.
2. Create a Web OAuth client ID for the backend/server audience. Put it in
   server/.env as GOOGLE_CLIENT_IDS. Comma-separated audiences are supported
   only for deliberately registered app clients; never accept an audience sent
   by a request. A client secret is not needed for ID-token verification.
3. For native sign-in, register an Android OAuth client with development package
   edu.amrita.campussarathi.campus_sarathi and its actual signing fingerprint.
   Confirm the final production ID/signing identity before release registration.
   Obtain the development fingerprint with the Android Gradle signingReport
   task after the Android toolchain works; do not invent or reuse a fingerprint.
4. Set DATABASE_URL to the development PostgreSQL database and migrate it.
   Configure TEST_DATABASE_URL separately for the real DB tests.
5. Generate a server-only signing key of at least 32 random bytes, base64url
   encoded, and store it locally as AUTH_SIGNING_KEY or in deployment secrets.
   Do not paste it into chat or include it in the Flutter app. Rotation of this
   key invalidates existing access tokens; a key-rotation rollout is a release
   operational concern.

There is currently no configured Google client, signing key or database in this
workspace. Without them the real auth endpoints return AUTH_NOT_CONFIGURED,
not simulated login. Partially supplied auth configuration fails at startup
and names only the missing/invalid environment fields.

## Domain verification decision

The Google adapter validates the ID-token signature/issuer/audience/expiry
using the official google-auth-library, then requires verified email, exact
cb.students.amrita.edu email domain, and matching signed hd Workspace claim.
Google warns that email suffix alone does not establish organisation membership;
email_verified on a non-Workspace account can outlive ownership of that email.
See [Google's verification guidance](https://developers.google.com/identity/gsi/web/guides/verify-google-id-token).

The university's actual Google Workspace membership/domain claim is not yet
verified. Test with an eligible real student identity before enabling public
sign-in. If the university does not issue Google-managed student accounts,
this is an authentication feasibility blocker requiring an approved solution,
not a reason to bypass identity checks or silently change the selected provider.

## Implemented server contracts

- POST /api/v1/auth/google: strict body {idToken}; returns basic account and
  application access/refresh tokens. Identity key is Google's subject. No
  client-supplied email or userId is accepted or used to grant access.
- POST /api/v1/auth/refresh: strict body {refreshToken}; single-use rotation.
- POST /api/v1/auth/logout: Bearer access token; revoke its entire token family.
- GET /api/v1/users/me: Bearer access token; basic account only, no academic
  profile before the academic consent/service module.

Access tokens: HS256, pinned issuer/audience, 15-minute lifetime capped by
session expiry. Each protected call checks the server session owner, revocation
and expiry in PostgreSQL. Refresh tokens: random 256-bit opaque values, SHA-256
digests in storage, 30-day absolute family lifetime. Refresh/logout serialize by
token-family transaction lock. Reuse commits family revocation before returning
401; it must not roll back that revocation by throwing inside the transaction.

Clients must serialize refreshes and must not automatically retry an old
refresh token after an ambiguous response. A replay signs out the family.
Expired access tokens may refresh while the refresh session remains active.
Keep raw credentials/tokens out of logs. The connected Flutter module uses
FlutterSecureStorage; its real Android protected-storage behaviour still needs
device testing. Set API_BASE_URL and GOOGLE_SERVER_CLIENT_ID together in the
Flutter build as documented in app/README.md. The device needs a trusted HTTPS
API; its debug guest workspace is not an authenticated fallback in release.

This is a native-client JSON/Bearer API, not a cookie-based web OAuth callback.
Future browser OAuth/cookie flows require their own CSRF/state design.

## Verification boundaries

Unit tests use explicitly named TestRepository and a local RSA certificate
fixture. Google's actual cryptographic verifier runs against that test key,
but no Google server or real student account is contacted. PostgreSQL tests
for concurrent rotation/replay/logout require TEST_DATABASE_URL and are skipped
when unavailable. Do not describe those unit tests as live sign-in, database
isolation, secure Flutter token storage or complete Phase 1 verification.
