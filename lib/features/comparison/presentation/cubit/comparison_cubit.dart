
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/comparison_repository.dart';
import '../../domain/comparison_item.dart';

enum ComparisonViewMode {
  table,
  highlighted,
}

class ComparisonState {
  final bool isLoading;
  final List<ComparisonItem> items;
  final ComparisonViewMode viewMode;
  final String? error;
  final bool showComparison;
  final int? selectedItemId;
  final int? ayahId;

  const ComparisonState({
    this.isLoading = false,
    this.items = const [],
    this.viewMode = ComparisonViewMode.table,
    this.error,
    this.showComparison = true,
    this.selectedItemId,
    this.ayahId,
  });

  ComparisonState copyWith({
    bool? isLoading,
    List<ComparisonItem>? items,
    ComparisonViewMode? viewMode,
    String? error,
    bool clearError = false,
    bool? showComparison,
    int? selectedItemId,
    bool clearSelection = false,
    int? ayahId,
    bool clearAyah = false,
  }) {
    return ComparisonState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      viewMode: viewMode ?? this.viewMode,
      error: clearError ? null : (error ?? this.error),
      showComparison: showComparison ?? this.showComparison,
      selectedItemId:
      clearSelection ? null : (selectedItemId ?? this.selectedItemId),
      ayahId: clearAyah ? null : (ayahId ?? this.ayahId),
    );
  }
}

class ComparisonCubit extends Cubit<ComparisonState> {
  final ComparisonRepository repository;

  ComparisonCubit(this.repository) : super(const ComparisonState());

  Future<void> loadApprovedForAyah(int? ayahId) async {
    if (ayahId == null) {
      emit(state.copyWith(
        isLoading: false,
        items: const [],
        clearSelection: true,
        clearAyah: true,
        clearError: true,
      ));
      return;
    }

    emit(state.copyWith(
      isLoading: true,
      ayahId: ayahId,
      items: const [],
      clearSelection: true,
      clearError: true,
    ));

    try {
      final items = await repository.getApprovedItemsForAyah(ayahId);

      emit(state.copyWith(
        isLoading: false,
        items: items,
        selectedItemId: items.isEmpty ? null : items.first.id,
        clearError: true,
      ));
    } catch (e) {
      if (isClosed || state.ayahId != ayahId) return;

      emit(state.copyWith(
        isLoading: false,
        error: 'تعذر تحميل أوجه القراءة المعتمدة: $e',
      ));
    }
  }

  void setViewMode(ComparisonViewMode mode) {
    emit(state.copyWith(viewMode: mode));
  }

  void toggleComparison() {
    emit(state.copyWith(showComparison: !state.showComparison));
  }

  void selectItem(int id) {
    emit(state.copyWith(selectedItemId: id));
  }
}
