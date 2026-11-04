import 'package:flutter/material.dart';

import 'core/database/app_database.dart';
import 'features/readings/data/basair_phase1_importer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // فتح قاعدة البيانات الحالية
  final db = await AppDatabase.instance.database;

  // استيراد القراء والرواة
  final result = await BasairPhase1Importer.importInto(db);

  debugPrint('القراء المضافون: ${result['qurras_added']}');
  debugPrint('الرواة المضافون: ${result['riwayat_added']}');

  runApp(const MyApp());
}