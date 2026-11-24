
import 'package:sqflite/sqflite.dart';

class BasairShubaAlimiImporter {
  static Future<Map<String, int>> import(Database db) async {
    return db.transaction((txn) async {
      final riwayat = await txn.rawQuery(
        '''
        SELECT riwayat.id
        FROM riwayat
        INNER JOIN qurras ON qurras.id = riwayat.qari_id
        WHERE qurras.name_ar = ?
          AND riwayat.name_ar = ?
        LIMIT 1
        ''',
        ['عاصم الكوفي', 'شعبة'],
      );

      if (riwayat.isEmpty) {
        throw StateError('لم يتم العثور على رواية شعبة');
      }

      final riwayaId = riwayat.first['id'] as int;

      final turuq = await txn.query(
        'turuq',
        where: 'riwaya_id = ? AND name_ar LIKE ?',
        whereArgs: [
          riwayaId,
          'طريق العليمي عن شعبة%',
        ],
        limit: 1,
      );

      if (turuq.isEmpty) {
        throw StateError('لم يتم العثور على طريق العليمي عن شعبة');
      }

      final turuqId = turuq.first['id'] as int;

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
        throw StateError('لم يتم العثور على مصدر النشر');
      }

      final sourceId = sources.first['id'] as int;

      int added = 0;
      int existing = 0;

      Future<int> ensureNode({
        required int? parentId,
        required String name,
        required String type,
        required int pageStart,
        required int pageEnd,
        required int sortOrder,
        String? notes,
      }) async {
        final whereClause = parentId == null
            ? 'turuq_id = ? AND parent_id IS NULL AND name_ar = ?'
            : 'turuq_id = ? AND parent_id = ? AND name_ar = ?';

        final whereArguments = parentId == null
            ? [turuqId, name]
            : [turuqId, parentId, name];

        final found = await txn.query(
          'tariq_nodes',
          columns: ['id'],
          where: whereClause,
          whereArgs: whereArguments,
          limit: 1,
        );

        if (found.isNotEmpty) {
          existing++;
          return found.first['id'] as int;
        }

        final id = await txn.insert('tariq_nodes', {
          'turuq_id': turuqId,
          'parent_id': parentId,
          'name_ar': name,
          'node_type': type,
          'source_id': sourceId,
          'volume': 1,
          'page_start': pageStart,
          'page_end': pageEnd,
          'sort_order': sortOrder,
          'review_status': 'pending',
          'notes': notes,
        });

        added++;
        return id;
      }

      // العليمي عن شعبة.
      final alimiId = await ensureNode(
        parentId: null,
        name: 'يحيى بن محمد العليمي عن شعبة',
        type: 'transmitter',
        pageStart: 150,
        pageEnd: 151,
        sortOrder: 1,
        notes: 'للعليمي ثمانية عشر طريقاً: خمسة عشر من طريق ابن خليع وثلاثة من طريق الرزاز. النشر ج1 ص150-151.',
      );

      // ==========================================
      // أولاً: ابن خليع - عشرة مسارات رئيسية.
      // ==========================================

      final ibnKhulayiId = await ensureNode(
        parentId: alimiId,
        name: 'طريق ابن خليع',
        type: 'branch',
        pageStart: 150,
        pageEnd: 151,
        sortOrder: 1,
        notes: 'ذكر ابن الجزري لابن خليع عشرة مسارات رئيسية، مجموعها خمسة عشر طريقاً. النشر ج1 ص150-151.',
      );

      final ibnKhulayiRoutes = [
        {
          'name': 'طريق الحمامي',
          'start': 150,
          'end': 150,
          'notes': 'الأولى عن ابن خليع، ولها ستة طرق. النشر ج1 ص150.',
        },
        {
          'name': 'طريق الخراساني',
          'start': 150,
          'end': 150,
          'notes': 'الثانية عن ابن خليع. النشر ج1 ص150.',
        },
        {
          'name': 'طريق ابن شاذان',
          'start': 150,
          'end': 150,
          'notes': 'الثالثة عن ابن خليع. النشر ج1 ص150.',
        },
        {
          'name': 'طريق السوسنجردي',
          'start': 150,
          'end': 150,
          'notes': 'الرابعة عن ابن خليع. النشر ج1 ص150.',
        },
        {
          'name': 'طريق البلدي',
          'start': 150,
          'end': 150,
          'notes': 'الخامسة عن ابن خليع. النشر ج1 ص150.',
        },
        {
          'name': 'طريق النهرواني',
          'start': 150,
          'end': 150,
          'notes': 'السادسة عن ابن خليع. النشر ج1 ص150.',
        },
        {
          'name': 'طريق الخبازي',
          'start': 150,
          'end': 150,
          'notes': 'السابعة عن ابن خليع. النشر ج1 ص150.',
        },
        {
          'name': 'طريق النحوي',
          'start': 150,
          'end': 151,
          'notes': 'الثامنة عن ابن خليع، من طريق التلخيص لأبي معشر. النشر ج1 ص150-151.',
        },
        {
          'name': 'طريق المصاحفي',
          'start': 151,
          'end': 151,
          'notes': 'التاسعة عن ابن خليع. النشر ج1 ص151.',
        },
        {
          'name': 'طريق ابن مهران',
          'start': 151,
          'end': 151,
          'notes': 'العاشرة عن ابن خليع. النشر ج1 ص151.',
        },
      ];

      int? hammamiId;

      for (var i = 0; i < ibnKhulayiRoutes.length; i++) {
        final route = ibnKhulayiRoutes[i];

        final id = await ensureNode(
          parentId: ibnKhulayiId,
          name: route['name'] as String,
          type: 'route',
          pageStart: route['start'] as int,
          pageEnd: route['end'] as int,
          sortOrder: i + 1,
          notes: route['notes'] as String,
        );

        if (i == 0) {
          hammamiId = id;
        }
      }

      // الطرق الستة عن الحمامي.
      final hammamiRoutes = [
        {
          'name': 'طريق التجريد عن ابن الفحام',
          'notes': 'من كتاب التجريد، قرأ بها ابن الفحام على أبي الحسين الفارسي. النشر ج1 ص150.',
        },
        {
          'name': 'طريق التجريد عن إسحاق المالكي',
          'notes': 'من كتاب التجريد، قرأ بها إسحاق المالكي على أبي علي المالكي. النشر ج1 ص150.',
        },
        {
          'name': 'طريق روضة أبي علي المالكي',
          'notes': 'من كتاب الروضة لأبي علي المالكي. النشر ج1 ص150.',
        },
        {
          'name': 'طريق كفاية أبي العز',
          'notes': 'من كتاب كفاية أبي العز، عن أبي علي الواسطي. النشر ج1 ص150.',
        },
        {
          'name': 'طريق التذكار لابن شيطا',
          'notes': 'من كتاب التذكار لابن شيطا. النشر ج1 ص150.',
        },
        {
          'name': 'طريق الجامع لابن فارس',
          'notes': 'من كتاب الجامع لابن فارس. النشر ج1 ص150.',
        },
      ];

      for (var i = 0; i < hammamiRoutes.length; i++) {
        final route = hammamiRoutes[i];

        await ensureNode(
          parentId: hammamiId,
          name: route['name']!,
          type: 'route',
          pageStart: 150,
          pageEnd: 150,
          sortOrder: i + 1,
          notes: route['notes'],
        );
      }

      // ==========================================
      // ثانياً: الرزاز - ثلاثة طرق.
      // ==========================================

      final razzazId = await ensureNode(
        parentId: alimiId,
        name: 'طريق الرزاز',
        type: 'branch',
        pageStart: 151,
        pageEnd: 151,
        sortOrder: 2,
        notes: 'ذكر ابن الجزري للرزاز ثلاثة طرق. النشر ج1 ص151.',
      );

      final razzazRoutes = [
        {
          'name': 'طريق سبط الخياط عن الشريف أبي الفضل',
          'notes': 'من كتابي المبهج والمصباح، قرأ بها سبط الخياط على الشريف أبي الفضل. النشر ج1 ص151.',
        },
        {
          'name': 'طريق أبي الكرم عن الشريف أبي الفضل',
          'notes': 'من كتابي المبهج والمصباح، قرأ بها أبو الكرم على الشريف أبي الفضل. النشر ج1 ص151.',
        },
        {
          'name': 'طريق الهذلي عن الخزاعي',
          'notes': 'من كتاب الكامل، قرأ بها الهذلي على عبد الله بن شبيب، وقرأ بها على الخزاعي. النشر ج1 ص151.',
        },
      ];

      for (var i = 0; i < razzazRoutes.length; i++) {
        final route = razzazRoutes[i];

        await ensureNode(
          parentId: razzazId,
          name: route['name']!,
          type: 'route',
          pageStart: 151,
          pageEnd: 151,
          sortOrder: i + 1,
          notes: route['notes'],
        );
      }

      return {
        'added': added,
        'existing': existing,
      };
    });
  }
}
