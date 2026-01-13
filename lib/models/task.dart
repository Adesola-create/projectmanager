class Task {
  final int? id;
  final int projectId;
  final int? phaseId;
  final String name;
  final String? description;
  final int? assigneeId;
  final String? dueDate;
  final String? status;
  final int? progress;

  Task({
    this.id,
    required this.projectId,
    this.phaseId,
    required this.name,
    this.description,
    this.assigneeId,
    this.dueDate,
    this.status,
    this.progress,
  });

  factory Task.fromMap(Map<String, dynamic> m) {
    return Task(
      id: m['id'] as int?,
      projectId: m['projectId'] as int,
      phaseId: m['phaseId'] as int?,
      name: m['name'] as String? ?? '',
      description: m['description'] as String?,
      assigneeId: m['assigneeId'] as int?,
      dueDate: m['dueDate'] as String?,
      status: m['status'] as String?,
      progress: m['progress'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'projectId': projectId,
      'phaseId': phaseId,
      'name': name,
      'description': description,
      'assigneeId': assigneeId,
      'dueDate': dueDate,
      'status': status,
      'progress': progress,
    };
  }
}
