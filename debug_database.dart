import 'package:flutter/material.dart';
import 'lib/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final db = DatabaseService();
  
  // Test database operations
  print('Testing database operations...');
  
  // Test saving a plan
  await db.saveDailyPlan(1, 'Test plan for today');
  print('Plan saved');
  
  // Test retrieving the plan
  final plan = await db.getTodayPlan(1);
  print('Retrieved plan: $plan');
  
  // Test getting all entries
  final entries = await db.getAllEntries();
  print('Total entries: ${entries.length}');
  
  // Test getting all plans
  final database = await db.database;
  final planMaps = await database.query('daily_plans');
  print('Total plans: ${planMaps.length}');
  for (var planMap in planMaps) {
    print('Plan: $planMap');
  }
}