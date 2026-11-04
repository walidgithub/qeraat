
import 'package:sqflite/sqflite.dart';

/// استيراد القراء العشرة والرواة العشرين.
///
/// آمن عند تكرار التشغيل:
/// - لا يحذف أي بيانات.
/// - لا يستبدل السجلات الموجودة.
/// - لا يغيّر إصدار قاعدة البيانات.
/// - لا ينشئ جداول جديدة.
/// - لا يضيف أوجه قراءة غير موثقة.
class BasairPhase1Importer {
  BasairPhase1Importer._();

  static const List<Map<String, Object>> _qurras = [
    {'name_ar': 'نافع المدني', 'order_no': 1},
    {'name_ar': 'ابن كثير المكي', 'order_no': 2},
    {'name_ar': 'أبو عمرو البصري', 'order_no': 3},
    {'name_ar': 'ابن عامر الشامي', 'order_no': 4},
    {'name_ar': 'عاصم الكوفي', 'order_no': 5},
    {'name_ar': 'حمزة الكوفي', 'order_no': 6},
    {'name_ar': 'الكسائي الكوفي', 'order_no': 7},
    {'name_ar': 'أبو جعفر المدني', 'order_no': 8},
    {'name_ar': 'يعقوب الحضرمي', 'order_no': 9},
    {'name_ar': 'خلف العاشر', 'order_no': 10},
  ];

  /// الراوي مرتبط بإمامه من خلال اسم القارئ.
  /// تكرار اسم الدوري مقصود؛ فهو راوٍ عن أبي عمرو
  /// وراوٍ عن الكسائي.
  static const List<Map<String, String>> _riwayat = [
    {'qari': 'نافع المدني', 'name': 'قالون'},
    {'qari': 'نافع المدني', 'name': 'ورش'},

    {'qari': 'ابن كثير المكي', 'name': 'البزي'},
    {'qari': 'ابن كثير المكي', 'name': 'قنبل'},

    {'qari': 'أبو عمرو البصري', 'name': 'الدوري'},
    {'qari': 'أبو عمرو البصري', 'name': 'السوسي'},

    {'qari': 'ابن عامر الشامي', 'name': 'هشام'},
    {'qari': 'ابن عامر الشامي', 'name': 'ابن ذكوان'},

    {'qari': 'عاصم الكوفي', 'name': 'شعبة'},
    {'qari': 'عاصم الكوفي', 'name': 'حفص'},

    {'qari': 'حمزة الكوفي', 'name': 'خلف'},
    {'qari': 'حمزة الكوفي', 'name': 'خلاد'},

    {'qari': 'الكسائي الكوفي', 'name': 'أبو الحارث'},
    {'qari': 'الكسائي الكوفي', 'name': 'الدوري'},

    {'qari': 'أبو جعفر المدني', 'name': 'ابن وردان'},
    {'qari': 'أبو جعفر المدني', 'name': 'ابن جماز'},

    {'qari': 'يعقوب الحضرمي', 'name': 'رويس'},
    {'qari': 'يعقوب الحضرمي', 'name': 'روح'},

    {'qari': 'خلف العاشر', 'name': 'إسحاق'},
    {'qari': 'خلف العاشر', 'name': 'إدريس'},
  ];

  /// تنفيذ الاستيراد داخل Transaction واحدة.
  static Future<Map<String, int>> importInto(
      Database db,
      ) async {
    int qurrasAdded = 0;
    int riwayatAdded = 0;

    await db.transaction((txn) async {
      // أولاً: إضافة القراء.
      for (final qari in _qurras) {
        final existing = await txn.query(
          'qurras',
          columns: ['id'],
          where: 'name_ar = ?',
          whereArgs: [qari['name_ar']],
          limit: 1,
        );

        if (existing.isNotEmpty) continue;

        await txn.insert('qurras', qari);
        qurrasAdded++;
      }

      // ثانياً: إضافة الرواة وربطهم بمعرف القارئ الفعلي.
      for (final riwaya in _riwayat) {
        final qariRows = await txn.query(
          'qurras',
          columns: ['id'],
          where: 'name_ar = ?',
          whereArgs: [riwaya['qari']],
          limit: 1,
        );

        if (qariRows.isEmpty) {
          throw StateError(
            'لم يتم العثور على القارئ: ${riwaya['qari']}',
          );
        }

        final qariId = qariRows.first['id'];

        final existing = await txn.query(
          'riwayat',
          columns: ['id'],
          where: 'qari_id = ? AND name_ar = ?',
          whereArgs: [qariId, riwaya['name']],
          limit: 1,
        );

        if (existing.isNotEmpty) continue;

        await txn.insert('riwayat', {
          'qari_id': qariId,
          'name_ar': riwaya['name'],
        });

        riwayatAdded++;
      }
    });

    return {
      'qurras_added': qurrasAdded,
      'riwayat_added': riwayatAdded,
    };
  }
}
