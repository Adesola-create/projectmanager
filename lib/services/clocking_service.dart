import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/clocking_history.dart';
import '../models/user.dart';
import '../models/clock_entry.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';

class ClockingService {
  static const String _historyKey = 'clocking_history';
  static const String _employeesKey = 'employees_cache';

  static Future<void> saveEmployeesLocally(List<Employee> employees) async {
    final prefs = await SharedPreferences.getInstance();
    final employeesJson = employees.map((e) => e.toJson()).toList();
    await prefs.setString(_employeesKey, jsonEncode(employeesJson));
  }

  static Future<List<Employee>> getLocalEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    final employeesString = prefs.getString(_employeesKey);
    if (employeesString != null) {
      final List<dynamic> employeesJson = jsonDecode(employeesString);
      return employeesJson.map((json) => Employee.fromJson(json)).toList();
    }
    return [];
  }

  static Future<List<ClockingHistory>> getClockingHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString(_historyKey);
    if (historyString != null) {
      final List<dynamic> historyJson = jsonDecode(historyString);
      return historyJson.map((json) => ClockingHistory.fromJson(json)).toList();
    }
    return [];
  }

  static Future<void> saveClockingHistory(List<ClockingHistory> history) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = history.map((h) => h.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(historyJson));
  }

  static Future<String> processClockAction(String barcode) async {
    final employees = await getLocalEmployees();
    final employee = employees.firstWhere(
      (e) => e.barcode == barcode,
      orElse: () => throw Exception('Employee not found'),
    );

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final currentTime = DateFormat('HH:mm').format(DateTime.now());
    final db = DatabaseService();

    // First sync from API to get latest status
    try {
      final apiStatus = await ApiService.getTodayClockStatus(barcode);
      if (apiStatus['success'] == true && apiStatus['data'] != null) {
        await _syncDatabaseFromAPI(employee.id, apiStatus['data']);
      }
    } catch (e) {
      print('API sync failed: $e');
    }

    // Check database for today's entry
    final todayEntry = await db.getTodayEntry(employee.id);
    final history = await getClockingHistory();
    final todayRecord = history
        .where((h) => h.barcode == barcode && h.date == today)
        .toList();

    if (todayEntry == null) {
      // First clock action of the day - Clock In
      final clockEntry = ClockEntry(
        employeeId: employee.id,
        employeeName: employee.name,
        clockIn: DateTime.now(),
        status: 'clocked_in',
      );
      await db.insertClockEntry(clockEntry);

      final newRecord = ClockingHistory(
        date: today,
        id: employee.id,
        barcode: barcode,
        name: employee.name,
        timein: currentTime,
        remark: 'Present',
        sentstatus: false,
      );

      history.add(newRecord);
      await saveClockingHistory(history);
      _syncRecord(newRecord);

      return 'Clocked In at $currentTime';
    } else if (todayEntry.clockOut == null) {
      // Second clock action - Clock Out
      // Check if both plan and report have been submitted (from database)
      if (todayEntry.dailyPlan == null || todayEntry.dailyPlan!.isEmpty) {
        throw Exception(
          'Daily plan not submitted yet. Please submit your daily plan before clocking out.',
        );
      }

      if (todayEntry.dailyReport == null || todayEntry.dailyReport!.isEmpty) {
        throw Exception(
          'Daily report not submitted yet. Please submit your daily report before clocking out.',
        );
      }

      // Update database clock entry with clockOut
      final updatedEntry = todayEntry.copyWith(clockOut: DateTime.now());
      await db.updateClockEntry(updatedEntry);

      // Update local history
      if (todayRecord.isNotEmpty) {
        final updatedRecord = todayRecord.first.copyWith(
          timeout: currentTime,
          sentstatus: false,
        );
        final index = history.indexWhere(
          (h) => h.barcode == barcode && h.date == today,
        );
        history[index] = updatedRecord;
        await saveClockingHistory(history);
        _syncRecord(updatedRecord);
      }

      return 'Clocked Out at $currentTime';
    } else {
      // Already clocked in and out for today
      return 'Already completed clocking for today';
    }
  }

  static Future<void> _syncDatabaseFromAPI(int employeeId, Map<String, dynamic> apiData) async {
    final db = DatabaseService();
    if (apiData['clockIn'] != null) {
      final entry = ClockEntry(
        id: apiData['id'],
        employeeId: employeeId,
        employeeName: apiData['employeeName'] ?? '',
        clockIn: DateTime.parse(apiData['clockIn']),
        clockOut: apiData['clockOut'] != null ? DateTime.parse(apiData['clockOut']) : null,
        dailyPlan: apiData['dailyPlan'],
        dailyReport: apiData['dailyReport'],
        synced: true,
        status: apiData['status'] ?? 'active',
      );
      
      final existingEntry = await db.getTodayEntry(employeeId);
      if (existingEntry == null) {
        await db.insertClockEntry(entry);
      } else {
        await db.updateClockEntry(entry.copyWith(id: existingEntry.id));
      }
    }
  }

  static Future<void> _syncRecord(ClockingHistory record) async {
    try {
      final success = await ApiService.clockAction(
        record.barcode,
        record.timeout == null ? 'clock_in' : 'clock_out',
      );

      if (success) {
        final history = await getClockingHistory();
        final index = history.indexWhere(
          (h) => h.barcode == record.barcode && h.date == record.date,
        );

        if (index != -1) {
          history[index] = record.copyWith(sentstatus: true);
          await saveClockingHistory(history);
        }
      }
    } catch (e) {
      print('Sync error: $e');
    }
  }

  static Future<void> syncUnsentRecords() async {
    final history = await getClockingHistory();
    final unsentRecords = history.where((h) => !h.sentstatus).toList();

    for (final record in unsentRecords) {
      await _syncRecord(record);
    }
  }
}
