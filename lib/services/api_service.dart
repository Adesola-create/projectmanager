import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bcrypt/bcrypt.dart';
import '../models/user.dart';

class ApiService {
  static const String _baseUrl = 'https://reports.schoolpetal.com/api';

  static List<Employee> _cachedEmployees = [];
  static int? _currentUserBusinessId;
  static List<Employee> get cachedEmployees => _cachedEmployees;
  static int? get currentUserBusinessId => _currentUserBusinessId;
  static void setCachedEmployees(List<Employee> employees) => _cachedEmployees = employees;

  static Future<List<Employee>> fetchEmployees([int? businessId]) async {
    // Use current user's business ID if no specific business ID provided
    final filterBusinessId = businessId ?? _currentUserBusinessId;
    
    final url = '$_baseUrl/users.php';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        List<Employee> allEmployees = data.map((json) => Employee.fromJson(json)).toList();
        
        // ALWAYS filter by business ID if available
        if (filterBusinessId != null) {
          _cachedEmployees = allEmployees.where((emp) => emp.businessId == filterBusinessId).toList();
        } else {
          _cachedEmployees = allEmployees;
        }
        
        await saveEmployeesToPrefs(_cachedEmployees);
        return _cachedEmployees;
      }
    } catch (e) {
      print('Fetch employees error: $e');
    }

    final local = await loadEmployeesFromPrefs(filterBusinessId);
    if (local.isNotEmpty) return local;

    throw Exception('Failed to fetch employees');
  }

  static Future<void> saveEmployeesToPrefs(List<Employee> employees) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = employees.map((e) => e.toJson()).toList();
    await prefs.setString('employees_json', json.encode(jsonList));
    await prefs.setString('filtered_employees_json', json.encode(jsonList));
  }

  static Future<List<Employee>> loadEmployeesFromPrefs([int? businessId]) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('employees_json');
    if (saved != null && saved.isNotEmpty) {
      try {
        final List<dynamic> data = json.decode(saved);
        List<Employee> allEmployees = data.map((json) => Employee.fromJson(json)).toList();
        
        if (businessId != null) {
          _cachedEmployees = allEmployees.where((emp) => emp.businessId == businessId).toList();
        } else {
          _cachedEmployees = allEmployees;
        }
        return _cachedEmployees;
      } catch (e) {
        print('Failed to parse saved employees: $e');
      }
    }
    return [];
  }

  static Future<Employee?> authenticateUser(
    String email,
    String password,
  ) async {
    try {
      // Clear all cached data first
      _cachedEmployees.clear();
      _currentUserBusinessId = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('employees_json');
      await prefs.remove('filtered_employees_json');
      
      // First fetch all employees to find the user
      final response = await http.get(Uri.parse('$_baseUrl/users.php'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final allEmployees = data.map((json) => Employee.fromJson(json)).toList();
        
        final user = allEmployees.firstWhere(
          (employee) => employee.email == email,
          orElse: () => throw Exception('User not found'),
        );

        if (BCrypt.checkpw(password, user.password)) {
          // Now filter and cache only employees from same business
          _currentUserBusinessId = user.businessId;
          _cachedEmployees = allEmployees.where((emp) => emp.businessId == user.businessId).toList();
          await saveEmployeesToPrefs(_cachedEmployees);
          return user;
        }
      }
      return null;
    } catch (e) {
      print('Authentication error: $e');
      return null;
    }
  }

  static Employee? findEmployeeByBarcode(String barcode) {
    if (_currentUserBusinessId == null) {
      return null;
    }
    
    try {
      // ONLY search employees from current user's business
      final businessEmployees = _cachedEmployees.where((emp) => emp.businessId == _currentUserBusinessId).toList();
      
      final found = businessEmployees.firstWhere(
        (employee) => employee.barcode == barcode,
        orElse: () => throw Exception('Employee not found in business'),
      );
      
      return found;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> clockAction(String barcode, String action) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/clock.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'barcode': barcode, 'action': action}),
      );

      print('Clock Action API Response:');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Parsed Response: $data');
        return {'success': data['success'] == true, 'message': data['message'] ?? 'Success'};
      } else {
        final data = json.decode(response.body);
        print('Parsed Error Response: $data');
        
        // Handle "Already clocked in" as a special case for clock out
        if (data['error'] != null && data['error'].toString().contains('Already clocked in') && action == 'clock_out') {
          return {'success': true, 'message': 'Clock out processed'};
        }
        
        return {'success': false, 'message': data['error'] ?? data['message'] ?? 'Unknown error'};
      }
    } catch (e) {
      print('Clock action error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getTodayClockStatus(String barcode) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/users.php'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final employee = data.firstWhere(
          (emp) => emp['barcode'] == barcode,
          orElse: () => null,
        );
        
        if (employee != null && employee['daily_status'] != null) {
          final status = employee['daily_status'];
          return {
            'success': true,
            'data': {
              'id': employee['id'],
              'employeeName': employee['name'],
              'clockIn': status['clocked_in'] ? status['clock_in_time'] : null,
              'clockOut': status['clocked_out'] ? status['clock_out_time'] : null,
              'dailyPlan': status['plan_submitted'] ? 'Plan submitted' : null,
              'dailyReport': status['report_submitted'] ? 'Report submitted' : null,
              'status': 'active',
            }
          };
        }
      }
      return {'success': false, 'message': 'Employee not found'};
    } catch (e) {
      return {'success': false, 'message': 'API unavailable'};
    }
  }

  static Future<Map<String, dynamic>> getClockingHistory([int? employeeId]) async {
    try {
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(Duration(days: 7));
      
      // Get a barcode from cached employees for the request
      String barcode = 'system';
      if (_cachedEmployees.isNotEmpty) {
        barcode = _cachedEmployees.first.barcode;
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/reports.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'barcode': barcode,
          'type': 'clocking_history',
          'content': 'fetch_history',
          'employee_id': employeeId,
          'start_date': oneWeekAgo.toIso8601String().split('T')[0],
          'end_date': now.toIso8601String().split('T')[0],
          'all_employees': employeeId == null, // Get all employees if no specific ID
        }),
      );
      
      print('History API Status Code: ${response.statusCode}');
      print('History API Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': 'Failed to fetch history', 'status': response.statusCode};
      }
    } catch (e) {
      print('History API Error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> submitReport(
    String barcode,
    String type,
    String content,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reports.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'barcode': barcode,
          'type': type,
          'content': content,
        }),
      );

      final data = response.body.isNotEmpty ? json.decode(response.body) : {};

      if (response.statusCode == 200) {
        return {
          'success': data['success'] == true,
          'message': data['message'] ?? 'Submitted',
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? data['message'] ?? 'Request failed',
          'status': response.statusCode,
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}