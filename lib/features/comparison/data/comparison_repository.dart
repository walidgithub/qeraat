
import '../../../core/database/app_database.dart';
import '../../readings/data/reading_repository.dart';
import '../domain/comparison_item.dart';

class ComparisonRepository {
  final AppDatabase database;

  late final ReadingRepository _readingRepository =
  ReadingRepository(database);

  ComparisonRepository(this.database);

  Future<List<ComparisonItem>> getApprovedItemsForAyah(
      int ayahId,
      ) async {
    final rows =
    await _readingRepository.getApprovedFormsForAyah(ayahId);

    return rows
        .map((row) => ComparisonItem.fromApprovedRow(row))
        .toList(growable: false);
  }
}
