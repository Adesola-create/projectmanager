import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import 'barcode_scanner_screen.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/sound_service.dart';

class ClockingScreen extends StatefulWidget {
  final Employee employee;

  const ClockingScreen({super.key, required this.employee});

  @override
  _ClockingScreenState createState() => _ClockingScreenState();
}

class _ClockingScreenState extends State<ClockingScreen> {
  void _openBarcodeScanner(String action) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerScreen(
          username: '',
          action: action,
          onBarcodeScanned: (barcode) {
            _showClockResult(barcode, action);
          },
        ),
      ),
    );
  }

  void _showClockResult(String barcode, String action) {
    // Only show result if barcode is not empty (prevents double snackbar)
    if (barcode.isNotEmpty) {
      _handleClockResult(barcode, action);
    }
  }

  Future<void> _handleClockResult(String barcode, String action) async {
    final employee = ApiService.findEmployeeByBarcode(barcode);
    String actionText = 'scanned';

    if (action == 'auto') {
      if (employee != null) {
        final db = DatabaseService();
        final entry = await db.getTodayEntry(employee.id);
        if (entry != null && entry.clockOut == null) {
          actionText = 'clocked out';
          await SoundService.playClockOutSound();
        } else {
          actionText = 'clocked in';
          await SoundService.playClockInSound();
        }
      } else {
        actionText = 'scanned';
        await SoundService.playErrorSound();
      }
    } else {
      actionText = action == 'clock_in' ? 'clocked in' : 'clocked out';
      if (action == 'clock_in') {
        await SoundService.playClockInSound();
      } else {
        await SoundService.playClockOutSound();
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${employee?.email ?? 'Employee'} $actionText successfully!',
          ),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildScannerCard(),
                  SizedBox(height: 24),
                  _buildInstructionsCard(),
                ],
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
              color: Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF3B82F6).withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Employee Clock-In',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('HH:mm').format(DateTime.now()),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                DateFormat('MMM dd, yyyy').format(DateTime.now()),
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScannerCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Color(0xFF3B82F6).withOpacity(0.2), width: 2),
            ),
            child: Icon(
              Icons.qr_code_scanner,
              size: 60,
              color: Color(0xFF3B82F6),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Scan Employee Badge',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            'Hold the employee badge steady and ensure it\'s clean and flat for best results',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => _openBarcodeScanner('clock_in'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Open Scanner',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFFE2E8F0)),
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
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.info_outline, color: Color(0xFF10B981), size: 24),
              ),
              SizedBox(width: 16),
              Text(
                'Instructions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildInstructionItem(
            '1',
            'Position Badge',
            'Hold the employee badge 6-8 inches from the camera',
          ),
          SizedBox(height: 16),
          _buildInstructionItem(
            '2',
            'Ensure Good Lighting',
            'Make sure the barcode is well-lit and clearly visible',
          ),
          SizedBox(height: 16),
          _buildInstructionItem(
            '3',
            'Keep Steady',
            'Hold the badge steady until the scan completes',
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Color(0xFF3B82F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
