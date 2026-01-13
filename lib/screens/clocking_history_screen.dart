import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/clocking_service.dart';
import '../models/clocking_history.dart';
import '../models/user.dart';

class ClockingHistoryScreen extends StatefulWidget {
  final Employee employee;

  ClockingHistoryScreen({required this.employee});

  @override
  _ClockingHistoryScreenState createState() => _ClockingHistoryScreenState();
}

class _ClockingHistoryScreenState extends State<ClockingHistoryScreen> {
  List<ClockingHistory> _history = [];
  List<ClockingHistory> _filteredHistory = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  List<ClockingHistory> _allHistory = [];
  int? _selectedUserId;
  String? _selectedUserName;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await ClockingService.getClockingHistory();
      history.sort((a, b) => b.date.compareTo(a.date));
      // Save full list for manager-side filtering
      _allHistory = history;

      // If the current user cannot clock others, restrict visible history
      List<ClockingHistory> visible = history;
      if (!widget.employee.canClockOthers) {
        visible = history
            .where(
              (h) =>
                  h.id == widget.employee.id ||
                  h.barcode == widget.employee.barcode,
            )
            .toList();
      }

      setState(() {
        _history = visible;
        _filteredHistory = visible;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      switch (filter) {
        case 'Completed':
          _filteredHistory = _history.where((h) => h.timeout != null).toList();
          break;
        case 'In Progress':
          _filteredHistory = _history.where((h) => h.timeout == null).toList();
          break;
        case 'Synced':
          _filteredHistory = _history.where((h) => h.sentstatus).toList();
          break;
        case 'Pending Sync':
          _filteredHistory = _history.where((h) => !h.sentstatus).toList();
          break;
        default:
          _filteredHistory = _history;
      }
    });
  }

  String _calculateDuration(String? timein, String? timeout) {
    if (timein == null || timeout == null) return 'In Progress';

    try {
      final timeInParts = timein.split(':');
      final timeOutParts = timeout.split(':');

      final timeInMinutes =
          int.parse(timeInParts[0]) * 60 + int.parse(timeInParts[1]);
      final timeOutMinutes =
          int.parse(timeOutParts[0]) * 60 + int.parse(timeOutParts[1]);

      final durationMinutes = timeOutMinutes - timeInMinutes;
      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;

      return '${hours}h ${minutes}m';
    } catch (e) {
      return 'Invalid';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedUserId != null
              ? 'History: ${_selectedUserName ?? ''}'
              : (widget.employee.canClockOthers
                    ? 'All Clocking History'
                    : 'My Clocking History'),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          if (_selectedUserId != null)
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _selectedUserId = null;
                  _selectedUserName = null;
                  // restore visible list depending on permission
                  if (widget.employee.canClockOthers) {
                    _filteredHistory = List.from(_allHistory);
                  } else {
                    _filteredHistory = _allHistory
                        .where(
                          (h) =>
                              h.id == widget.employee.id ||
                              h.barcode == widget.employee.barcode,
                        )
                        .toList();
                  }
                });
              },
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
            icon: Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Icon(Icons.filter_list, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text(
                  'Filter: $_selectedFilter',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Spacer(),
                Text(
                  '${_filteredHistory.length} records',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No records found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _filteredHistory.length,
                    itemBuilder: (context, index) {
                      final record = _filteredHistory[index];
                      return InkWell(
                        onTap: () {
                          if (widget.employee.canClockOthers) {
                            setState(() {
                              _selectedUserId = record.id;
                              _selectedUserName = record.name;
                              _filteredHistory = _allHistory
                                  .where(
                                    (h) =>
                                        h.id == record.id ||
                                        h.barcode == record.barcode,
                                  )
                                  .toList();
                            });
                          }
                        },
                        child: Card(
                          margin: EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            record.name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Barcode: ${record.barcode}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            DateFormat('MMM dd, yyyy').format(
                                              DateTime.parse(record.date),
                                            ),
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: record.timeout != null
                                                ? Colors.green
                                                : Colors.orange,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            record.timeout != null
                                                ? 'Complete'
                                                : 'In Progress',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          record.sentstatus
                                              ? Icons.cloud_done
                                              : Icons.cloud_off,
                                          color: record.sentstatus
                                              ? Colors.green
                                              : Colors.grey,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                if (record.timein != null)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.login,
                                        color: Colors.green,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Clock In: ${record.timein}'),
                                    ],
                                  ),
                                if (record.timeout != null) ...[
                                  SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.logout,
                                        color: Colors.red,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Clock Out: ${record.timeout}'),
                                    ],
                                  ),
                                ],
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.timer,
                                      color: Colors.blue,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Duration: ${_calculateDuration(record.timein, record.timeout)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
