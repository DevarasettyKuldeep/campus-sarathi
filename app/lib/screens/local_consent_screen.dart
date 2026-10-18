import 'package:flutter/material.dart';

import '../repositories/academic_store.dart';

const localPrivacyNotice = '''Campus Sārathi — local academic records
Notice version: local-academic-3

This development version stores the programme, semester number and dates, assignments, timetable and attendance you enter, plus the time you accepted this notice, in this app's SQLite database on this device. The purpose is to help you organise your academic responsibilities. Campus dates use Asia/Kolkata.

When sign-in is configured, your Google identity and app session are verified by the Campus Sārathi server. Academic entries in this development version still remain on this device, separately for each signed-in account. Without configured sign-in, the local development workspace is separate and is never automatically imported into an account. Your academic records are not sent to Gemini or the university. Information you enter is student-managed, not university-verified.

Records remain until you erase them using Profile → Erase local records. That control also withdraws this local-processing consent and returns you to this screen. Android app backup is disabled. This action applies to the app's active local database; it does not erase copies you made outside the app.

You can decline by leaving this screen without enabling storage. No academic records can be entered until you consent. Review this notice again from Profile at any time.

Cloud academic processing, server account deletion and a production privacy contact require further implementation and notice before public release. Use this build for development testing only.''';

Future<void> showLocalPrivacyNotice(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Local privacy notice'),
    content: const SingleChildScrollView(child: Text(localPrivacyNotice)),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
    ],
  ),
);

const serverAcademicNoticeText = '''Campus Sārathi development academic profile processing. If you explicitly consent, this server stores your programme, semester number, semester dates and timezone to organise your academic information. These records are student-entered, not university-verified. Profile data is not sent to Gemini or the university. Google identity/session processing is separate. Local-only academic consent does not authorise an upload. Your latest server consent choice and its notice version/time are retained as evidence. Withdrawal immediately blocks further profile reads and writes; it does not itself erase stored records. Profile and consent records remain in the configured development PostgreSQL database until account deletion or development data cleanup. Server account deletion, backup expiry, operator privacy contact and production notices are not ready; do not use this build for public onboarding. No claim of legal compliance or provider-controlled deletion is made.''';

Future<void> showCloudPrivacyNotice(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Cloud academic privacy notice'),
    content: const SingleChildScrollView(child: Text(serverAcademicNoticeText)),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
    ],
  ),
);

class LocalConsentScreen extends StatefulWidget {
  const LocalConsentScreen({super.key, required this.store, this.onDecline});
  final AcademicStore store;
  final VoidCallback? onDecline;
  @override
  State<LocalConsentScreen> createState() => _LocalConsentScreenState();
}

class _LocalConsentScreenState extends State<LocalConsentScreen> {
  bool _accepted = false;
  bool _saving = false;
  String? _error;

  Future<void> _continue() async {
    if (!_accepted || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.store.grantLocalConsent();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not save your choice. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Campus Sārathi')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.menu_book_outlined, size: 48),
          const SizedBox(height: 24),
          Text(
            'Your academic day, on your device.',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const Text(
            'Save your semester profile, timetable, attendance and assignments on this device. Cloud academic sync and AI are not connected yet.',
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => showLocalPrivacyNotice(context),
            child: const Text('Read the local privacy notice'),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _accepted,
            onChanged: _saving
                ? null
                : (value) => setState(() => _accepted = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'I consent to storing and processing my academic records on this device as described in the local privacy notice.',
            ),
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _accepted && !_saving ? _continue : null,
            child: Text(
              _saving ? 'Saving your choice…' : 'Continue with local records',
            ),
          ),
          if (widget.onDecline != null)
            TextButton(
              onPressed: _saving ? null : widget.onDecline,
              child: const Text('Decline and sign out'),
            ),
        ],
      ),
    ),
  );
}
