
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/database/app_database.dart';
import '../../data/ayah_repository.dart';
import 'mushaf_reader_state.dart';

class MushafReaderCubit extends Cubit<MushafReaderState> {
  final AyahRepository repository;

  int _surahRequestId = 0;

  MushafReaderCubit(AppDatabase database)
      : repository = AyahRepository(database),
        super(const MushafReaderState());

  Future<void> loadSurahs() async {
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
      ),
    );

    try {
      final surahs = await repository.getSurahs();

      if (isClosed) return;

      emit(
        state.copyWith(
          surahs: surahs,
          isLoading: false,
          clearError: true,
        ),
      );

      if (surahs.isNotEmpty) {
        await selectSurah(surahs.first);
      }
    } catch (e) {
      if (isClosed) return;

      emit(
        state.copyWith(
          isLoading: false,
          error: 'تعذر تحميل السور: $e',
        ),
      );
    }
  }

  Future<void> selectSurah(
      Map<String, Object?> surah, {
        int initialAyahNumber = 1,
      }) async {
    final requestId = ++_surahRequestId;

    final id = (surah['id'] as num).toInt();
    final name = surah['name_ar'] as String;

    emit(
      state.copyWith(
        surahId: id,
        surahName: name,
        ayahs: const [],
        isLoading: true,
        clearAyah: true,
        clearError: true,
      ),
    );

    try {
      final ayahs = await repository.getAyahs(id);

      // تجاهل نتائج أي سورة سبق اختيارها.
      if (isClosed || requestId != _surahRequestId) return;

      if (ayahs.isEmpty) {
        emit(
          state.copyWith(
            ayahs: const [],
            isLoading: false,
            clearAyah: true,
            clearError: true,
          ),
        );
        return;
      }

      final index = ayahs.indexWhere(
            (ayah) =>
        (ayah['ayah_number'] as num).toInt() == initialAyahNumber,
      );

      final selectedIndex = index >= 0 ? index : 0;
      final ayah = ayahs[selectedIndex];

      emit(
        state.copyWith(
          ayahs: ayahs,
          ayahId: (ayah['id'] as num).toInt(),
          ayahNumber: (ayah['ayah_number'] as num).toInt(),
          ayahText: ayah['uthmani_text'] as String,
          isLoading: false,
          clearError: true,
        ),
      );
    } catch (e) {
      if (isClosed || requestId != _surahRequestId) return;

      emit(
        state.copyWith(
          isLoading: false,
          error: 'تعذر تحميل الآيات: $e',
        ),
      );
    }
  }

  Future<void> selectAyah(Map<String, Object?> ayah) async {
    if (isClosed) return;

    emit(
      state.copyWith(
        ayahId: (ayah['id'] as num).toInt(),
        ayahNumber: (ayah['ayah_number'] as num).toInt(),
        ayahText: ayah['uthmani_text'] as String,
        clearError: true,
      ),
    );
  }

  Future<void> nextAyah() async {
    final index = state.ayahs.indexWhere(
          (ayah) => (ayah['id'] as num).toInt() == state.ayahId,
    );

    if (index < 0 || index + 1 >= state.ayahs.length) {
      return;
    }

    await selectAyah(state.ayahs[index + 1]);
  }

  Future<void> previousAyah() async {
    final index = state.ayahs.indexWhere(
          (ayah) => (ayah['id'] as num).toInt() == state.ayahId,
    );

    if (index <= 0) return;

    await selectAyah(state.ayahs[index - 1]);
  }
}
