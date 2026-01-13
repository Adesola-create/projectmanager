class TimetableEntry {
  final int? id;
  final int employeeId;
  final String date;
  final String timeBlockStart;
  final String timeBlockEnd;
  final String activity;
  final int? projectId;
  final int? phaseId;
  final int? taskId;
  final bool completed;

  TimetableEntry({
    this.id,
    required this.employeeId,
    required this.date,
    required this.timeBlockStart,
    required this.timeBlockEnd,
    required this.activity,
    this.projectId,
    this.phaseId,
    this.taskId,
    this.completed = false,
  });

  factory TimetableEntry.fromMap(Map<String, dynamic> m) {
    return TimetableEntry(
      id: m['id'] as int?,
      employeeId: m['employeeId'] as int,
      date: m['date'] as String? ?? '',
      timeBlockStart: m['timeBlockStart'] as String? ?? '',
      timeBlockEnd: m['timeBlockEnd'] as String? ?? '',
      activity: m['activity'] as String? ?? '',
      projectId: m['projectId'] as int?,
      phaseId: m['phaseId'] as int?,
      taskId: m['taskId'] as int?,
      completed: (m['completed'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'employeeId': employeeId,
      'date': date,
      'timeBlockStart': timeBlockStart,
      'timeBlockEnd': timeBlockEnd,
      'activity': activity,
      'projectId': projectId,
      'phaseId': phaseId,
      'taskId': taskId,
      'completed': completed ? 1 : 0,
    };
  }
}
