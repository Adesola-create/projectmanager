import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'database_service.dart';
import 'api_service.dart';
import '../models/clock_entry.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseService _db = DatabaseService();
  final String _baseUrl = 'https://reports.schoolpetal.com/api';
  Timer? _syncTimer;

  Future<bool> hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> syncData() async {
    if (!await hasInternetConnection()) return;

    final unsyncedEntries = await _db.getUnsyncedEntries();
    
    for (final entry in unsyncedEntries) {
      try {
        await _syncEntry(entry);
        final syncedEntry = entry.copyWith(synced: true);
        await _db.updateClockEntry(syncedEntry);
      } catch (e) {
        print('Failed to sync entry ${entry.id}: $e');
      }
    }
  }

  Future<void> syncEmployeeStatus(String barcode, int employeeId) async {
    try {
      final response = await ApiService.getTodayClockStatus(barcode);
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        if (data['clockIn'] != null) {
          final entry = ClockEntry(
            id: data['id'],
            employeeId: employeeId,
            employeeName: data['employeeName'] ?? '',
            clockIn: DateTime.parse(data['clockIn']),
            clockOut: data['clockOut'] != null ? DateTime.parse(data['clockOut']) : null,
            dailyPlan: data['dailyPlan'],
            dailyReport: data['dailyReport'],
            synced: true,
            status: data['status'] ?? 'active',
          );
          
          final existingEntry = await _db.getTodayEntry(employeeId);
          if (existingEntry == null) {
            await _db.insertClockEntry(entry);
          } else {
            await _db.updateClockEntry(entry.copyWith(id: existingEntry.id));
          }
        }
      }
    } catch (e) {
      print('Employee sync error (API may be unavailable): $e');
    }
  }

  Future<void> _syncEntry(ClockEntry entry) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/sync-entry'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(entry.toMap()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to sync entry');
    }
  }

  void startAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(Duration(seconds: 30), (_) {
      syncData();
    });
  }

  void stopAutoSync() {
    _syncTimer?.cancel();
  }
}