import 'package:flutter/material.dart';
import '../../repositories/academic_store.dart';
import 'student_profile.dart';

class ProfileEditor extends StatefulWidget {
  const ProfileEditor({super.key, required this.store});
  final AcademicStore store;
  @override
  State<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<ProfileEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _programme;
  late final TextEditingController _semester;
  late final TextEditingController _start;
  late final TextEditingController _end;
  bool _saving = false;
  bool _dirty = false;
  bool _allowExit = false;
  bool _confirming = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = widget.store.profile;
    _programme = TextEditingController(text: profile?.programme ?? '');
    _semester = TextEditingController(
      text: profile?.semesterNumber.toString() ?? '',
    );
    _start = TextEditingController(text: profile?.semesterStart ?? '');
    _end = TextEditingController(text: profile?.semesterEnd ?? '');
  }

  @override
  void dispose() {
    for (final field in [_programme, _semester, _start, _end]) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _exit() async {
    if (_saving || _confirming) return;
    if (_dirty) {
      _confirming = true;
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard profile changes?'),
          content: const Text(
            'Your unsaved changes will be lost. Your saved profile is unchanged.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep editing'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard changes'),
            ),
          ],
        ),
      );
      _confirming = false;
      if (discard != true || !mounted) return;
    }
    if (!mounted) return;
    setState(() => _allowExit = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context);
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.store.saveProfile(
        StudentProfile(
          programme: _programme.text.trim(),
          semesterNumber: int.parse(_semester.text.trim()),
          semesterStart: _start.text.trim(),
          semesterEnd: _end.text.trim(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      if (!mounted) return;
      setState(() => _allowExit = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not save your profile. Your draft is still here. Please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowExit || (!_dirty && !_saving),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _exit();
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Semester profile'),
        leading: BackButton(onPressed: _exit),
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          onChanged: () {
            if (!_dirty) setState(() => _dirty = true);
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Student-entered • Saved on this device only. No cloud upload or university verification.',
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _programme,
                  enabled: !_saving,
                  maxLength: 200,
                  decoration: const InputDecoration(labelText: 'Programme'),
                  validator: StudentProfile.programmeError,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _semester,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Semester number',
                  ),
                  validator: (text) {
                    final number = int.tryParse(text?.trim() ?? '');
                    return number == null || number < 1 || number > 30
                        ? 'Enter a whole number from 1 to 30.'
                        : null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _start,
                  enabled: !_saving,
                  keyboardType: TextInputType.datetime,
                  decoration: const InputDecoration(
                    labelText: 'Semester start',
                    hintText: 'YYYY-MM-DD',
                  ),
                  validator: (text) => StudentProfile.dayError(text?.trim()),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _end,
                  enabled: !_saving,
                  keyboardType: TextInputType.datetime,
                  decoration: const InputDecoration(
                    labelText: 'Semester end',
                    hintText: 'YYYY-MM-DD',
                  ),
                  validator: (text) {
                    final error = StudentProfile.dayError(text?.trim());
                    if (error != null) return error;
                    return StudentProfile.dayError(_start.text.trim()) ==
                                null &&
                            text!.trim().compareTo(_start.text.trim()) < 0
                        ? 'End date must not be before the start.'
                        : null;
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Campus timezone: Asia/Kolkata. Enter your actual semester dates; no university calendar is assumed.',
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Save profile on device'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
