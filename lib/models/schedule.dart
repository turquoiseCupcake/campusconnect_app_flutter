// lib/models/schedule.dart
// Type-safe models for GET /api/v1/schedules.
// The API returns data pre-grouped by day — no client-side grouping needed.

class ScheduleData {
  final Map<String, dynamic> student;
  final List<DaySchedule> weeklySchedule;
  final Map<String, dynamic> summary;

  const ScheduleData({
    required this.student,
    required this.weeklySchedule,
    required this.summary,
  });

  factory ScheduleData.fromJson(Map<String, dynamic> json) => ScheduleData(
        student:        json['student'] as Map<String, dynamic>,
        weeklySchedule: (json['weekly_schedule'] as List)
            .map((d) => DaySchedule.fromJson(d as Map<String, dynamic>))
            .toList(),
        summary: json['summary'] as Map<String, dynamic>,
      );
}

class DaySchedule {
  final String day;
  final List<Map<String, dynamic>> classes;

  const DaySchedule({required this.day, required this.classes});

  factory DaySchedule.fromJson(Map<String, dynamic> json) => DaySchedule(
        day:     json['day'] as String,
        classes: (json['classes'] as List).cast<Map<String, dynamic>>(),
      );
}
