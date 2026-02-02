import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import '../models/clock_entry.dart';
import '../models/user.dart';

class ClockingHistoryScreen extends StatefulWidget {
  final Employee employee;

  const ClockingHistoryScreen({super.key, required this.employee});

  @override
  _ClockingHistoryScreenState createState() => _ClockingHistoryScreenState();
}

class _ClockingHistoryScreenState extends State<ClockingHistoryScreen> {
  List<ClockEntry> _history = [];
  List<ClockEntry> _filteredHistory = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  final DatabaseService _db = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      // First try to fetch from API
      final apiResponse = await ApiService.getClockingHistory(
        widget.employee.canClockOthers ? null : widget.employee.id
      );
      
      print('Clocking History API Response:');
      print('Success: ${apiResponse['success']}');
      print('Data: ${apiResponse['data']}');
      
      if (apiResponse['success'] == true && apiResponse['data'] != null) {
        // Convert API data to ClockEntry objects and save to database
        final List<dynamic> apiData = apiResponse['data'];
        for (final item in apiData) {
          final entry = ClockEntry(
            id: item['id'],
            employeeId: item['employee_id'],
            employeeName: item['employee_name'] ?? 'Unknown',
            clockIn: DateTime.parse(item['clock_in']),
            clockOut: item['clock_out'] != null ? DateTime.parse(item['clock_out']) : null,
            dailyPlan: item['daily_plan'],
            dailyReport: item['daily_report'],
            synced: true,
            status: item['status'] ?? 'active',
          );
          
          // Insert or update in database
          try {
            await _db.insertClockEntry(entry);
          } catch (e) {
            // If insert fails (duplicate), try update
            await _db.updateClockEntry(entry);
          }
        }
      }
      
      // Load from database (now contains API data)
      List<ClockEntry> history;
      if (widget.employee.canClockOthers) {
        history = await _db.getAllEntries();
      } else {
        history = await _db.getEntriesForEmployee(widget.employee.id);
      }

      setState(() {
        _history = history;
        _filteredHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      print('History load error: $e');
      // Fallback to database only
      List<ClockEntry> history;
      if (widget.employee.canClockOthers) {
        history = await _db.getAllEntries();
      } else {
        history = await _db.getEntriesForEmployee(widget.employee.id);
      }
      
      setState(() {
        _history = history;
        _filteredHistory = history;
        _isLoading = false;
      });
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      switch (filter) {
        case 'Completed':
          _filteredHistory = _history.where((h) => h.clockOut != null).toList();
          break;
        case 'In Progress':
          _filteredHistory = _history.where((h) => h.clockOut == null).toList();
          break;
        case 'Synced':
          _filteredHistory = _history.where((h) => h.synced == true).toList();
          break;
        case 'Pending Sync':
          _filteredHistory = _history.where((h) => h.synced != true).toList();
          break;
        default:
          _filteredHistory = _history;
      }
    });
  }

  String _calculateDuration(DateTime? clockIn, DateTime? clockOut) {
    if (clockIn == null || clockOut == null) return 'In Progress';

    final duration = clockOut.difference(clockIn);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(),
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                  )
                : _filteredHistory.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadHistory,
                    color: Color(0xFF3B82F6),
                    child: ListView.builder(
                      padding: EdgeInsets.all(20),
                      itemCount: _filteredHistory.length,
                      itemBuilder: (context, index) {
                        final record = _filteredHistory[index];
                        return _buildHistoryCard(record);
                      },
                    ),
                  ),
          ),
        ],
      ),
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
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color(0xFF8B5CF6),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF8B5CF6).withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.history, color: Colors.white, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.employee.canClockOthers
                      ? 'All Clocking History'
                      : 'My Clocking History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  '${_filteredHistory.length} records',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: _applyFilter,
            itemBuilder: (context) => [
              PopupMenuItem(value: 'All', child: Text('All Records')),
              PopupMenuItem(value: 'Completed', child: Text('Completed')),
              PopupMenuItem(value: 'In Progress', child: Text('In Progress')),
              PopupMenuItem(value: 'Synced', child: Text('Synced')),
              PopupMenuItem(value: 'Pending Sync', child: Text('Pending Sync')),
            ],
            icon: Icon(Icons.filter_list, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.filter_list, color: Color(0xFF3B82F6), size: 16),
                SizedBox(width: 6),
                Text(
                  _selectedFilter,
                  style: TextStyle(
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.history,
              size: 40,
              color: Color(0xFF8B5CF6),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'No records found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Clocking history will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(ClockEntry record) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.employeeName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy').format(record.clockIn),
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: record.clockOut != null
                          ? Color(0xFF10B981).withOpacity(0.1)
                          : Color(0xFFF59E0B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      record.clockOut != null ? 'Complete' : 'In Progress',
                      style: TextStyle(
                        color: record.clockOut != null
                            ? Color(0xFF10B981)
                            : Color(0xFFF59E0B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    record.synced == true ? Icons.cloud_done : Icons.cloud_off,
                    color: record.synced == true
                        ? Color(0xFF10B981)
                        : Color(0xFF64748B),
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.login,
                        color: Color(0xFF10B981),
                        size: 18,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Clock In: ${DateFormat('h:mm a').format(record.clockIn)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
                if (record.clockOut != null) ...[
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(0xFFEF4444).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.logout,
                          color: Color(0xFFEF4444),
                          size: 18,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Clock Out: ${DateFormat('h:mm a').format(record.clockOut!)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.timer,
                        color: Color(0xFF3B82F6),
                        size: 18,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Duration: ${_calculateDuration(record.clockIn, record.clockOut)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}