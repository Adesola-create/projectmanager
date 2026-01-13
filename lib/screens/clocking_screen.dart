import 'package:flutter/material.dart';
import '../models/user.dart';
import 'barcode_scanner_screen.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import 'dashboard_screen.dart';

class ClockingScreen extends StatefulWidget {
  final Employee employee;

  ClockingScreen({required this.employee});

  @override
  _ClockingScreenState createState() => _ClockingScreenState();
}

class _ClockingScreenState extends State<ClockingScreen> {
  void _openBarcodeScanner(String action) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerScreen(
          username: '', // Allow any user for clocking others
          action: action,
          onBarcodeScanned: (barcode) {
            _showClockResult(barcode, action);
          },
        ),
      ),
    );
  }

  bool _scannerOpened = false;

  void _showClockResult(String barcode, String action) {
    _handleClockResult(barcode, action);
  }

  Future<void> _handleClockResult(String barcode, String action) async {
    final employee = ApiService.findEmployeeByBarcode(barcode);
    String actionText = 'scanned';

    if (action == 'auto') {
      if (employee != null) {
        final db = DatabaseService();
        final entry = await db.getTodayEntry(employee.id);
        // if there's a today entry without clockOut -> perform clock out, else clock in
        if (entry != null && entry.clockOut == null) {
          actionText = 'clocked out';
        } else {
          actionText = 'clocked in';
        }
      } else {
        actionText = 'scanned';
      }
    } else {
      actionText = action == 'clock_in' ? 'clocked in' : 'clocked out';
    }

    // keep minimal: let scanner screen handle navigation to dashboard
    // show a short success message if still visible
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${employee?.email ?? 'Employee'} $actionText successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // When screen first builds, open scanner automatically once
    if (!_scannerOpened) {
      _scannerOpened = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openBarcodeScanner('auto'),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Clock Employees'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Container(),
    );
  }
}
