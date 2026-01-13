class Project {
  final int? id;
  final String name;
  final String? description;
  final int? ownerId;
  final String? startDate;
  final String? endDate;
  final String? status;
  final String? createdAt;

  Project({
    this.id,
    required this.name,
    this.description,
    this.ownerId,
    this.startDate,
    this.endDate,
    this.status,
    this.createdAt,
  });

  factory Project.fromMap(Map<String, dynamic> m) {
    return Project(
      id: m['id'] as int?,
      name: m['name'] as String? ?? '',
      description: m['description'] as String?,
      ownerId: m['ownerId'] as int?,
      startDate: m['startDate'] as String?,
      endDate: m['endDate'] as String?,
      status: m['status'] as String?,
      createdAt: m['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'startDate': startDate,
      'endDate': endDate,
      'status': status,
      'createdAt': createdAt,
    };
  }
}
