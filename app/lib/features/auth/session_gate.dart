import 'dart:async';
import 'package:flutter/material.dart';
import '../../repositories/academic_store.dart';
import '../../screens/local_consent_screen.dart';
import 'account_workspaces.dart';
import 'auth_models.dart';
import 'session_controller.dart';

typedef AccountHomeBuilder =
    Widget Function(
      BuildContext context,
      AcademicStore store,
      StudentAccount account,
      SessionController session,
    );

const identityNotice = '''Campus Sārathi sign-in

Continuing opens Google's student account sign-in. The app sends the returned Google ID token to the configured Campus Sārathi server for identity verification. The server stores your Google subject, verified student email, display name and application session records to identify and protect your account.

Your app session tokens are stored using protected storage on this device. Signing out removes local app access and cached academic records for this account. If offline, server session revocation may remain unconfirmed.

Academic entries remain on this device in the current development version. They are not uploaded or sent to Gemini. Academic processing requires a separate, unchecked consent choice after sign-in. Account deletion and a production privacy contact are still being implemented; this build is for development testing only.''';

class SessionGate extends StatefulWidget {
  const SessionGate({
    super.key,
    required this.controller,
    required this.workspaces,
    required this.homeBuilder,
  });
  final SessionController controller;
  final AccountWorkspaces workspaces;
  final AccountHomeBuilder homeBuilder;
  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> with WidgetsBindingObserver {
  String? _accountId;
  Future<AcademicStore>? _workspace;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_changed);
    unawaited(widget.controller.initialize());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    final id = widget.controller.account?.id;
    if (id != _accountId) {
      if (_accountId != null && mounted) {
        // Editors/dialogs pushed above the home route must not outlive their
        // account when revocation, logout or an account switch occurs.
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      _accountId = id;
      _workspace = id == null ? null : widget.workspaces.open(id);
    }
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.controller.validate());
    }
  }

  Future<void> _declineConsent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline academic processing?'),
        content: const Text(
          'You can sign out without consenting. Signing out erases this account’s local academic records and any previous local consent, including unsynced records. It does not delete your server account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep reviewing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out and erase local records'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await widget.controller.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.controller;
    if (session.phase == SessionPhase.restoring ||
        session.phase == SessionPhase.working) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }
    if (session.phase == SessionPhase.storageError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Protected storage')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(session.message ?? 'Could not open protected storage.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: session.busy ? null : session.initialize,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    final account = session.account;
    if (account == null) return _SignInScreen(session: session);
    return FutureBuilder<AcademicStore>(
      key: ValueKey(account.id),
      future: _workspace,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Account records')),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'Could not open your local records. Nothing has been erased.',
                  ),
                  FilledButton(
                    onPressed: () => setState(
                      () => _workspace = widget.workspaces.open(account.id),
                    ),
                    child: const Text('Retry'),
                  ),
                  TextButton(
                    onPressed: session.signOut,
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          );
        }
        final store = snapshot.data;
        if (store == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return AnimatedBuilder(
          animation: store,
          builder: (context, _) => store.hasConsent
              ? widget.homeBuilder(context, store, account, session)
              : LocalConsentScreen(
                  key: ValueKey(account.id),
                  store: store,
                  onDecline: _declineConsent,
                ),
        );
      },
    );
  }
}

class _SignInScreen extends StatelessWidget {
  const _SignInScreen({required this.session});
  final SessionController session;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Campus Sārathi')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.school_outlined, size: 48),
          const SizedBox(height: 24),
          Text(
            'Your semester, with a little more clarity.',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          const Text(
            'Use your university-managed student Google account to open your own academic workspace.',
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Sign-in privacy notice'),
                content: const SingleChildScrollView(
                  child: Text(identityNotice),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
            child: const Text('How sign-in data is used'),
          ),
          if (session.message != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                session.message!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          FilledButton.icon(
            onPressed: session.busy ? null : session.signIn,
            icon: const Icon(Icons.login),
            label: const Text('Continue with student Google account'),
          ),
        ],
      ),
    ),
  );
}
