
import 'package:sqflite/sqflite.dart';

class BasairSourcesImporter {
  static Future<bool> importMainSource(Database db) async {
    const title = 'النشر في القراءات العشر';
    const author = 'شمس الدين أبو الخير ابن الجزري';
    const edition =
        'تحقيق علي محمد الضباع، المطبعة التجارية الكبرى، '
        'تصوير دار الكتاب العلمية، جزآن';

    final existing = await db.query(
      'sources',
      columns: ['id'],
      where: 'title = ? AND author = ? AND edition = ?',
      whereArgs: [title, author, edition],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      return false;
    }

    await db.insert('sources', {
      'title': title,
      'author': author,
      'edition': edition,
      'page_reference': null,
      'review_status': 'pending',
    });

    return true;
  }
}
