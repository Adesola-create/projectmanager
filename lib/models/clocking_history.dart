class ClockingHistory {
  final String date;
  final int id;
  final String barcode;
  final String name;
  final String? timein;
  final String? timeout;
  final String remark;
  final bool sentstatus;

  ClockingHistory({
    required this.date,
    required this.id,
    required this.barcode,
    required this.name,
    this.timein,
    this.timeout,
    this.remark = 'Present',
    this.sentstatus = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'id': id,
      'barcode': barcode,
      'name': name,
      'timein': timein,
      'timeout': timeout,
      'remark': remark,
      'sentstatus': sentstatus,
    };
  }

  factory ClockingHistory.fromJson(Map<String, dynamic> json) {
    return ClockingHistory(
      date: json['date'],
      id: json['id'],
      barcode: json['barcode'],
      name: json['name'],
      timein: json['timein'],
      timeout: json['timeout'],
      remark: json['remark'] ?? 'Present',
      sentstatus: json['sentstatus'] ?? false,
    );
  }

  ClockingHistory copyWith({
    String? date,
    int? id,
    String? barcode,
    String? name,
    String? timein,
    String? timeout,
    String? remark,
    bool? sentstatus,
  }) {
    return ClockingHistory(
      date: date ?? this.date,
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      timein: timein ?? this.timein,
      timeout: timeout ?? this.timeout,
      remark: remark ?? this.remark,
      sentstatus: sentstatus ?? this.sentstatus,
    );
  }
}