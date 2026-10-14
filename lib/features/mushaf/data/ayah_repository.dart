import '../../../core/database/app_database.dart';

class AyahRepository {
  final AppDatabase database;

  AyahRepository(this.database);

  Future<List<Map<String, Object?>>> getSurahs() async {
    final db = await database.database;

    return db.query(
      'surahs',
      columns: ['id', 'name_ar', 'ayah_count'],
      orderBy: 'id ASC',
    );
  }

  Future<List<Map<String, Object?>>> getAyahs(int surahId) async {
    final db = await database.database;

    return db.query(
      'ayahs',
      columns: ['id', 'surah_id', 'ayah_number', 'uthmani_text'],
      where: 'surah_id = ?',
      whereArgs: [surahId],
      orderBy: 'ayah_number ASC',
    );
  }

  Future<Map<String, Object?>?> getAyah({
    required int surahId,
    required int ayahNumber,
  }) async {
    final db = await database.database;

    final result = await db.query(
      'ayahs',
      columns: ['id', 'surah_id', 'ayah_number', 'uthmani_text'],
      where: 'surah_id = ? AND ayah_number = ?',
      whereArgs: [surahId, ayahNumber],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return result.first;
  }
}
