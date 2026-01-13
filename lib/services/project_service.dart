import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

class ProjectService {
  final DatabaseService _dbService = DatabaseService();

  Future<Database> get _db async => await _dbService.database;

  Future<bool> isLeader(int employeeId, int projectId) async {
    final db = await _db;
    final maps = await db.query(
      'project_members',
      where: 'projectId = ? AND employeeId = ? AND role = ?',
      whereArgs: [projectId, employeeId, 'leader'],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  Future<bool> isSupervisor(int employeeId, int projectId) async {
    final db = await _db;
    final maps = await db.query(
      'project_members',
      where: 'projectId = ? AND employeeId = ? AND role = ?',
      whereArgs: [projectId, employeeId, 'supervisor'],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  Future<bool> isOwner(int employeeId, int projectId) async {
    final db = await _db;
    final maps = await db.query(
      'projects',
      where: 'id = ? AND ownerId = ?',
      whereArgs: [projectId, employeeId],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  Future<bool> canManageProject(int employeeId, int projectId) async {
    if (await isOwner(employeeId, projectId)) return true;
    if (await isLeader(employeeId, projectId)) return true;
    if (await isSupervisor(employeeId, projectId)) return true;
    return false;
  }

  /// Adds a member to a project. Throws if caller lacks permission.
  Future<int> addMember({
    required int callerId,
    required int projectId,
    required int employeeId,
    String role = 'member',
  }) async {
    final can = await canManageProject(callerId, projectId);
    if (!can) throw Exception('Permission denied');
    return await _dbService.addProjectMember(projectId, employeeId, role);
  }

  Future<List<Map<String, dynamic>>> getMembers(int projectId) async {
    final db = await _db;
    final maps = await db.query(
      'project_members',
      where: 'projectId = ?',
      whereArgs: [projectId],
    );
    return maps;
  }

  /// Remove a member from a project. Caller must have manage rights.
  Future<int> removeMember({
    required int callerId,
    required int projectId,
    required int employeeId,
  }) async {
    final can = await canManageProject(callerId, projectId);
    if (!can) throw Exception('Permission denied');
    final db = await _db;
    return await db.delete(
      'project_members',
      where: 'projectId = ? AND employeeId = ?',
      whereArgs: [projectId, employeeId],
    );
  }

  /// Assign a task to a user. Caller must be assignee (self) or have manage rights on project.
  Future<void> assignTask({
    required int callerId,
    required int taskId,
    required int assigneeId,
  }) async {
    final db = await _db;
    final tasks = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [taskId],
      limit: 1,
    );
    if (tasks.isEmpty) throw Exception('Task not found');
    final task = tasks.first;
    final projectId = task['projectId'] as int?;

    if (callerId != assigneeId) {
      if (projectId == null) throw Exception('Task has no project');
      final can = await canManageProject(callerId, projectId);
      if (!can) throw Exception('Permission denied');
    }

    await db.update(
      'tasks',
      {'assigneeId': assigneeId},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  /// Create project and add owner as leader
  Future<int> createProjectWithOwner(
    Map<String, dynamic> project,
    int ownerId,
  ) async {
    final id = await _dbService.createProject(project);
    await _dbService.addProjectMember(id, ownerId, 'leader');
    return id;
  }
}
