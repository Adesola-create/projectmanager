import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class UsersListScreen extends StatefulWidget {
  @override
  _UsersListScreenState createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  List<Employee> _employees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final employees = await ApiService.fetchEmployees();
      setState(() {
        _employees = employees;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Users List'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _employees.length,
              itemBuilder: (context, index) {
                final employee = _employees[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[600],
                      child: Text(
                        (employee.name.isNotEmpty
                                ? employee.name[0]
                                : employee.email[0])
                            .toUpperCase(),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      employee.name.isNotEmpty ? employee.name : employee.email,
                    ),
                    subtitle: Text(
                      '${employee.email} • Barcode: ${employee.barcode}',
                    ),
                    trailing: employee.canClockOthers
                        ? Icon(Icons.admin_panel_settings, color: Colors.orange)
                        : null,
                  ),
                );
              },
            ),
    );
  }
}
