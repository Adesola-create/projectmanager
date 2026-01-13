import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(await _buildApp());
}

Future<Widget> _buildApp() async {
  final prefs = await SharedPreferences.getInstance();
  final current = prefs.getString('current_user');
  if (current != null && current.isNotEmpty) {
    try {
      final Map<String, dynamic> jsonMap = json.decode(current);
      final emp = Employee.fromJson(jsonMap);
      return ClockingApp(home: DashboardScreen(employee: emp));
    } catch (e) {
      // fall through to login
    }
  }
  return ClockingApp();
}

class ClockingApp extends StatelessWidget {
  final Widget? home;
  const ClockingApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee Clocking System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: home ?? LoginScreen(),
    );
  }
}
