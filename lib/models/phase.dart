class Phase {
  final int? id;
  final int projectId;
  final String name;
  final String? description;
  final int? sequence;
  final String? startDate;
  final String? endDate;
  final String? status;

  Phase({
    this.id,
    required this.projectId,
    required this.name,
    this.description,
    this.sequence,
    this.startDate,
    this.endDate,
    this.status,
  });

  factory Phase.fromMap(Map<String, dynamic> m) {
    return Phase(
      id: m['id'] as int?,
      projectId: m['projectId'] as int,
      name: m['name'] as String? ?? '',
      description: m['description'] as String?,
      sequence: m['sequence'] as int?,
      startDate: m['startDate'] as String?,
      endDate: m['endDate'] as String?,
      status: m['status'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'projectId': projectId,
      'name': name,
      'description': description,
      'sequence': sequence,
      'startDate': startDate,
      'endDate': endDate,
      'status': status,
    };
  }
}
