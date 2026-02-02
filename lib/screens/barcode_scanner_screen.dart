import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import '../services/clocking_service.dart';
import '../services/sound_service.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final String username;
  final String action; // 'clock_in' or 'clock_out'
  final Function(String) onBarcodeScanned;

  const BarcodeScannerScreen({super.key, 
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
        _performClockAction(code);
      }
    }
  }

  Future<void> _performClockAction(String barcode) async {
    try {
      print('Processing clock action for barcode: $barcode');
      
      // Use ClockingService to handle business logic
      final result = await ClockingService.processClockAction(barcode);
      
      print('Clock action result: $result');
      
      // Play appropriate sound based on result
      if (result.contains('Clocked In')) {
        await SoundService.playClockInSound();
      } else if (result.contains('Clocked Out')) {
        await SoundService.playClockOutSound();
      } else {
        await SoundService.playErrorSound();
      }
      
      // Notify caller (if any) - but don't show additional snackbar
      widget.onBarcodeScanned('');

      // Show success message then navigate directly to Dashboard
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor: result.contains('not submitted') ? Color(0xFFEF4444) : Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      await Future.delayed(Duration(milliseconds: 1500));
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      print('Clock action exception: $e');
      // Play error sound
      await SoundService.playErrorSound();
      _showErrorDialog(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 24),
            ),
            SizedBox(width: 12),
            Text(
              'Clock Action Failed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF374151),
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                isScanning = true;
              });
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Try Again',
              style: TextStyle(
                color: Color(0xFF3B82F6),
                fontWeight: FontWeight.w600,
              ),
            ),
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
