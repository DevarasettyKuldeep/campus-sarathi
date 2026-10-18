import 'package:flutter/material.dart';

import '../models/academic_models.dart';
import '../repositories/academic_store.dart';

enum ManualEntryType { assignment, timetable, attendance }

Future<void> showManualEditor(
  BuildContext context,
  AcademicStore store,
  ManualEntryType type,
) => Navigator.of(context).push<void>(
  MaterialPageRoute(
    builder: (_) => ManualEditor(store: store, type: type),
  ),
);

/// A real manual capture path. No official source or policy is inferred.
class ManualEditor extends StatefulWidget {
  const ManualEditor({super.key, required this.store, required this.type});
  final AcademicStore store;
  final ManualEntryType type;

  @override
  State<ManualEditor> createState() => _ManualEditorState();
}

class _ManualEditorState extends State<ManualEditor> {
  final _form = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _title = TextEditingController();
  final _room = TextEditingController();
  final _attended = TextEditingController();
  final _conducted = TextEditingController();
  final _minimum = TextEditingController();
  DateTime _due = DateTime.now().add(const Duration(days: 1));
  int _day = DateTime.now().weekday;
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 10, minute: 0);
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in [
      _subject,
      _title,
      _room,
      _attended,
      _conducted,
      _minimum,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? 'This field is required.'
      : value.trim().length > 200
      ? 'Use at most 200 characters.'
      : null;

  String? _count(String? value) {
    final count = int.tryParse(value?.trim() ?? '');
    return count == null || count < 0 || count > 100000
        ? 'Enter a whole number between 0 and 100000.'
        : null;
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _error = null);
    setState(() => _saving = true);
    try {
      switch (widget.type) {
        case ManualEntryType.assignment:
          await widget.store.addAssignment(
            title: _title.text,
            subject: _subject.text,
            dueDate: _due,
          );
        case ManualEntryType.timetable:
          if (_end.hour * 60 + _end.minute <=
              _start.hour * 60 + _start.minute) {
            setState(() => _error = 'End time must be after start time.');
            return;
          }
          await widget.store.addClass(
            ClassSession(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              subject: _subject.text.trim(),
              room: _room.text.trim(),
              day: _day,
              startTime: TimeOfDayValue(_start.hour, _start.minute),
              endTime: TimeOfDayValue(_end.hour, _end.minute),
            ),
          );
        case ManualEntryType.attendance:
          await widget.store.saveAttendance(
            subject: _subject.text,
            attended: int.parse(_attended.text.trim()),
            total: int.parse(_conducted.text.trim()),
            minimumPercentage: _minimum.text.trim().isEmpty
                ? null
                : double.parse(_minimum.text.trim()),
          );
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not save this record. Your entries are still here; please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = switch (widget.type) {
      ManualEntryType.assignment => 'Add assignment',
      ManualEntryType.timetable => 'Add recurring class',
      ManualEntryType.attendance => 'Update attendance',
    };
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Student-entered record',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Use information from your own academic records. These entries are not university-verified.',
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _subject,
              validator: _required,
              maxLength: 200,
              decoration: const InputDecoration(labelText: 'Subject'),
            ),
            if (widget.type == ManualEntryType.assignment) ...[
              TextFormField(
                controller: _title,
                validator: _required,
                maxLength: 200,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              ListTile(
                title: const Text('Due date'),
                subtitle: Text('${_due.day}/${_due.month}/${_due.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _due,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null && mounted) setState(() => _due = picked);
                },
              ),
            ],
            if (widget.type == ManualEntryType.timetable) ...[
              TextFormField(
                controller: _room,
                validator: _required,
                maxLength: 200,
                decoration: const InputDecoration(labelText: 'Room / location'),
              ),
              DropdownButtonFormField<int>(
                initialValue: _day,
                decoration: const InputDecoration(labelText: 'Day'),
                items: List.generate(
                  7,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text(
                      const [
                        'Monday',
                        'Tuesday',
                        'Wednesday',
                        'Thursday',
                        'Friday',
                        'Saturday',
                        'Sunday',
                      ][i],
                    ),
                  ),
                ),
                onChanged: (day) {
                  if (day != null) setState(() => _day = day);
                },
              ),
              ListTile(
                title: const Text('Start time'),
                subtitle: Text(_start.format(context)),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _start,
                  );
                  if (picked != null && mounted) {
                    setState(() => _start = picked);
                  }
                },
              ),
              ListTile(
                title: const Text('End time'),
                subtitle: Text(_end.format(context)),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _end,
                  );
                  if (picked != null && mounted) setState(() => _end = picked);
                },
              ),
            ],
            if (widget.type == ManualEntryType.attendance) ...[
              TextFormField(
                controller: _attended,
                validator: _count,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Classes attended',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _conducted,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total classes conducted',
                ),
                validator: (value) {
                  final error = _count(value);
                  if (error != null) return error;
                  return int.parse(value!.trim()) <
                          (int.tryParse(_attended.text.trim()) ?? 0)
                      ? 'Total cannot be less than attended classes.'
                      : null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _minimum,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Minimum attendance % (optional)',
                  helperText: 'Enter your course requirement if known.',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final percentage = double.tryParse(value.trim());
                  return percentage == null ||
                          !percentage.isFinite ||
                          percentage <= 0 ||
                          percentage > 100
                      ? 'Enter a percentage greater than 0 and at most 100.'
                      : null;
                },
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save record'),
            ),
          ],
        ),
      ),
    );
  }
}
