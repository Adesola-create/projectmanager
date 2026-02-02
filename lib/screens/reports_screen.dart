import 'package:flutter/material.dart';
import 'dart:async';
import '../services/database_service.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../models/clock_entry.dart';

class ReportsScreen extends StatefulWidget {
  final Employee employee;

  const ReportsScreen({super.key, required this.employee});

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with WidgetsBindingObserver {
  final DatabaseService _db = DatabaseService();
  final _planController = TextEditingController();
  final _reportController = TextEditingController();

  String _clockStatus =
      'not_clocked_in'; // 'not_clocked_in', 'clocked_in', 'plan_submitted', 'report_submitted', 'clocked_out'
  int? _employeeId;
  ClockEntry? _todayEntry;
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _employeeId = widget.employee.id;
    _loadTodayStatus();
    // Refresh status every 3 seconds to detect clock-in from other devices
    _refreshTimer = Timer.periodic(Duration(seconds: 3), (_) {
      if (mounted) {
        _loadTodayStatus();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh immediately when app comes to foreground
      if (mounted) {
        _loadTodayStatus();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _planController.dispose();
    _reportController.dispose();
    super.dispose();
  }

  Future<void> _loadTodayStatus() async {
    if (_employeeId != null) {
      // Try to sync from API, but don't fail if it's unavailable
      try {
        await _syncFromAPI();
      } catch (e) {
        // Silently handle API sync failures
      }
      
      final entry = await _db.getTodayEntry(_employeeId!);
      
      // Load existing plan and report into controllers if they exist
      if (entry?.dailyPlan != null && entry!.dailyPlan!.isNotEmpty) {
        _planController.text = entry.dailyPlan!;
      }
      if (entry?.dailyReport != null && entry!.dailyReport!.isNotEmpty) {
        _reportController.text = entry.dailyReport!;
      }
      
      setState(() {
        _todayEntry = entry;
        _isLoading = false;

        if (entry == null) {
          _clockStatus = 'not_clocked_in';
        } else if (entry.clockOut != null) {
          _clockStatus = 'clocked_out';
        } else if (entry.dailyReport != null && entry.dailyReport!.isNotEmpty) {
          _clockStatus = 'report_submitted';
        } else if (entry.dailyPlan != null && entry.dailyPlan!.isNotEmpty) {
          _clockStatus = 'plan_submitted';
        } else {
          _clockStatus = 'clocked_in';
        }
      });
    }
  }

  Future<void> _syncFromAPI() async {
    try {
      final response = await ApiService.getTodayClockStatus(widget.employee.barcode);
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        if (data['clockIn'] != null) {
          final entry = ClockEntry(
            id: data['id'],
            employeeId: _employeeId!,
            employeeName: widget.employee.name,
            clockIn: DateTime.parse(data['clockIn']),
            clockOut: data['clockOut'] != null ? DateTime.parse(data['clockOut']) : null,
            dailyPlan: data['dailyPlan'],
            dailyReport: data['dailyReport'],
            synced: true,
            status: data['status'] ?? 'active',
          );
          
          final existingEntry = await _db.getTodayEntry(_employeeId!);
          if (existingEntry == null) {
            await _db.insertClockEntry(entry);
          } else {
            await _db.updateClockEntry(entry.copyWith(id: existingEntry.id));
          }
        }
      }
    } catch (e) {
      // Silently handle sync errors
    }
  }

  Future<void> _submitPlan() async {
    if (_planController.text.trim().isEmpty ||
        _employeeId == null ||
        _todayEntry == null) {
      _showErrorMessage('Plan cannot be empty');
      return;
    }

    // Check if plan was already submitted (from another device)
    if (_todayEntry!.dailyPlan != null && _todayEntry!.dailyPlan!.isNotEmpty) {
      _showErrorMessage('Daily plan has already been submitted.');
      return;
    }

    try {
      // Save plan to database and update clock entry
      await _db.saveDailyPlan(_employeeId!, _planController.text.trim());

      // Update the clock entry with the plan
      final updatedEntry = _todayEntry!.copyWith(
        dailyPlan: _planController.text.trim(),
      );
      await _db.updateClockEntry(updatedEntry);

      // Submit to API
      final res = await ApiService.submitReport(
        widget.employee.barcode,
        'plan',
        _planController.text.trim(),
      );

      if (res['success'] == true ||
          (res['message'] != null &&
              res['message'].toString().toLowerCase().contains('already'))) {
        _showSuccessMessage(
          'Daily plan submitted successfully! ✓\nNow you can submit your daily report.',
        );
        await _loadTodayStatus();
      } else {
        _showErrorMessage(
          'Failed to submit plan: ${res['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      _showErrorMessage('Error submitting plan: ${e.toString()}');
    }
  }

  Future<void> _submitReport() async {
    if (_reportController.text.trim().isEmpty) {
      _showErrorMessage('Report cannot be empty');
      return;
    }

    // Check if report was already submitted (from another device)
    if (_todayEntry!.dailyReport != null && _todayEntry!.dailyReport!.isNotEmpty) {
      _showErrorMessage('Daily report has already been submitted.');
      return;
    }

    try {
      // Update the clock entry with the report
      final updatedEntry = _todayEntry!.copyWith(
        dailyReport: _reportController.text.trim(),
      );
      await _db.updateClockEntry(updatedEntry);

      // Submit to API
      final res = await ApiService.submitReport(
        widget.employee.barcode,
        'report',
        _reportController.text.trim(),
      );

      if (res['success'] == true) {
        _showSuccessMessage(
          'Daily report submitted successfully! ✓\nYou can now clock out.',
        );
        await _loadTodayStatus();
      } else {
        _showErrorMessage(
          'Failed to submit report: ${res['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      _showErrorMessage('Error submitting report: ${e.toString()}');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildStatusProgressIndicator() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Workflow Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              IconButton(
                onPressed: () async {
                  setState(() {
                    _isLoading = true;
                  });
                  await _loadTodayStatus();
                },
                icon: Icon(Icons.refresh, color: Color(0xFF3B82F6)),
                tooltip: 'Refresh Status',
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildProgressStep(1, 'Clock In', _clockStatus != 'not_clocked_in'),
          SizedBox(height: 16),
          _buildProgressStep(
            2,
            'Submit Daily Plan',
            _clockStatus == 'plan_submitted' ||
                _clockStatus == 'report_submitted' ||
                _clockStatus == 'clocked_out',
          ),
          SizedBox(height: 16),
          _buildProgressStep(
            3,
            'Submit Daily Report',
            _clockStatus == 'report_submitted' ||
                _clockStatus == 'clocked_out',
          ),
          SizedBox(height: 16),
          _buildProgressStep(
            4,
            'Clock Out',
            _clockStatus == 'clocked_out',
            isEnabled: _clockStatus == 'report_submitted',
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep(
    int stepNum,
    String label,
    bool isCompleted, {
    bool isEnabled = false,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? Color(0xFF10B981)
                : (isEnabled ? Color(0xFF3B82F6) : Color(0xFFE2E8F0)),
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    stepNum.toString(),
                    style: TextStyle(
                      color: isCompleted || isEnabled ? Colors.white : Color(0xFF64748B),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: isCompleted ? Color(0xFF10B981) : Color(0xFF374151),
              fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text('My Reports'),
          backgroundColor: Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('My Reports'),
        backgroundColor: Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadTodayStatus,
        color: Color(0xFF3B82F6),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              _buildStatusProgressIndicator(),
              SizedBox(height: 24),
              if (_clockStatus == 'not_clocked_in')
                _buildNotClockedInCard()
              else if (_clockStatus == 'clocked_in')
                _buildPlanCard()
              else if (_clockStatus == 'plan_submitted')
                _buildReportCard()
              else if (_clockStatus == 'report_submitted')
                _buildAllCompleteCard()
              else if (_clockStatus == 'clocked_out')
                _buildClockedOutCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotClockedInCard() {
    return Card(
      elevation: 4,
      color: Colors.orange[50],
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.login, color: Colors.orange[600], size: 28),
                SizedBox(width: 12),
                Text(
                  'Waiting for Clock In',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'You need to be clocked in before submitting your daily plan. If you have already been clocked in by an admin, please tap the refresh button above to update your status.',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                height: 1.5,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pull down to refresh or tap the refresh button above if you were clocked in from another device.',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard() {
    final isAlreadySubmitted = _todayEntry?.dailyPlan != null && _todayEntry!.dailyPlan!.isNotEmpty;
    
    return Card(
      elevation: 4,
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
                if (isAlreadySubmitted) ...[
                  SizedBox(width: 8),
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                ],
              ],
            ),
            SizedBox(height: 8),
            Text(
              isAlreadySubmitted ? 'Plan submitted' : 'Step 2: Plan your day',
              style: TextStyle(
                fontSize: 12,
                color: isAlreadySubmitted ? Colors.green[600] : Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _planController,
              maxLines: 5,
              enabled: !isAlreadySubmitted,
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                hintText: isAlreadySubmitted 
                    ? 'Plan has been submitted'
                    : 'What do you plan to accomplish today? Be specific about tasks and goals.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isAlreadySubmitted ? Colors.grey[100] : Colors.grey[50],
                contentPadding: EdgeInsets.all(12),
              ),
            ),
            SizedBox(height: 16),
            if (!isAlreadySubmitted) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _planController.text.trim().isNotEmpty
                      ? _submitPlan
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    padding: EdgeInsets.symmetric(vertical: 14),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: Text(
                    'Submit Plan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '💡 After submitting your plan, you\'ll be able to submit your daily report at the end of the day.',
                  style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                ),
              ),
            ] else ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700], size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your daily plan has been submitted successfully.',
                        style: TextStyle(fontSize: 12, color: Colors.green[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard() {
    final isAlreadySubmitted = _todayEntry?.dailyReport != null && _todayEntry!.dailyReport!.isNotEmpty;
    
    return Card(
      elevation: 4,
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
                if (isAlreadySubmitted) ...[
                  SizedBox(width: 8),
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                ],
              ],
            ),
            SizedBox(height: 8),
            Text(
              isAlreadySubmitted ? 'Report submitted' : 'Step 3: Report your progress',
              style: TextStyle(
                fontSize: 12,
                color: isAlreadySubmitted ? Colors.green[600] : Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _reportController,
              maxLines: 5,
              enabled: !isAlreadySubmitted,
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                hintText: isAlreadySubmitted
                    ? 'Report has been submitted'
                    : 'What did you accomplish today? Include completed tasks, blockers, and next steps.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isAlreadySubmitted ? Colors.grey[100] : Colors.grey[50],
                contentPadding: EdgeInsets.all(12),
              ),
            ),
            SizedBox(height: 16),
            if (!isAlreadySubmitted) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _reportController.text.trim().isNotEmpty
                      ? _submitReport
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    padding: EdgeInsets.symmetric(vertical: 14),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: Text(
                    'Submit Report',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '✓ After submitting your report, you\'ll be able to clock out for the day.',
                  style: TextStyle(fontSize: 12, color: Colors.green[700]),
                ),
              ),
            ] else...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700], size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your daily report has been submitted successfully.',
                        style: TextStyle(fontSize: 12, color: Colors.green[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAllCompleteCard() {
    return Card(
      elevation: 4,
      color: Colors.green[50],
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 28),
                SizedBox(width: 12),
                Text(
                  'Ready to Clock Out',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Step 4: Clock out\n\nYou have successfully completed your daily plan and report. You are now ready to clock out for the day.',
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 14,
                height: 1.6,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green[700], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Go to Clock In to scan your barcode and clock out.',
                      style: TextStyle(fontSize: 12, color: Colors.green[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClockedOutCard() {
    return Card(
      elevation: 4,
      color: Colors.grey[100],
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.logout, color: Colors.grey[600], size: 28),
                SizedBox(width: 12),
                Text(
                  'Clocked Out',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'You have successfully completed all tasks and clocked out for the day.\n\nYour daily plan and report have been submitted.',
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
