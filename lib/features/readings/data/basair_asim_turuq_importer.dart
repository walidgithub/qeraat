
import 'package:sqflite/sqflite.dart';

class BasairAsimTuruqImporter {
  static Future<Map<String, int>> import(Database db) async {
    return db.transaction((txn) async {
      // البحث عن القارئ عاصم
      final qurras = await txn.query(
        'qurras',
        columns: ['id'],
        where: 'name_ar = ?',
        whereArgs: ['عاصم الكوفي'],
        limit: 1,
      );

      if (qurras.isEmpty) {
        throw StateError('لم يتم العثور على القارئ عاصم الكوفي');
      }

      final qariId = qurras.first['id'] as int;

      // البحث عن المصدر المعتمد
      final sources = await txn.query(
        'sources',
        columns: ['id'],
        where: 'title = ? AND author = ?',
        whereArgs: [
          'النشر في القراءات العشر',
          'شمس الدين أبو الخير ابن الجزري',
        ],
        limit: 1,
      );

      if (sources.isEmpty) {
        throw StateError('لم يتم العثور على مصدر النشر في القراءات العشر');
      }

      final sourceId = sources.first['id'] as int;

      // تعريف المداخل الأربعة مع مرجع كل مدخل
      final entries = [
        {
          'riwaya': 'شعبة',
          'name': 'طريق يحيى بن آدم عن شعبة - النشر ج1 ص147-150',
        },
        {
          'riwaya': 'شعبة',
          'name': 'طريق العليمي عن شعبة - النشر ج1 ص151-152',
        },
        {
          'riwaya': 'حفص',
          'name': 'طريق عبيد بن الصباح عن حفص - النشر ج1 ص152-153',
        },
        {
          'riwaya': 'حفص',
          'name': 'طريق عمرو بن الصباح عن حفص - النشر ج1 ص153-155',
        },
      ];

      int added = 0;
      int existing = 0;

      for (final entry in entries) {
        final riwayaName = entry['riwaya']!;
        final routeName = entry['name']!;

        final riwayat = await txn.query(
          'riwayat',
          columns: ['id'],
          where: 'qari_id = ? AND name_ar = ?',
          whereArgs: [qariId, riwayaName],
          limit: 1,
        );

        if (riwayat.isEmpty) {
          throw StateError('لم يتم العثور على رواية $riwayaName');
        }

        final riwayaId = riwayat.first['id'] as int;

        // منع التكرار
        final routes = await txn.query(
          'turuq',
          columns: ['id'],
          where: 'riwaya_id = ? AND name_ar = ?',
          whereArgs: [riwayaId, routeName],
          limit: 1,
        );

        if (routes.isNotEmpty) {
          existing++;
          continue;
        }

        await txn.insert('turuq', {
          'riwaya_id': riwayaId,
          'name_ar': routeName,
          'source_id': sourceId,
        });

        added++;
      }

      return {
        'added': added,
        'existing': existing,
      };
    });
  }
}
