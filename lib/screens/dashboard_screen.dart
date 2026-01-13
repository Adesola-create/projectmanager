import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import '../services/api_service.dart';
import '../models/clock_entry.dart';
import '../models/user.dart';
import 'login_screen.dart';
import 'clocking_screen.dart';
import 'reports_screen.dart';
import 'users_list_screen.dart';
import 'clocking_history_screen.dart';
import 'project_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Employee employee;

  DashboardScreen({required this.employee});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _db = DatabaseService();
  final SyncService _sync = SyncService();
  final _planController = TextEditingController();
  final _reportController = TextEditingController();

  ClockEntry? _todayEntry;
  String _planStatus = 'not_submitted'; // 'not_submitted', 'submitted'
  String _reportStatus = 'not_submitted'; // 'not_submitted', 'submitted'
  int? _employeeId;

  @override
  void initState() {
    super.initState();
    _findEmployeeId();
    _loadTodayEntry();
    _checkTodayPlan();
    _sync.startAutoSync();
  }

  Future<void> _findEmployeeId() async {
    _employeeId = widget.employee.id;
  }

  Future<void> _loadTodayEntry() async {
    if (_employeeId != null) {
      // Sync from API first
      await _sync.syncEmployeeStatus(widget.employee.barcode, _employeeId!);
      
      final entry = await _db.getTodayEntry(_employeeId!);
      setState(() {
        _todayEntry = entry;
        if (entry != null) {
          _planController.text = entry.dailyPlan ?? '';
          _reportController.text = entry.dailyReport ?? '';
        }
      });
    }
  }

  Future<void> _checkTodayPlan() async {
    if (_employeeId != null) {
      final plan = await _db.getTodayPlan(_employeeId!);
      setState(() {
        _planStatus = plan != null ? 'submitted' : 'not_submitted';
      });
    }
  }

  Future<void> _openBarcodeScanner(String action) async {
    // This method is no longer needed in the new navigation structure
  }

  Future<void> _clockIn() async {
    if (_employeeId != null) {
      final entry = ClockEntry(
        employeeId: _employeeId!,
        employeeName: widget.employee.name.isNotEmpty
            ? widget.employee.name
            : widget.employee.email,
        clockIn: DateTime.now(),
        status: 'clocked_in',
      );
      await _db.insertClockEntry(entry);
      await _loadTodayEntry();
      _sync.syncData();
      _showSuccessMessage('Clocked in successfully!');
    }
  }

  Future<void> _submitPlan() async {
    if (_planController.text.trim().isNotEmpty && _employeeId != null) {
      await _db.saveDailyPlan(_employeeId!, _planController.text.trim());

      // Submit to API and handle response
      final result = await ApiService.submitReport(
        widget.employee.barcode,
        'plan',
        _planController.text.trim(),
      );

      // If server indicates plan already submitted, reflect that
      if (result['success'] == true ||
          (result['message'] != null &&
              result['message'].toString().toLowerCase().contains('already'))) {
        setState(() {
          _planStatus = 'submitted';
        });
      }

      _sync.syncData();
      _showSuccessMessage(
        result['message'] ??
            (result['success'] == true
                ? 'Daily plan submitted!'
                : 'Plan saved locally (will sync when online)'),
      );
    }
  }

  Future<void> _submitReport() async {
    if (_reportController.text.trim().isNotEmpty) {
      try {
        // Save locally first
        // TODO: Add local report saving to database

        setState(() {
          _reportStatus = 'submitted';
        });

        // Submit to API and show result
        final res = await ApiService.submitReport(
          widget.employee.barcode,
          'report',
          _reportController.text.trim(),
        );

        _showSuccessMessage(
          res['message'] ??
              (res['success'] == true
                  ? 'Daily report submitted!'
                  : 'Report saved locally'),
        );
      } catch (e) {
        _showSuccessMessage('Report saved locally');
      }
    }
  }

  Future<void> _clockOut() async {
    if (_todayEntry != null) {
      final updatedEntry = _todayEntry!.copyWith(
        clockOut: DateTime.now(),
        status: 'clocked_out',
      );
      await _db.updateClockEntry(updatedEntry);
      await _loadTodayEntry();
      _sync.syncData();
      _showSuccessMessage('Clocked out successfully!');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showReportSuccessModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('Success!'),
            ],
          ),
          content: Text('Your daily report has been successfully submitted.'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    // clear persisted user and return to login
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Welcome, ${widget.employee.name.isNotEmpty ? widget.employee.name : widget.employee.email}',
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [IconButton(onPressed: _logout, icon: Icon(Icons.logout))],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            if (widget.employee.canClockOthers) ...[
              _buildNavigationCard(
                'Clock Employees',
                'Clock other employees in and out',
                Icons.access_time,
                Colors.blue,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ClockingScreen(employee: widget.employee),
                  ),
                ),
              ),
              SizedBox(height: 16),
              // _buildNavigationCard(
              //   'Projects',
              //   'Create and manage projects, phases and tasks',
              //   Icons.work,
              //   Colors.teal,
              //   () => Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //       builder: (context) =>
              //           ProjectListScreen(employee: widget.employee),
              //     ),
              //   ),
              // ),
              SizedBox(height: 16),
            ],
            _buildNavigationCard(
              'My Reports',
              'Submit daily plan and report',
              Icons.assignment,
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ReportsScreen(employee: widget.employee),
                ),
              ),
            ),
            SizedBox(height: 16),
            _buildNavigationCard(
              'Clocking History',
              'View your clocking records',
              Icons.history,
              Colors.purple,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ClockingHistoryScreen(employee: widget.employee),
                ),
              ),
            ),
            if (widget.employee.canClockOthers) ...[
              SizedBox(height: 16),
              _buildNavigationCard(
                'Users List',
                'View all employees and barcodes',
                Icons.people,
                Colors.green,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UsersListScreen()),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationCard(
    String title,
    String subtitle,
    IconData icon,
    MaterialColor color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color[400]!, color[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Colors.white),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue[400]!, Colors.blue[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Icon(_getStatusIcon(), size: 60, color: Colors.white),
            SizedBox(height: 16),
            Text(
              _getStatusText(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            if (_todayEntry != null) ...[
              Text(
                'Clock In: ${DateFormat('HH:mm').format(_todayEntry!.clockIn)}',
                style: TextStyle(color: Colors.white70),
              ),
              if (_todayEntry!.clockOut != null)
                Text(
                  'Clock Out: ${DateFormat('HH:mm').format(_todayEntry!.clockOut!)}',
                  style: TextStyle(color: Colors.white70),
                ),
            ],
            SizedBox(height: 16),
            if (true) // Replace with actual clock status check
              ElevatedButton(
                onPressed: () => _openBarcodeScanner('clock_in'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue[600],
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_scanner),
                    SizedBox(width: 8),
                    Text('Scan to Clock In', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment, color: Colors.orange[600], size: 28),
                SizedBox(width: 12),
                Text(
                  'Daily Plan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextField(
              controller: _planController,
              maxLines: 4,
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'What do you plan to accomplish today?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _planController.text.trim().isNotEmpty
                    ? _submitPlan
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Submit Plan', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: Colors.green[600], size: 28),
                SizedBox(width: 12),
                Text(
                  'Daily Report',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextField(
              controller: _reportController,
              maxLines: 4,
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'What did you accomplish today?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _reportController.text.trim().isNotEmpty
                    ? _submitReport
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Submit Report', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClockOutCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.red[400]!, Colors.red[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.logout, size: 60, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Ready to Clock Out?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You have completed your daily plan and report',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _openBarcodeScanner('clock_out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red[600],
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_scanner),
                  SizedBox(width: 8),
                  Text('Scan to Clock Out', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon() {
    return Icons.login;
  }

  String _getStatusText() {
    return 'Ready to Clock In';
  }
}
