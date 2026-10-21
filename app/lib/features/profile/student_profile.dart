/// Student-managed semester context. Dates are calendar days, not UTC instants.
class StudentProfile {
  const StudentProfile({
    required this.programme,
    required this.semesterNumber,
    required this.semesterStart,
    required this.semesterEnd,
    required this.updatedAt,
  });
  final String programme;
  final int semesterNumber;
  final String semesterStart;
  final String semesterEnd;
  final DateTime updatedAt;
  String get timezone => 'Asia/Kolkata';

  static String? programmeError(String? value) =>
      value == null ||
          value.trim().isEmpty ||
          value.trim().length > 200 ||
          RegExp(r'[\x00-\x1f\x7f]').hasMatch(value)
      ? 'Enter a programme name of 1–200 characters.'
      : null;

  static String? dayError(String? value) {
    if (value == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return 'Use YYYY-MM-DD.';
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null ||
        parsed.toIso8601String().substring(0, 10) != value ||
        value.compareTo('2000-01-01') < 0 ||
        value.compareTo('2100-12-31') > 0) {
      return 'Enter a real date between 2000 and 2100.';
    }
    return null;
  }

  void validate() {
    if (programmeError(programme) != null ||
        semesterNumber < 1 ||
        semesterNumber > 30 ||
        dayError(semesterStart) != null ||
        dayError(semesterEnd) != null ||
        semesterEnd.compareTo(semesterStart) < 0) {
      throw ArgumentError('Check programme, semester and semester dates.');
    }
  }
}
