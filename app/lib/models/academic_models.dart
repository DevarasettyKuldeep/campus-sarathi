enum AssignmentStatus { pending, complete }

class Assignment {
  const Assignment({
    required this.id,
    required this.title,
    required this.subject,
    required this.dueDate,
    this.status = AssignmentStatus.pending,
    required this.recordedAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String subject;
  final DateTime dueDate;
  final AssignmentStatus status;
  final DateTime recordedAt;
  final DateTime updatedAt;
  String get sourceLabel => 'Student-entered';

  Assignment copyWith({AssignmentStatus? status}) => Assignment(
    id: id,
    title: title,
    subject: subject,
    dueDate: dueDate,
    status: status ?? this.status,
    recordedAt: recordedAt,
    updatedAt: DateTime.now().toUtc(),
  );
}

class ClassSession {
  const ClassSession({
    required this.id,
    required this.subject,
    required this.room,
    required this.day,
    required this.startTime,
    required this.endTime,
    this.recordedAt,
  });

  final String id;
  final String subject;
  final String room;
  final int day;
  final TimeOfDayValue startTime;
  final TimeOfDayValue endTime;
  final DateTime? recordedAt;
  String get sourceLabel => 'Student-entered';
}

class TimeOfDayValue {
  const TimeOfDayValue(this.hour, this.minute);
  final int hour;
  final int minute;
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.subject,
    required this.attended,
    required this.total,
    required this.updatedAt,
    this.minimumPercentage,
  });
  final String subject;
  final int attended;
  final int total;
  final DateTime updatedAt;
  final double? minimumPercentage;
  String get sourceLabel => 'Student-entered';
  double? get percentage => total == 0 ? null : attended / total * 100;
  bool? get isBelowMinimum => percentage == null || minimumPercentage == null
      ? null
      : percentage! < minimumPercentage!;
}
