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
//import 'project_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Employee employee;

  const DashboardScreen({super.key, required this.employee});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _db = DatabaseService();
  final SyncService _sync = SyncService();
  final _planController = TextEditingController();
  final _reportController = TextEditingController();

  ClockEntry? _todayEntry;
  String _planStatus = 'not_submitted';
  String _reportStatus = 'not_submitted';
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

  Future<void> _submitPlan() async {
    if (_planController.text.trim().isNotEmpty && _employeeId != null) {
      await _db.saveDailyPlan(_employeeId!, _planController.text.trim());
      final result = await ApiService.submitReport(
        widget.employee.barcode,
        'plan',
        _planController.text.trim(),
      );
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
    if (_reportController.text.trim().isNotEmpty && _employeeId != null) {
      try {
        // Save to database first
        await _db.saveDailyReport(_employeeId!, _reportController.text.trim());
        
        setState(() {
          _reportStatus = 'submitted';
        });
        
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

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Color(0xFFEF4444)),
            SizedBox(width: 12),
            Text('Sign Out'),
          ],
        ),
        content: Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF3B82F6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Sign Out'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 100),
              child: Column(
                children: [
                  SizedBox(height: 20),
                  _buildWelcomeCard(),
                  // SizedBox(height: 24),
                  // _buildQuickActions(),
                  SizedBox(height: 24),
                  _buildNavigationGrid(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF3B82F6).withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.schedule, color: Colors.white, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TimeTrack Pro',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('HH:mm').format(DateTime.now()),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                DateFormat('MMM dd, yyyy').format(DateTime.now()),
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.person, color: Colors.white, size: 32),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      widget.employee.name.isNotEmpty
                          ? widget.employee.name
                          : widget.employee.email.split('@')[0],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _logout,
                icon: Icon(Icons.logout, color: Colors.white70),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            _getStatusText(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildQuickActions() {
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: _buildQuickActionCard(
  //           'Clock Status',
  //           _getClockStatusText(),
  //           Icons.access_time,
  //           Color(0xFF10B981),
  //           () {},
  //         ),
  //       ),
  //       SizedBox(width: 16),
  //       Expanded(
  //         child: _buildQuickActionCard(
  //           'Today\'s Plan',
  //           _planStatus == 'submitted' ? 'Submitted' : 'Pending',
  //           Icons.assignment,
  //           _planStatus == 'submitted' ? Color(0xFF10B981) : Color(0xFFF59E0B),
  //           () {},
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildQuickActionCard(
    String title,
    String status,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE2E8F0)),
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationGrid() {
    List<Map<String, dynamic>> items = [
      if (widget.employee.canClockOthers) ...[
        {
          'title': 'Clock Employees',
          'subtitle': 'Clock other employees in and out',
          'icon': Icons.access_time,
          'color': Color(0xFF3B82F6),
          'onTap': () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClockingScreen(employee: widget.employee),
                ),
              ),
        },
        {
          'title': 'Users List',
          'subtitle': 'View all employees and barcodes',
          'icon': Icons.people,
          'color': Color(0xFF10B981),
          'onTap': () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UsersListScreen(employee: widget.employee),
                ),
              ),
        },
      ],
      {
        'title': 'My Reports',
        'subtitle': 'Submit daily plan and report',
        'icon': Icons.assignment,
        'color': Color(0xFFF59E0B),
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReportsScreen(employee: widget.employee),
              ),
            ),
      },
      {
        'title': 'Clocking History',
        'subtitle': 'View your clocking records',
        'icon': Icons.history,
        'color': Color(0xFF8B5CF6),
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ClockingHistoryScreen(employee: widget.employee),
              ),
            ),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildNavigationCard(
          item['title'],
          item['subtitle'],
          item['icon'],
          item['color'],
          item['onTap'],
        );
      },
    );
  }

  Widget _buildNavigationCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFFE2E8F0)),
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
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.dashboard, 'Dashboard', true, () {}),
              _buildNavItem(Icons.assignment, 'Reports', false, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportsScreen(employee: widget.employee),
                  ),
                );
              }),
              _buildNavItem(Icons.history, 'History', false, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClockingHistoryScreen(employee: widget.employee),
                  ),
                );
              }),
              if (widget.employee.canClockOthers)
                _buildNavItem(Icons.people, 'Users', false, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UsersListScreen(employee: widget.employee),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Color(0xFF3B82F6).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Color(0xFF3B82F6) : Color(0xFF64748B),
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? Color(0xFF3B82F6) : Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText() {
    if (_todayEntry?.clockOut != null) {
      return 'You\'ve completed your workday. Great job!';
    } else if (_todayEntry?.clockIn != null) {
      return 'You\'re currently clocked in. Keep up the good work!';
    }
    return 'Ready to start your productive day?';
  }

  String _getClockStatusText() {
    if (_todayEntry?.clockOut != null) {
      return 'Clocked Out';
    } else if (_todayEntry?.clockIn != null) {
      return 'Clocked In';
    }
    return 'Not Clocked In';
  }
}
