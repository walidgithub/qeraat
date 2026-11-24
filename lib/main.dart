
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/database/app_database.dart';

import 'features/readings/data/basair_phase1_importer.dart';
import 'features/readings/data/basair_sources_importer.dart';
import 'features/readings/data/basair_asim_turuq_importer.dart';
import 'features/readings/data/basair_shuba_yahya_importer.dart';
import 'features/readings/data/basair_shuba_alimi_importer.dart';

import 'features/comparison/data/comparison_repository.dart';
import 'features/comparison/presentation/cubit/comparison_cubit.dart';

import 'features/mushaf/presentation/cubit/mushaf_reader_cubit.dart';
import 'features/mushaf/presentation/pages/mushaf_reader_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // فتح قاعدة البيانات الحالية.
  final db = await AppDatabase.instance.database;

  // =========================================
  // 1. استيراد القراء والرواة.
  // =========================================

  final result = await BasairPhase1Importer.importInto(db);

  debugPrint('القراء المضافون: ${result['qurras_added']}');
  debugPrint('الرواة المضافون: ${result['riwayat_added']}');

  // =========================================
  // 2. استيراد المصدر الرئيسي.
  // =========================================

  final sourceAdded =
  await BasairSourcesImporter.importMainSource(db);

  debugPrint(
    sourceAdded
        ? 'تم تسجيل المصدر الرئيسي'
        : 'المصدر الرئيسي مسجل مسبقًا',
  );

  // =========================================
  // 3. عرض بيانات عاصم.
  // =========================================

  final asimData = await db.rawQuery('''
    SELECT
      q.id AS qari_id,
      q.name_ar AS qari_name,
      r.id AS riwaya_id,
      r.name_ar AS riwaya_name
    FROM qurras q
    INNER JOIN riwayat r ON r.qari_id = q.id
    WHERE q.name_ar LIKE '%عاصم%'
    ORDER BY r.id
  ''');

  for (final item in asimData) {
    debugPrint('بيانات عاصم: $item');
  }

  // =========================================
  // 4. استيراد الطرق الرئيسية.
  // =========================================

  final turuqResult =
  await BasairAsimTuruqImporter.import(db);

  debugPrint('الطرق المضافة: ${turuqResult['added']}');
  debugPrint(
    'الطرق الموجودة مسبقًا: ${turuqResult['existing']}',
  );

  // =========================================
  // 5. التأكد من وجود جدول فروع الطرق.
  // =========================================

  final tables = await db.rawQuery(
    "SELECT name FROM sqlite_master "
        "WHERE type = 'table' AND name = 'tariq_nodes'",
  );

  debugPrint(
    'جدول فروع الطرق: ${tables.isNotEmpty ? 'موجود' : 'غير موجود'}',
  );

  final turuq = await db.query('turuq');

  debugPrint('عدد الطرق الحالية: ${turuq.length}');

  // =========================================
  // 6. استيراد فروع شعبة عن يحيى بن آدم.
  // =========================================

  final shubaYahyaResult =
  await BasairShubaYahyaImporter.import(db);

  debugPrint(
    'فروع شعبة عن يحيى المضافة: ${shubaYahyaResult['added']}',
  );

  debugPrint(
    'فروع شعبة عن يحيى الموجودة: ${shubaYahyaResult['existing']}',
  );

  // =========================================
  // 7. استيراد فروع شعبة عن العليمي.
  // =========================================

  final shubaAlimiResult =
  await BasairShubaAlimiImporter.import(db);

  debugPrint(
    'فروع شعبة عن العليمي المضافة: ${shubaAlimiResult['added']}',
  );

  debugPrint(
    'فروع شعبة عن العليمي الموجودة: ${shubaAlimiResult['existing']}',
  );

  await BasairShubaYahyaImporter.debugPrintShubaYahyaTree(db);

  await BasairShubaYahyaImporter
      .importQaffalayiDetails(db);


  // =========================================
  // تشغيل التطبيق.
  // =========================================

  runApp(const BasairQiraatApp());
}

class BasairQiraatApp extends StatelessWidget {
  const BasairQiraatApp({super.key});

  @override
  Widget build(BuildContext context) {
    final database = AppDatabase.instance;

    return MultiBlocProvider(
      providers: [
        BlocProvider<ComparisonCubit>(
          create: (_) => ComparisonCubit(
            ComparisonRepository(database),
          ),
        ),
        BlocProvider<MushafReaderCubit>(
          create: (_) => MushafReaderCubit(database)..loadSurahs(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'بصائر القراءات',
        locale: const Locale('ar'),
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF443182),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF24143D),
            foregroundColor: Colors.white,
            centerTitle: true,
          ),
        ),
        home: const MushafReaderPage(),
      ),
    );
  }
}
