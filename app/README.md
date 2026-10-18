# Campus Sārathi Android app

Flutter/Dart academic companion for Amrita Coimbatore. Product authority:
../plan.txt. Implementation contracts: ../docs/IMPLEMENTATION_PLAN.md.

The current development build saves manually entered assignments, recurring
classes, attendance and semester profile to Drift/SQLite on this device. Records persist across
restart. A versioned local notice and explicit consent gate precede academic
entry. Profile offers local-data erasure and consent withdrawal.

Configured builds now connect Google sign-in to the server auth API, protected
session storage and an account-specific local workspace. Without configuration,
debug builds use the separate local development workspace; release builds show
a configuration error and do not bypass authentication. Cloud academic sync and
the live assistant are not implemented. No university verification or legal
compliance is claimed.

## Run and verify

From this directory with Flutter and the Android SDK installed:

```powershell
flutter pub get
dart run build_runner build
flutter analyze
flutter test
flutter build apk --debug
flutter devices
flutter run -d <android-device-id>
```

For configured sign-in, first follow ../docs/GOOGLE_AUTH_SETUP.md and set both
public client values (replace example values with your registered configuration):

```powershell
flutter run -d <android-device-id> --dart-define=API_BASE_URL=https://your-api.example/api/v1 --dart-define=GOOGLE_SERVER_CLIENT_ID=your-web-client.apps.googleusercontent.com
```

Use a trusted HTTPS API reachable from the Android device. Never include
AUTH_SIGNING_KEY, database credentials or OAuth client secrets in dart defines.
Sign-in does not import guest records or upload academic records. Logout
confirms removal of that account's unsynced local records; offline remote
session revocation is explicitly unconfirmed.

The generated Drift file is included; regenerate it after table changes.
Current schema version is 2; its tested upgrade adds the profile table without
losing v1 rows. Notice local-academic-3 requires renewed consent for profile
processing. New schema changes must include migrations and
upgrade tests before shipping. SQLite uses an app-support file and a background
isolate on Android. Android backup is disabled. Account/server storage boundaries are implemented and tested. Full local
encryption/key lifecycle and device verification remain Phase 1/1.5 work.

Connect a USB-debugging Android device or create an AVD through Android Studio.
Review SDK licenses with flutter doctor --android-licenses. Repair the incomplete
NDK 28.2.13676358 through SDK Manager before retrying Android builds. Never
describe debug signing as production signing.

See IMPLEMENTATION_STATUS.md and ../docs/PHASE_REPORT.md for exact verification
and remaining work.
