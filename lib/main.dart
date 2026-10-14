import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/database/app_database.dart';
import 'features/comparison/data/comparison_repository.dart';
import 'features/comparison/presentation/cubit/comparison_cubit.dart';
import 'features/mushaf/presentation/pages/mushaf_reader_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BasairQiraatApp());
}

class BasairQiraatApp extends StatelessWidget {
  const BasairQiraatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: BlocProvider(
        create: (_) => ComparisonCubit(
          ComparisonRepository(AppDatabase.instance),
        )..load(),
        child: const MushafReaderPage(),
      ),
    );
  }
}
