import 'package:flutter/material.dart';
import 'core/database/app_database.dart';
import 'features/readings/data/basair_phase1_importer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/comparison/data/comparison_repository.dart';
import 'features/comparison/presentation/cubit/comparison_cubit.dart';
import 'features/mushaf/presentation/cubit/mushaf_reader_cubit.dart';
import 'features/mushaf/presentation/pages/mushaf_reader_page.dart';
import 'features/readings/data/basair_sources_importer.dart';
import 'features/readings/data/basair_asim_turuq_importer.dart';
import 'features/readings/data/basair_shuba_yahya_importer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // فتح قاعدة البيانات الحالية
  final db = await AppDatabase.instance.database;

  // استيراد القراء والرواة
  final result = await BasairPhase1Importer.importInto(db);

  debugPrint('القراء المضافون: ${result['qurras_added']}');
  debugPrint('الرواة المضافون: ${result['riwayat_added']}');

  final sourceAdded =
  await BasairSourcesImporter.importMainSource(db);

  debugPrint(
    sourceAdded
        ? 'تم تسجيل المصدر الرئيسي'
        : 'المصدر الرئيسي مسجل مسبقًا',
  );


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

  final turuqResult =
  await BasairAsimTuruqImporter.import(db);

  debugPrint('الطرق المضافة: ${turuqResult['added']}');
  debugPrint('الطرق الموجودة مسبقًا: ${turuqResult['existing']}');

  final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master "
          "WHERE type = 'table' AND name = 'tariq_nodes'"
  );

  debugPrint('جدول فروع الطرق: ${tables.isNotEmpty ? 'موجود' : 'غير موجود'}');

  final turuq = await db.query('turuq');

  debugPrint('عدد الطرق الحالية: ${turuq.length}');

  final shubaResult =
  await BasairShubaYahyaImporter.import(db);

  debugPrint('فروع شعبة المضافة: ${shubaResult['added']}');
  debugPrint('فروع شعبة الموجودة: ${shubaResult['existing']}');

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
          create: (_) => ComparisonCubit(ComparisonRepository(database)),
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
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF443182)),
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