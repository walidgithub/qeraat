
import '../../../core/database/app_database.dart';
import '../domain/comparison_item.dart';

class ComparisonRepository {
  final AppDatabase database;

  ComparisonRepository(this.database);

  Future<List<ComparisonItem>> getDemoItems() async {
    final rows = await database.getDemoItems();

    return rows
        .map((row) => ComparisonItem.fromMap(row))
        .toList(growable: false);
  }
}
