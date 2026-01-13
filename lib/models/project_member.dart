class ProjectMember {
  final int? id;
  final int projectId;
  final int employeeId;
  final String role;

  ProjectMember({
    this.id,
    required this.projectId,
    required this.employeeId,
    required this.role,
  });

  factory ProjectMember.fromMap(Map<String, dynamic> m) {
    return ProjectMember(
      id: m['id'] as int?,
      projectId: m['projectId'] as int,
      employeeId: m['employeeId'] as int,
      role: m['role'] as String? ?? 'member',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'projectId': projectId,
      'employeeId': employeeId,
      'role': role,
    };
  }
}
