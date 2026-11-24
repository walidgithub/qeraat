import 'package:sqflite/sqflite.dart';

class BasairShubaYahyaImporter {
  static Future<Map<String, int>> import(Database db) async {
    return db.transaction((txn) async {
      // تحديد رواية شعبة عن عاصم.
      final riwayat = await txn.rawQuery(
        '''
        SELECT riwayat.id
        FROM riwayat
        INNER JOIN qurras
          ON qurras.id = riwayat.qari_id
        WHERE qurras.name_ar = ?
          AND riwayat.name_ar = ?
        LIMIT 1
        ''',
        ['عاصم الكوفي', 'شعبة'],
      );

      if (riwayat.isEmpty) {
        throw StateError('لم يتم العثور على رواية شعبة عن عاصم');
      }

      final riwayaId = riwayat.first['id'] as int;

      // تحديد الطريق الرئيسي: يحيى بن آدم عن شعبة.
      final turuq = await txn.query(
        'turuq',
        where: 'riwaya_id = ? AND name_ar LIKE ?',
        whereArgs: [
          riwayaId,
          'طريق يحيى بن آدم عن شعبة%',
        ],
        limit: 1,
      );

      if (turuq.isEmpty) {
        throw StateError('لم يتم العثور على طريق يحيى بن آدم عن شعبة');
      }

      final turuqId = turuq.first['id'] as int;

      // تحديد مصدر النشر.
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

      // إضافة عقدة أو استرجاعها دون تكرار.
      Future<int> ensureNode({
        required int? parentId,
        required String name,
        required String type,
        required int pageStart,
        required int pageEnd,
        required int sortOrder,
        String? notes,
      }) async {
        final String whereClause;
        final List<Object?> whereArguments;

        if (parentId == null) {
          whereClause = '''
            turuq_id = ?
            AND parent_id IS NULL
            AND name_ar = ?
          ''';

          whereArguments = [turuqId, name];
        } else {
          whereClause = '''
            turuq_id = ?
            AND parent_id = ?
            AND name_ar = ?
          ''';

          whereArguments = [turuqId, parentId, name];
        }

        final found = await txn.query(
          'tariq_nodes',
          columns: ['id'],
          where: whereClause,
          whereArgs: whereArguments,
          limit: 1,
        );

        if (found.isNotEmpty) {
          existing++;

          final id = found.first['id'] as int;

          // تحديث الملاحظة التوثيقية فقط عند توفيرها.
          // لا نغيّر حالة الاعتماد أو بيانات العقدة الموجودة.
          if (notes != null) {
            await txn.update(
              'tariq_nodes',
              {'notes': notes},
              where: 'id = ?',
              whereArgs: [id],
            );
          }

          return id;
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

      // =====================================================
      // أولاً: شعيب بن أيوب عن يحيى بن آدم.
      // النشر: الجزء الأول، ص 147-148.
      // =====================================================

      final shuaibId = await ensureNode(
        parentId: null,
        name: 'شعيب بن أيوب عن يحيى بن آدم',
        type: 'transmitter',
        pageStart: 147,
        pageEnd: 148,
        sortOrder: 1,
        notes: 'ذكر ابن الجزري لشعيب خمسة طرق، مجموعها 38 طريقاً. النشر ج1 ص147-148.',
      );

      // الطرق الخمسة عن شعيب.
      final shuaibRoutes = [
        {
          'name': 'طريق الأصم',
          'start': 147,
          'end': 147,
          'order': 1,
          'notes': 'الأولى عن شعيب. ذكر ابن الجزري لها اثني عشر طريقاً. النشر ج1 ص147.',
        },
        {
          'name': 'طريق القافلائي',
          'start': 147,
          'end': 147,
          'order': 2,
          'notes': 'الثانية عن شعيب. ذكر ابن الجزري لها ثمانية طرق. النشر ج1 ص147.',
        },
        {
          'name': 'طريق المثلثي',
          'start': 147,
          'end': 148,
          'order': 3,
          'notes': 'الثالثة عن شعيب. ذكر ابن الجزري لها ستة طرق. النشر ج1 ص147-148.',
        },
        {
          'name': 'طريق أبي عون',
          'start': 148,
          'end': 148,
          'order': 4,
          'notes': 'الرابعة عن شعيب. ذكر ابن الجزري لها خمسة طرق. النشر ج1 ص148.',
        },
        {
          'name': 'طريق نفطويه',
          'start': 148,
          'end': 148,
          'order': 5,
          'notes': 'الخامسة عن شعيب. ذكر ابن الجزري لها سبعة طرق. النشر ج1 ص148.',
        },
      ];

      final shuaibRouteIds = <String, int>{};

      for (final route in shuaibRoutes) {
        final name = route['name'] as String;

        final id = await ensureNode(
          parentId: shuaibId,
          name: name,
          type: 'route',
          pageStart: route['start'] as int,
          pageEnd: route['end'] as int,
          sortOrder: route['order'] as int,
          notes: route['notes'] as String,
        );

        shuaibRouteIds[name] = id;
      }

      // =====================================================
      // تفصيل طريق المثلثي عن شعيب بن أيوب.
      // النشر: الجزء الأول، ص 147.
      // تضاف الفروع تحت العقدة الموجودة دون تكرار.
      // =====================================================

      final mathlathiId = shuaibRouteIds['طريق المثلثي']!;

      final mathlathiDetails = [
        {
          'name': 'طريق كتاب الموضح لابن خيرون',
          'notes':
          'من كتاب الموضح لأبي منصور بن خيرون. '
              'ذكر ضمن مصادر طريق المثلثي. النشر ج1 ص147.',
        },
        {
          'name': 'طريق كتاب المفتاح لابن خيرون',
          'notes':
          'من كتاب المفتاح لأبي منصور بن خيرون. '
              'ذكر ضمن مصادر طريق المثلثي. النشر ج1 ص147.',
        },
        {
          'name': 'طريق مصباح أبي الكرم عن عبد السيد',
          'notes':
          'من مصباح أبي الكرم، قرأ بها على عبد السيد بن عتاب، '
              'وقرأ بها عبد السيد على القاضي أبي العلاء الواسطي، '
              'ثم على أبي علي أحمد بن علي بن البصري الواسطي. '
              'النشر ج1 ص147.',
        },
        {
          'name': 'طريق سبط الخياط عن ثابت بن بندار',
          'notes':
          'بالإسناد المتقدم إلى سبط الخياط، قرأ بها على أبي المعالي '
              'ثابت بن بندار. النشر ج1 ص147.',
        },
        {
          'name': 'طريق عبد السيد وثابت إلى أبي الفتح',
          'notes':
          'من مصباح أبي الكرم، عن عبد السيد بن عتاب وثابت بن بندار، '
              'وقرآ بها على أبي الفتح فرج بن عمر بن الحسن البصري المفسر، '
              'ثم على القاضي أبي الحسن علي بن أحمد بن العريف الجامدي. '
              'النشر ج1 ص147.',
        },
        {
          'name': 'طريق ثابت بن بندار إلى الجامدي',
          'notes':
          'من مصباح أبي الكرم، عن ثابت بن بندار، '
              'إلى أبي الفتح فرج بن عمر، ثم القاضي أبي الحسن الجامدي. '
              'النشر ج1 ص147.',
        },
      ];

      for (var i = 0; i < mathlathiDetails.length; i++) {
        final detail = mathlathiDetails[i];

        await ensureNode(
          parentId: mathlathiId,
          name: detail['name']!,
          type: 'route',
          pageStart: 147,
          pageEnd: 147,
          sortOrder: i + 1,
          notes: detail['notes'],
        );
      }

      // تفصيل الطرق الستة المذكورة تحت طريق الأصم.
      final asammId = shuaibRouteIds['طريق الأصم']!;

      final asammRoutes = [
        'طريق البغدادي',
        'طريق المطوعي',
        'طريق ابن عصام',
        'طريق ابن بابش',
        'طريق النقاش',
        'طريق ابن خليع',
      ];

      for (var i = 0; i < asammRoutes.length; i++) {
        await ensureNode(
          parentId: asammId,
          name: asammRoutes[i],
          type: 'route',
          pageStart: 147,
          pageEnd: 147,
          sortOrder: i + 1,
          notes: 'من الطرق المذكورة تحت طريق الأصم. النشر ج1 ص147.',
        );
      }

      // =====================================================
      // ثانياً: أبو حمدون عن يحيى بن آدم.
      // النشر: الجزء الأول، ص 148-150.
      // =====================================================

      final abuHamdoonId = await ensureNode(
        parentId: null,
        name: 'أبو حمدون عن يحيى بن آدم',
        type: 'transmitter',
        pageStart: 148,
        pageEnd: 150,
        sortOrder: 2,
        notes: 'ذكر ابن الجزري لأبي حمدون طريقين، مجموعهما عشرون طريقاً. النشر ج1 ص148-150.',
      );

      // الطريقان عن أبي حمدون.
      final sawwafId = await ensureNode(
        parentId: abuHamdoonId,
        name: 'طريق الصواف',
        type: 'route',
        pageStart: 148,
        pageEnd: 150,
        sortOrder: 1,
        notes: 'الأولى عن أبي حمدون. ذكر ابن الجزري تحتها خمسة طرق رئيسية، مجموعها 19 طريقاً. النشر ج1 ص148-150.',
      );

      await ensureNode(
        parentId: abuHamdoonId,
        name: 'طريق أبي عون',
        type: 'route',
        pageStart: 150,
        pageEnd: 150,
        sortOrder: 2,
        notes: 'الثانية عن أبي حمدون. وبها يكتمل مجموع طرق أبي حمدون العشرين. النشر ج1 ص150.',
      );

      // التفريعات الخمسة تحت طريق الصواف.
      final sawwafRoutes = [
        {
          'name': 'طريق الحمامي',
          'notes': 'الأولى عن الصواف. ذكر ابن الجزري لها أحد عشر طريقاً. النشر ج1 ص148-149.',
        },
        {
          'name': 'طريق ابن شاذان',
          'notes': 'الثانية عن الصواف. النشر ج1 ص149.',
        },
        {
          'name': 'طريق النهرواني',
          'notes': 'الثالثة عن الصواف. ذكر ابن الجزري لها خمسة طرق. النشر ج1 ص149.',
        },
        {
          'name': 'طريق النحاس',
          'notes': 'الرابعة عن الصواف. قرأ الحروف على الصواف. النشر ج1 ص149-150.',
        },
        {
          'name': 'طريق الخلال',
          'notes': 'الخامسة عن الصواف. قرأ الحروف على الصواف. النشر ج1 ص149-150.',
        },
      ];

      for (var i = 0; i < sawwafRoutes.length; i++) {
        final route = sawwafRoutes[i];

        await ensureNode(
          parentId: sawwafId,
          name: route['name']!,
          type: 'route',
          pageStart: 148,
          pageEnd: 150,
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

  static Future<void> debugPrintShubaYahyaTree(
      Database db,
      ) async {
    final rows = await db.rawQuery('''
    SELECT
      id,
      turuq_id,
      parent_id,
      name_ar,
      node_type,
      review_status,
      sort_order,
      page_start,
      page_end,
      notes
    FROM tariq_nodes
    ORDER BY turuq_id, parent_id, sort_order, id
  ''');

    for (final row in rows) {
      print(
        'TREE: '
            'id=${row['id']} | '
            'turuq=${row['turuq_id']} | '
            'parent=${row['parent_id']} | '
            'name=${row['name_ar']} | '
            'type=${row['node_type']} | '
            'status=${row['review_status']} | '
            'sort=${row['sort_order']} | '
            'pages=${row['page_start']}-${row['page_end']} | '
            'notes=${row['notes']}',
      );
    }
  }


  static Future<void> importQaffalayiDetails(Database db) async {
    const rootName = 'شعيب بن أيوب عن يحيى بن آدم';
    const routeName = 'طريق القافلائي';

    final details = [
      {
        'name': 'طريق التيسير',
        'notes': 'من كتاب التيسير، قرأ بها الداني على فارس. النشر ج1 ص147.',
      },
      {
        'name': 'طريق الشاطبية',
        'notes': 'من طريق الشاطبية، وذكرها ابن الجزري مع التيسير عن فارس. النشر ج1 ص147.',
      },
      {
        'name': 'طريق التجريد',
        'notes': 'من كتاب التجريد، قرأ بها ابن الفحام على عبد الباقي بن فارس، وقرأ عبد الباقي على أبيه فارس. النشر ج1 ص147.',
      },
      {
        'name': 'طريق التلخيص',
        'notes': 'من كتاب التلخيص، قرأ بها ابن بليمة على عبد الباقي بن فارس، وقرأ عبد الباقي على أبيه فارس. النشر ج1 ص147.',
      },
      {
        'name': 'طريق العنوان',
        'notes': 'من كتاب العنوان، قرأ بها أبو طاهر على عبد الجبار الطرسوسي. النشر ج1 ص147.',
      },
      {
        'name': 'طريق المجتبى',
        'notes': 'من كتاب المجتبى للطرسوسي. النشر ج1 ص147.',
      },
      {
        'name': 'طريق الكافي',
        'notes': 'من كتاب الكافي، قرأ بها ابن شريح. النشر ج1 ص147.',
      },
      {
        'name': 'طريق روضة المعدل',
        'notes': 'من روضة المعدل، وذكر ابن الجزري القراءة بها على ابن نفيس. النشر ج1 ص147.',
      },
    ];

    await db.transaction((txn) async {
      final roots = await txn.query(
        'tariq_nodes',
        where: 'turuq_id = ? AND parent_id IS NULL AND name_ar = ?',
        whereArgs: [1, rootName],
        limit: 1,
      );

      if (roots.isEmpty) {
        throw Exception('لم يتم العثور على أصل شعيب عن يحيى بن آدم');
      }

      final rootId = roots.first['id'];

      final parents = await txn.query(
        'tariq_nodes',
        where: 'turuq_id = ? AND parent_id = ? AND name_ar = ?',
        whereArgs: [1, rootId, routeName],
        limit: 1,
      );

      if (parents.isEmpty) {
        throw Exception('لم يتم العثور على طريق القافلائي');
      }

      final parent = parents.first;
      final parentId = parent['id'];
      final sourceId = parent['source_id'];

      int added = 0;
      int existing = 0;

      for (int i = 0; i < details.length; i++) {
        final item = details[i];

        final found = await txn.query(
          'tariq_nodes',
          where: 'turuq_id = ? AND parent_id = ? AND name_ar = ?',
          whereArgs: [1, parentId, item['name']],
          limit: 1,
        );

        if (found.isNotEmpty) {
          existing++;
          continue;
        }

        await txn.insert('tariq_nodes', {
          'turuq_id': 1,
          'parent_id': parentId,
          'name_ar': item['name'],
          'node_type': 'route',
          'source_id': sourceId,
          'volume': 1,
          'page_start': 147,
          'page_end': 147,
          'sort_order': i + 1,
          'review_status': 'pending',
          'notes': item['notes'],
        });

        added++;
      }

      print('تفاصيل القافلائي المضافة: $added');
      print('تفاصيل القافلائي الموجودة: $existing');
    });
  }

}
