import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/phase.dart';
import '../models/user.dart';

class CreateTaskScreen extends StatefulWidget {
  final int projectId;
  final Phase phase;
  final Employee employee;
  const CreateTaskScreen({super.key, 
    required this.projectId,
    required this.phase,
    required this.employee,
  });

  @override
  _CreateTaskScreenState createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _assigneeCtrl = TextEditingController();
  final _dueCtrl = TextEditingController();
  final DatabaseService _db = DatabaseService();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await _db.createTask({
      'projectId': widget.projectId,
      'phaseId': widget.phase.id,
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'assigneeId': widget.employee.id,
      'dueDate': _dueCtrl.text.trim(),
      'status': 'open',
      'progress': 0,
    });
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Task')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create Task',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Task name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter name' : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _descCtrl,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _dueCtrl,
                    decoration: InputDecoration(
                      labelText: 'Due date (YYYY-MM-DD)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('Create Task'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
