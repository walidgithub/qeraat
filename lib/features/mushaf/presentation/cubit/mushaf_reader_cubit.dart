import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/database/app_database.dart';
import '../../data/ayah_repository.dart';
import 'mushaf_reader_state.dart';

class MushafReaderCubit extends Cubit<MushafReaderState> {
  final AyahRepository repository;

  MushafReaderCubit(AppDatabase database)
      : repository = AyahRepository(database),
        super(const MushafReaderState());

  Future<void> loadSurahs() async {
    emit(state.copyWith(
      isLoading: true,
      clearError: true,
    ));

    try {
      final surahs = await repository.getSurahs();

      emit(state.copyWith(
        surahs: surahs,
        isLoading: false,
        clearError: true,
      ));

      if (surahs.isNotEmpty) {
        await selectSurah(surahs.first);
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'تعذر تحميل السور: $e',
      ));
    }
  }

  Future<void> selectSurah(
      Map<String, Object?> surah, {
        int initialAyahNumber = 1,
      }) async {
    final id = surah['id'] as int;
    final name = surah['name_ar'] as String;

    emit(state.copyWith(
      surahId: id,
      surahName: name,
      ayahs: const [],
      isLoading: true,
      clearAyah: true,
      clearError: true,
    ));

    try {
      final ayahs = await repository.getAyahs(id);

      if (ayahs.isEmpty) {
        emit(state.copyWith(
          ayahs: const [],
          isLoading: false,
          clearAyah: true,
          clearError: true,
        ));
        return;
      }

      final index = ayahs.indexWhere(
            (ayah) =>
        ayah['ayah_number'] == initialAyahNumber,
      );

      final selectedIndex = index >= 0 ? index : 0;
      final ayah = ayahs[selectedIndex];

      emit(state.copyWith(
        ayahs: ayahs,
        ayahId: ayah['id'] as int,
        ayahNumber: ayah['ayah_number'] as int,
        ayahText: ayah['uthmani_text'] as String,
        isLoading: false,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'تعذر تحميل الآيات: $e',
      ));
    }
  }

  Future<void> selectAyah(
      Map<String, Object?> ayah,
      ) async {
    emit(state.copyWith(
      ayahId: ayah['id'] as int,
      ayahNumber: ayah['ayah_number'] as int,
      ayahText: ayah['uthmani_text'] as String,
      clearError: true,
    ));
  }

  Future<void> nextAyah() async {
    final index = state.ayahs.indexWhere(
          (ayah) => ayah['id'] == state.ayahId,
    );

    if (index < 0 || index + 1 >= state.ayahs.length) {
      return;
    }

    await selectAyah(state.ayahs[index + 1]);
  }

  Future<void> previousAyah() async {
    final index = state.ayahs.indexWhere(
          (ayah) => ayah['id'] == state.ayahId,
    );

    if (index <= 0) return;

    await selectAyah(state.ayahs[index - 1]);
  }
}