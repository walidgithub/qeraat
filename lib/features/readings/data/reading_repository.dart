import '../../../core/database/app_database.dart';

class ReadingRepository {
  final AppDatabase database;

  ReadingRepository(this.database);

  /// جلب أوجه القراءة التي اجتازت المراجعة
  /// لآية محددة.
  Future<List<Map<String, Object?>>> getApprovedFormsForAyah(
      int ayahId,
      ) async {
    final db = await database.database;

    return db.rawQuery(
      '''
      SELECT
        v.id AS variant_id,
        v.ayah_id,
        v.variant_group,
        v.category,
        v.description,

        vf.id AS form_id,
        vf.label,
        vf.reading_text,
        vf.difference_text,
        vf.notes,

        q.id AS qari_id,
        q.name_ar AS qari_name,

        r.id AS riwayah_id,
        r.name_ar AS riwayah_name,

        t.id AS tariq_id,
        t.name_ar AS tariq_name,

        s.id AS source_id,
        s.title AS source_title,
        s.author AS source_author,
        s.edition AS source_edition,
        s.page_reference AS source_page

      FROM reading_variants v

      INNER JOIN variant_forms vf
        ON vf.variant_id = v.id

      INNER JOIN turuq t
        ON t.id = vf.tariq_id

      INNER JOIN riwayat r
        ON r.id = t.riwaya_id

      INNER JOIN qurras q
        ON q.id = r.qari_id

      INNER JOIN sources s
        ON s.id = v.source_id

      WHERE v.ayah_id = ?
        AND v.review_status = 'approved'
        AND s.review_status = 'approved'

      ORDER BY q.order_no, r.id, t.id
      ''',
      [ayahId],
    );
  }
}