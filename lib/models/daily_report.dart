class DailyReport {
  final int? id;
  final int employeeId;
  final String date;
  final int? taskId;
  final String content;
  final String? status;

  DailyReport({
    this.id,
    required this.employeeId,
    required this.date,
    this.taskId,
    required this.content,
    this.status,
  });

  factory DailyReport.fromMap(Map<String, dynamic> m) {
    return DailyReport(
      id: m['id'] as int?,
      employeeId: m['employeeId'] as int,
      date: m['date'] as String? ?? '',
      taskId: m['taskId'] as int?,
      content: m['content'] as String? ?? '',
      status: m['status'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'employeeId': employeeId,
      'date': date,
      'taskId': taskId,
      'content': content,
      'status': status,
    };
  }
}
