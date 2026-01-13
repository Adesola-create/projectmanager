import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import '../services/clocking_service.dart';
import 'dashboard_screen.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final String username;
  final String action; // 'clock_in' or 'clock_out'
  final Function(String) onBarcodeScanned;

  BarcodeScannerScreen({
    required this.username,
    required this.action,
    required this.onBarcodeScanned,
  });

  @override
  _BarcodeScannerScreenState createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool isScanning = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    _syncUnsentRecords();
  }

  Future<void> _loadEmployees() async {
    // Don't fetch employees again if they're already cached and filtered
    if (ApiService.cachedEmployees.isNotEmpty) {
      return;
    }
    
    final employees = await ClockingService.getLocalEmployees();
    if (employees.isEmpty) {
      // Only fetch if no local employees exist
      final apiEmployees = await ApiService.fetchEmployees();
      await ClockingService.saveEmployeesLocally(apiEmployees);
    } else {
      // Use local employees and update cached list
      ApiService.setCachedEmployees(employees);
    }
  }

  Future<void> _syncUnsentRecords() async {
    await ClockingService.syncUnsentRecords();
  }

  void _handleScan(BarcodeCapture capture) {
    if (!isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          isScanning = false;
        });

        try {
          final employee = ApiService.findEmployeeByBarcode(code);
          if (employee != null) {
            if (widget.username.isEmpty || employee.email == widget.username) {
              _performClockAction(code, employee);
            } else {
              _showErrorDialog('Invalid barcode or employee mismatch.');
            }
          } else {
            _showErrorDialog('Employee not found.');
          }
        } catch (e) {
          _showErrorDialog('Employee not found. Please try again.');
        }
      }
    }
  }

  Future<void> _performClockAction(String barcode, dynamic employee) async {
    try {
      final message = await ClockingService.processClockAction(barcode);
      // Notify caller (if any)
      widget.onBarcodeScanned(barcode);

      // Show success message then navigate directly to Dashboard
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );

      await Future.delayed(Duration(milliseconds: 600));
      // Return to the original logged-in Dashboard by popping back to the first route
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      String errorMessage = e.toString();

      // Extract the meaningful message from the exception
      if (errorMessage.contains('Daily plan not submitted')) {
        _showBlockingErrorDialog(
          'Cannot Clock Out',
          'You must submit your daily plan before you can clock out.\n\nPlease complete your daily plan in the Reports screen.',
        );
      } else if (errorMessage.contains('Daily report not submitted')) {
        _showBlockingErrorDialog(
          'Cannot Clock Out',
          'You must submit your daily report before you can clock out.\n\nPlease complete your daily report in the Reports screen.',
        );
      } else {
        _showErrorDialog('Clock action failed: $errorMessage');
      }
    }
  }

  void _showBlockingErrorDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                isScanning = true;
              });
            },
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                isScanning = true;
              });
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Scan to ${widget.action == 'clock_in' ? 'Clock In' : 'Clock Out'}',
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(Icons.qr_code_scanner, size: 60, color: Colors.blue[600]),
                SizedBox(height: 16),
                Text(
                  'Scan your barcode to ${widget.action == 'clock_in' ? 'clock in' : 'clock out'}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: MobileScanner(
                  controller: controller,
                  onDetect: _handleScan,
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(20),
            child: Text(
              'Ensure good lighting for better scanning',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
