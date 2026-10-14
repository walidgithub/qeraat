class MushafReaderState {
  final int? surahId;
  final int? ayahId;
  final int ayahNumber;
  final String? surahName;
  final String? ayahText;
  final bool isLoading;
  final String? error;

  const MushafReaderState({
    this.surahId,
    this.ayahId,
    this.ayahNumber = 1,
    this.surahName,
    this.ayahText,
    this.isLoading = false,
    this.error,
  });

  MushafReaderState copyWith({
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