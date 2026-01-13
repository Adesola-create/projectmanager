import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/clock_entry.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'clocking.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE clock_entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employeeId INTEGER,
        employeeName TEXT,
        clockIn TEXT,
        clockOut TEXT,
        dailyPlan TEXT,
        dailyReport TEXT,
        synced INTEGER,
        status TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_plans(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employeeId INTEGER,
        date TEXT,
        plan TEXT,
        synced INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE projects(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        description TEXT,
        ownerId INTEGER,
        startDate TEXT,
        endDate TEXT,
        status TEXT,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE phases(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        projectId INTEGER,
        name TEXT,
        description TEXT,
        sequence INTEGER,
        startDate TEXT,
        endDate TEXT,
        status TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        projectId INTEGER,
        phaseId INTEGER,
        name TEXT,
        description TEXT,
        assigneeId INTEGER,
        dueDate TEXT,
        status TEXT,
        progress INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE deliverables(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        taskId INTEGER,
        name TEXT,
        description TEXT,
        dueDate TEXT,
        status TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE project_members(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        projectId INTEGER,
        employeeId INTEGER,
        role TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE timetables(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employeeId INTEGER,
        date TEXT,
        timeBlockStart TEXT,
        timeBlockEnd TEXT,
        activity TEXT,
        projectId INTEGER,
        phaseId INTEGER,
        taskId INTEGER,
        completed INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_reports(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employeeId INTEGER,
        date TEXT,
        taskId INTEGER,
        content TEXT,
        status TEXT
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE daily_plans(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          employeeId INTEGER,
          date TEXT,
          plan TEXT,
          synced INTEGER
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE projects(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          description TEXT,
          ownerId INTEGER,
          startDate TEXT,
          endDate TEXT,
          status TEXT,
          createdAt TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE phases(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          projectId INTEGER,
          name TEXT,
          description TEXT,
          sequence INTEGER,
          startDate TEXT,
          endDate TEXT,
          status TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE tasks(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          projectId INTEGER,
          phaseId INTEGER,
          name TEXT,
          description TEXT,
          assigneeId INTEGER,
          dueDate TEXT,
          status TEXT,
          progress INTEGER
        )
      ''');

      await db.execute('''
        CREATE TABLE deliverables(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          taskId INTEGER,
          name TEXT,
          description TEXT,
          dueDate TEXT,
          status TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE project_members(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          projectId INTEGER,
          employeeId INTEGER,
          role TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE timetables(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          employeeId INTEGER,
          date TEXT,
          timeBlockStart TEXT,
          timeBlockEnd TEXT,
          activity TEXT,
          projectId INTEGER,
          phaseId INTEGER,
          taskId INTEGER,
          completed INTEGER
        )
      ''');

      await db.execute('''
        CREATE TABLE daily_reports(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          employeeId INTEGER,
          date TEXT,
          taskId INTEGER,
          content TEXT,
          status TEXT
        )
      ''');
    }
  }

  Future<int> insertClockEntry(ClockEntry entry) async {
    final db = await database;
    return await db.insert('clock_entries', entry.toMap());
  }

  Future<void> updateClockEntry(ClockEntry entry) async {
    final db = await database;
    await db.update(
      'clock_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<List<ClockEntry>> getUnsyncedEntries() async {
    final db = await database;
    final maps = await db.query(
      'clock_entries',
      where: 'synced = ?',
      whereArgs: [0],
    );
    return maps.map((map) => ClockEntry.fromMap(map)).toList();
  }

  Future<ClockEntry?> getTodayEntry(int employeeId) async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    final maps = await db.query(
      'clock_entries',
      where: 'employeeId = ? AND clockIn >= ? AND clockIn < ?',
      whereArgs: [
        employeeId,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
      orderBy: 'clockIn DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return ClockEntry.fromMap(maps.first);
    }
    return null;
  }

  Future<List<ClockEntry>> getAllEntries() async {
    final db = await database;
    final maps = await db.query('clock_entries', orderBy: 'clockIn DESC');
    return maps.map((map) => ClockEntry.fromMap(map)).toList();
  }

  Future<void> saveDailyPlan(int employeeId, String plan) async {
    final db = await database;
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    await db.insert('daily_plans', {
      'employeeId': employeeId,
      'date': dateStr,
      'plan': plan,
      'synced': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getTodayPlan(int employeeId) async {
    final db = await database;
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final maps = await db.query(
      'daily_plans',
      where: 'employeeId = ? AND date = ?',
      whereArgs: [employeeId, dateStr],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return maps.first['plan'] as String;
    }
    return null;
  }

  Future<bool> hasTodayPlan(int employeeId) async {
    final entry = await getTodayEntry(employeeId);
    return entry?.dailyPlan != null && entry!.dailyPlan!.isNotEmpty;
  }

  Future<bool> hasTodayReport(int employeeId) async {
    final entry = await getTodayEntry(employeeId);
    return entry?.dailyReport != null && entry!.dailyReport!.isNotEmpty;
  }

  Future<bool> isClockedIn(int employeeId) async {
    final entry = await getTodayEntry(employeeId);
    return entry != null && entry.clockOut == null;
  }

  Future<bool> isClockedOut(int employeeId) async {
    final entry = await getTodayEntry(employeeId);
    return entry?.clockOut != null;
  }

  // Projects and related CRUD
  Future<int> createProject(Map<String, dynamic> project) async {
    final db = await database;
    project['createdAt'] ??= DateTime.now().toIso8601String();
    return await db.insert('projects', project);
  }

  Future<int> addProjectMember(
    int projectId,
    int employeeId,
    String role,
  ) async {
    final db = await database;
    return await db.insert('project_members', {
      'projectId': projectId,
      'employeeId': employeeId,
      'role': role,
    });
  }

  Future<List<Map<String, dynamic>>> getProjectsForEmployee(
    int employeeId,
  ) async {
    final db = await database;
    final maps = await db.rawQuery(
      '''
      SELECT p.* FROM projects p
      JOIN project_members pm ON p.id = pm.projectId
      WHERE pm.employeeId = ?
      ORDER BY p.createdAt DESC
    ''',
      [employeeId],
    );
    return maps;
  }

  Future<int> createPhase(Map<String, dynamic> phase) async {
    final db = await database;
    return await db.insert('phases', phase);
  }

  Future<List<Map<String, dynamic>>> getPhasesForProject(int projectId) async {
    final db = await database;
    final maps = await db.query(
      'phases',
      where: 'projectId = ?',
      whereArgs: [projectId],
      orderBy: 'sequence ASC',
    );
    return maps;
  }

  Future<int> createTask(Map<String, dynamic> task) async {
    final db = await database;
    return await db.insert('tasks', task);
  }

  Future<List<Map<String, dynamic>>> getTasksForPhase(int phaseId) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'phaseId = ?',
      whereArgs: [phaseId],
      orderBy: 'dueDate ASC',
    );
    return maps;
  }

  Future<int> saveTimetableEntry(Map<String, dynamic> entry) async {
    final db = await database;
    entry['completed'] ??= 0;
    return await db.insert(
      'timetables',
      entry,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getTimetableForEmployee(
    int employeeId,
    String date,
  ) async {
    final db = await database;
    final maps = await db.query(
      'timetables',
      where: 'employeeId = ? AND date = ?',
      whereArgs: [employeeId, date],
      orderBy: 'timeBlockStart ASC',
    );
    return maps;
  }

  Future<int> submitDailyReport(Map<String, dynamic> report) async {
    final db = await database;
    return await db.insert('daily_reports', report);
  }

  Future<List<Map<String, dynamic>>> getDailyReportsForEmployee(
    int employeeId,
    String date,
  ) async {
    final db = await database;
    final maps = await db.query(
      'daily_reports',
      where: 'employeeId = ? AND date = ?',
      whereArgs: [employeeId, date],
    );
    return maps;
  }
}
