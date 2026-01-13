import 'package:flutter/material.dart';
import '../services/project_service.dart';

class AssignTaskScreen extends StatefulWidget {
  final int taskId;
  final int projectId;
  final int callerId;

  AssignTaskScreen({
    required this.taskId,
    required this.projectId,
    required this.callerId,
  });

  @override
  _AssignTaskScreenState createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  final ProjectService _svc = ProjectService();
  late Future<List<Map<String, dynamic>>> _membersFuture;
  int? _selectedEmployee;

  @override
  void initState() {
    super.initState();
    _membersFuture = _svc.getMembers(widget.projectId);
  }

  Future<void> _assign() async {
    if (_selectedEmployee == null) return _showError('Select assignee');
    try {
      await _svc.assignTask(
        callerId: widget.callerId,
        taskId: widget.taskId,
        assigneeId: _selectedEmployee!,
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String m) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Assign Task')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _membersFuture,
          builder: (c, s) {
            if (s.connectionState != ConnectionState.done)
              return Center(child: CircularProgressIndicator());
            final members = s.data ?? [];
            if (members.isEmpty)
              return Center(child: Text('No project members to assign'));
            return Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Text(
                          'Select assignee',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 12),
                        ...members.map(
                          (m) => RadioListTile<int>(
                            value: m['employeeId'] as int,
                            groupValue: _selectedEmployee,
                            title: Text('Employee ${m['employeeId']}'),
                            subtitle: Text(m['role'] ?? 'member'),
                            onChanged: (v) =>
                                setState(() => _selectedEmployee = v),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12),
                ElevatedButton(onPressed: _assign, child: Text('Assign')),
              ],
            );
          },
        ),
      ),
    );
  }
}
