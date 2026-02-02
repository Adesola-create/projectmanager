import 'package:flutter/material.dart';
import '../services/project_service.dart';

class MemberManagementScreen extends StatefulWidget {
  final int projectId;
  final int callerId;

  const MemberManagementScreen({super.key, required this.projectId, required this.callerId});

  @override
  _MemberManagementScreenState createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends State<MemberManagementScreen> {
  final ProjectService _svc = ProjectService();
  late Future<List<Map<String, dynamic>>> _membersFuture;
  final _empCtrl = TextEditingController();
  String _role = 'member';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _membersFuture = _svc.getMembers(widget.projectId);
  }

  Future<void> _addMember() async {
    final id = int.tryParse(_empCtrl.text.trim());
    if (id == null) return _showError('Enter valid employee id');
    try {
      await _svc.addMember(
        callerId: widget.callerId,
        projectId: widget.projectId,
        employeeId: id,
        role: _role,
      );
      _empCtrl.clear();
      setState(() => _load());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Member added')));
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _removeMember(int employeeId) async {
    try {
      await _svc.removeMember(
        callerId: widget.callerId,
        projectId: widget.projectId,
        employeeId: employeeId,
      );
      setState(() => _load());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Member removed')));
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Members')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _empCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Employee ID',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _role,
                      items: ['member', 'leader', 'supervisor']
                          .map(
                            (r) => DropdownMenuItem(value: r, child: Text(r)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _role = v ?? 'member'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(onPressed: _addMember, child: Text('Add')),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _membersFuture,
                builder: (c, s) {
                  if (s.connectionState != ConnectionState.done) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final members = s.data ?? [];
                  if (members.isEmpty) {
                    return Center(child: Text('No members yet'));
                  }
                  return ListView.separated(
                    itemCount: members.length,
                    separatorBuilder: (_, __) => Divider(),
                    itemBuilder: (context, idx) {
                      final m = members[idx];
                      return ListTile(
                        title: Text('Employee ${m['employeeId']}'),
                        subtitle: Text(m['role'] ?? 'member'),
                        trailing: IconButton(
                          icon: Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () =>
                              _confirmRemove(m['employeeId'] as int),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemove(int employeeId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Remove member'),
        content: Text('Remove employee $employeeId from project?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) _removeMember(employeeId);
  }
}
