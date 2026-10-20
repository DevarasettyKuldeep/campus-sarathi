import 'package:google_sign_in/google_sign_in.dart';
import 'auth_models.dart';

abstract interface class StudentIdentityProvider {
  Future<String?> authenticate();
  Future<void> signOut();
}

class GoogleStudentIdentity implements StudentIdentityProvider {
  GoogleStudentIdentity({required this.serverClientId});
  final String serverClientId;
  Future<void>? _initialization;
  Future<void> _initialize() =>
      _initialization ??= GoogleSignIn.instance.initialize(
        serverClientId: serverClientId,
        hostedDomain: 'cb.students.amrita.edu',
      );
  @override
  Future<String?> authenticate() async {
    try {
      await _initialize();
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw const AuthFailure(
          AuthFailureKind.unavailable,
          'Student sign-in is not available on this device.',
        );
      }
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthFailure(
          AuthFailureKind.unavailable,
          'Google did not return a sign-in token.',
        );
      }
      // Email/domain returned to this client is not an authorisation decision.
      return idToken;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      throw const AuthFailure(
        AuthFailureKind.unavailable,
        'Google sign-in could not start. Please retry.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    await _initialize();
    await GoogleSignIn.instance.signOut();
  }
}
