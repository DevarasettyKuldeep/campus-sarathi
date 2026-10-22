import 'dart:math';
import 'package:uuid/uuid.dart';
import '../../models/academic_models.dart';
import '../../repositories/academic_store.dart';
import 'assistant_models.dart';
import 'assistant_api.dart';

class LocalAssistantEngine {
  LocalAssistantEngine({
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  static const _uuid = Uuid();

  AssistantChatResponse generateResponse(
    String message,
    AcademicStore store, {
    String? clientMessageId,
  }) {
    final effectiveClientId = clientMessageId ?? _uuid.v4();
    final lower = message.trim().toLowerCase();

    // 1. Detect prompt injection
    if (RegExp(r'ignore\s+(all\s+)?(previous|prior)\s+instructions', caseSensitive: false).hasMatch(message) ||
        RegExp(r'system\s+prompt', caseSensitive: false).hasMatch(message) ||
        RegExp(r'select\s+.*\s+from', caseSensitive: false).hasMatch(message) ||
        RegExp(r'drop\s+table', caseSensitive: false).hasMatch(message)) {
      return AssistantChatResponse(
        messageId: _uuid.v4(),
        clientMessageId: effectiveClientId,
        reply:
            'I am your Campus Sārathi academic companion. I can only assist with your personal academic schedule, attendance, and coursework planning.',
        references: const [],
      );
    }

    // 2. Attendance & Skip queries
    if (lower.contains('skip') ||
        lower.contains('miss') ||
        lower.contains('attendance')) {
      return _handleAttendanceQuery(lower, store, effectiveClientId);
    }

    // 3. Today's schedule / What to focus on
    if (lower.contains('today') ||
        lower.contains('what should i do') ||
        lower.contains('focus') ||
        lower.contains('schedule') ||
        lower.contains('timetable')) {
      return _handleScheduleQuery(store, effectiveClientId);
    }

    // 4. Overwhelmed / Workload stress
    if (lower.contains('overwhelm') ||
        lower.contains('stress') ||
        lower.contains('too much') ||
        lower.contains('assignments') ||
        lower.contains('deadline')) {
      return _handleStressQuery(store, effectiveClientId);
    }

    // 5. Default welcoming guidance
    return AssistantChatResponse(
      messageId: _uuid.v4(),
      clientMessageId: effectiveClientId,
      reply:
          'Hello! I am Campus Sārathi, your academic companion. You can ask me:\n'
          '• "What should I do today?"\n'
          '• "Can I skip tomorrow\'s class?"\n'
          '• "I am overwhelmed with assignments."\n'
          '• "What is my current attendance summary?"',
      references: const [],
    );
  }

  AssistantChatResponse _handleAttendanceQuery(
    String lower,
    AcademicStore store,
    String clientMessageId,
  ) {
    final list = store.attendance;
    if (list.isEmpty) {
      return AssistantChatResponse(
        messageId: _uuid.v4(),
        clientMessageId: clientMessageId,
        reply:
            'You haven\'t saved any attendance records yet. Add your courses and attendance in the Academic tab to calculate skip margins and risk alerts.',
        references: const [],
      );
    }

    // Try finding specific course in student query
    AttendanceRecord? matched;
    for (final att in list) {
      if (lower.contains(att.subject.toLowerCase())) {
        matched = att;
        break;
      }
    }

    if (matched != null) {
      final references = ['attendance:${matched.subject}'];
      if (matched.total <= 0) {
        return AssistantChatResponse(
          messageId: _uuid.v4(),
          clientMessageId: clientMessageId,
          reply:
              'No classes have been recorded for ${matched.subject} yet, so attendance risk cannot be calculated.',
          references: references,
        );
      }

      final percentage = (matched.attended / matched.total) * 100;
      if (matched.minimumPercentage == null || matched.minimumPercentage! <= 0) {
        return AssistantChatResponse(
          messageId: _uuid.v4(),
          clientMessageId: clientMessageId,
          reply:
              'Your recorded attendance for ${matched.subject} is ${matched.attended}/${matched.total} (${percentage.toStringAsFixed(1)}%). However, no minimum threshold is configured for this course, so the safety risk cannot be determined.',
          references: references,
        );
      }

      final minPct = matched.minimumPercentage!;
      final ifMissedNext = (matched.attended / (matched.total + 1)) * 100;
      final safeToSkip = ifMissedNext >= minPct;

      if (safeToSkip) {
        return AssistantChatResponse(
          messageId: _uuid.v4(),
          clientMessageId: clientMessageId,
          reply:
              'Your recorded attendance for ${matched.subject} is ${matched.attended}/${matched.total} (${percentage.toStringAsFixed(1)}%). If you miss the next class, it will drop to ${ifMissedNext.toStringAsFixed(1)}%, which is still above your ${minPct.toStringAsFixed(0)}% requirement. You can safely afford to miss it if necessary, but attending is still advised.',
          references: references,
        );
      } else {
        final minRatio = minPct / 100.0;
        int needed = 1;
        if (minRatio < 1.0) {
          needed = max(1, ((minRatio * matched.total - matched.attended) / (1.0 - minRatio)).ceil());
        }
        return AssistantChatResponse(
          messageId: _uuid.v4(),
          clientMessageId: clientMessageId,
          reply:
              'Your recorded attendance for ${matched.subject} is ${matched.attended}/${matched.total} (${percentage.toStringAsFixed(1)}%), which is close to or below your ${minPct.toStringAsFixed(0)}% requirement. Missing the next class would put you at serious attendance risk. You need to attend the next $needed consecutive class(es) to maintain the required threshold.',
          references: references,
        );
      }
    }

    // General summary
    final summary = list.map((a) {
      final p = a.total > 0
          ? '${((a.attended / a.total) * 100).toStringAsFixed(1)}%'
          : 'No classes';
      return '${a.subject}: $p (${a.attended}/${a.total})';
    }).join('\n');

    return AssistantChatResponse(
      messageId: _uuid.v4(),
      clientMessageId: clientMessageId,
      reply:
          'Here is your currently recorded attendance:\n$summary\n\nAsk me specifically about any course to calculate whether you can afford to miss an upcoming session.',
      references: const ['attendance:summary'],
    );
  }

  AssistantChatResponse _handleScheduleQuery(
    AcademicStore store,
    String clientMessageId,
  ) {
    final now = _clock();
    final jsDay = now.weekday; // 1 = Monday ... 7 = Sunday
    final todayClasses = store.classes
        .where((c) => c.day == jsDay)
        .toList()
      ..sort((a, b) {
        final startA = a.startTime.hour * 60 + a.startTime.minute;
        final startB = b.startTime.hour * 60 + b.startTime.minute;
        return startA.compareTo(startB);
      });

    final pending = store.assignments
        .where((a) => a.status == AssignmentStatus.pending)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final threeDays = now.add(const Duration(days: 3));
    final urgent = pending.where((a) => a.dueDate.isBefore(threeDays)).toList();
    final upcoming = pending.where((a) => !a.dueDate.isBefore(threeDays)).toList();

    final parts = <String>[];
    final references = <String>[];

    if (todayClasses.isNotEmpty) {
      references.add('timetable:today');
      final classLines = todayClasses.map((c) {
        final h = c.startTime.hour.toString().padLeft(2, '0');
        final m = c.startTime.minute.toString().padLeft(2, '0');
        return '• ${c.subject} at $h:$m (${c.room})';
      }).join('\n');
      parts.add('Today\'s classes:\n$classLines');
    } else {
      parts.add('You have no classes scheduled for today.');
    }

    ActionProposalModel? actionProposal;
    if (urgent.isNotEmpty) {
      final first = urgent.first;
      references.add('assignments:urgent');
      final urgentList = urgent
          .map((a) =>
              '• ${a.title} (${a.subject}) due ${a.dueDate.day.toString().padLeft(2, '0')}/${a.dueDate.month.toString().padLeft(2, '0')}')
          .join('\n');
      parts.add('Urgent assignments:\n$urgentList');
      parts.add('Recommendation: Focus on completing ${first.title} first.');

      actionProposal = ActionProposalModel(
        id: _uuid.v4(),
        actionType: 'schedule_study',
        title: 'Schedule Study for ${first.subject}',
        description: 'Dedicate a 90-minute study block today for "${first.title}".',
        payload: {
          'subject': first.subject,
          'assignmentId': first.id,
          'durationMinutes': 90,
        },
        expiresAt: now.add(const Duration(hours: 2)),
      );
    } else if (upcoming.isNotEmpty) {
      references.add('assignments:upcoming');
      parts.add('No urgent deadlines in the next 3 days. Your next task is ${upcoming.first.title} (${upcoming.first.subject}).');
    } else {
      parts.add('You have no pending assignments on record. Great job staying ahead!');
    }

    return AssistantChatResponse(
      messageId: _uuid.v4(),
      clientMessageId: clientMessageId,
      reply: parts.join('\n\n'),
      references: references,
      actionProposal: actionProposal,
    );
  }

  AssistantChatResponse _handleStressQuery(
    AcademicStore store,
    String clientMessageId,
  ) {
    final now = _clock();
    final pending = store.assignments
        .where((a) => a.status == AssignmentStatus.pending)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    if (pending.isEmpty) {
      return AssistantChatResponse(
        messageId: _uuid.v4(),
        clientMessageId: clientMessageId,
        reply:
            'You have no pending assignments recorded. Take a breath and relax, or add any new assignments in the Academic tab.',
        references: const [],
      );
    }

    final threeDays = now.add(const Duration(days: 3));
    final urgent = pending.where((a) => a.dueDate.isBefore(threeDays)).toList();
    final total = pending.length;
    final primary = pending.first;

    final actionProposal = ActionProposalModel(
      id: _uuid.v4(),
      actionType: 'schedule_study',
      title: 'Plan Focus Block: ${primary.title}',
      description: 'Divide workload into a focused 1-hour session today.',
      payload: {
        'subject': primary.subject,
        'assignmentId': primary.id,
        'durationMinutes': 60,
      },
      expiresAt: now.add(const Duration(hours: 2)),
    );

    return AssistantChatResponse(
      messageId: _uuid.v4(),
      clientMessageId: clientMessageId,
      reply:
          'You have $total pending assignment(s): ${urgent.length} urgent and ${total - urgent.length} further out. Let\'s break this down into manageable steps: first focus only on ${primary.title}, and leave the remaining tasks for tomorrow.',
      references: const ['assignments:triage'],
      actionProposal: actionProposal,
    );
  }
}
