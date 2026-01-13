class Deliverable {
  final int? id;
  final int taskId;
  final String name;
  final String? description;
  final String? dueDate;
  final String? status;

  Deliverable({
    this.id,
    required this.taskId,
    required this.name,
    this.description,
    this.dueDate,
    this.status,
  });

  factory Deliverable.fromMap(Map<String, dynamic> m) {
    return Deliverable(
      id: m['id'] as int?,
      taskId: m['taskId'] as int,
      name: m['name'] as String? ?? '',
      description: m['description'] as String?,
      dueDate: m['dueDate'] as String?,
      status: m['status'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'taskId': taskId,
      'name': name,
      'description': description,
      'dueDate': dueDate,
      'status': status,
    };
  }
}
