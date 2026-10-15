class MushafReaderState {
  final List<Map<String, Object?>> surahs;
  final List<Map<String, Object?>> ayahs;

  final int? surahId;
  final int? ayahId;
  final int ayahNumber;

  final String? surahName;
  final String? ayahText;

  final bool isLoading;
  final String? error;

  const MushafReaderState({
    this.surahs = const [],
    this.ayahs = const [],
    this.surahId,
    this.ayahId,
    this.ayahNumber = 1,
    this.surahName,
    this.ayahText,
    this.isLoading = false,
    this.error,
  });

  MushafReaderState copyWith({
    List<Map<String, Object?>>? surahs,
    List<Map<String, Object?>>? ayahs,
    int? surahId,
    int? ayahId,
    int? ayahNumber,
    String? surahName,
    String? ayahText,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearAyah = false,
  }) {
    return MushafReaderState(
      surahs: surahs ?? this.surahs,
      ayahs: ayahs ?? this.ayahs,
      surahId: surahId ?? this.surahId,
      ayahId: clearAyah ? null : (ayahId ?? this.ayahId),
      ayahNumber: ayahNumber ?? this.ayahNumber,
      surahName: surahName ?? this.surahName,
      ayahText: clearAyah ? null : (ayahText ?? this.ayahText),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}