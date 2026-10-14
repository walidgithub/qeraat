import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/comparison_item.dart';
import '../../data/comparison_repository.dart';

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

  const ComparisonState({
    this.isLoading = false,
    this.items = const [],
    this.viewMode = ComparisonViewMode.table,
    this.error,
    this.showComparison = true,
    this.selectedItemId,
  });

  ComparisonState copyWith({
    bool? isLoading,
    List<ComparisonItem>? items,
    ComparisonViewMode? viewMode,
    String? error,
    bool clearError = false,
    bool? showComparison,
    int? selectedItemId,
  }) {
    return ComparisonState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      viewMode: viewMode ?? this.viewMode,
      error: clearError ? null : (error ?? this.error),
      showComparison: showComparison ?? this.showComparison,
      selectedItemId: selectedItemId ?? this.selectedItemId,
    );
  }
}

class ComparisonCubit extends Cubit<ComparisonState> {
  final ComparisonRepository repository;

  ComparisonCubit(this.repository) : super(const ComparisonState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final items = await repository.getDemoItems();

      emit(state.copyWith(
        isLoading: false,
        items: items,
        selectedItemId:
        items.isNotEmpty ? items.first.id : null,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  void setViewMode(ComparisonViewMode mode) {
    emit(state.copyWith(viewMode: mode));
  }

  void toggleComparison() {
    emit(state.copyWith(
      showComparison: !state.showComparison,
    ));
  }

  void selectItem(int id) {
    emit(state.copyWith(selectedItemId: id));
  }
}