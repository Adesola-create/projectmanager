class ClockEntry {
  final int? id;
  final int employeeId;
  final String employeeName;
  final DateTime clockIn;
  final DateTime? clockOut;
  final String? dailyPlan;
  final String? dailyReport;
  final bool synced;
  final String status; // 'clocked_in', 'plan_submitted', 'report_submitted', 'clocked_out'

  ClockEntry({
    this.id,
    required this.employeeId,
    required this.employeeName,
    required this.clockIn,
    this.clockOut,
    this.dailyPlan,
    this.dailyReport,
    this.synced = false,
    this.status = 'clocked_in',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'clockIn': clockIn.toIso8601String(),
      'clockOut': clockOut?.toIso8601String(),
      'dailyPlan': dailyPlan,
      'dailyReport': dailyReport,
      'synced': synced ? 1 : 0,
      'status': status,
    };
  }

  factory ClockEntry.fromMap(Map<String, dynamic> map) {
    return ClockEntry(
      id: map['id'],
      employeeId: map['employeeId'],
      employeeName: map['employeeName'],
      clockIn: DateTime.parse(map['clockIn']),
      clockOut: map['clockOut'] != null ? DateTime.parse(map['clockOut']) : null,
      dailyPlan: map['dailyPlan'],
      dailyReport: map['dailyReport'],
      synced: map['synced'] == 1,
      status: map['status'] ?? 'clocked_in',
    );
  }

  ClockEntry copyWith({
    int? id,
    int? employeeId,
    String? employeeName,
    DateTime? clockIn,
    DateTime? clockOut,
    String? dailyPlan,
    String? dailyReport,
    bool? synced,
    String? status,
  }) {
    return ClockEntry(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      clockIn: clockIn ?? this.clockIn,
      clockOut: clockOut ?? this.clockOut,
      dailyPlan: dailyPlan ?? this.dailyPlan,
      dailyReport: dailyReport ?? this.dailyReport,
      synced: synced ?? this.synced,
      status: status ?? this.status,
    );
  }
}