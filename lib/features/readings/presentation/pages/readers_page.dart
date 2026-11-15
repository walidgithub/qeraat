
import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';

class ReadersPage extends StatefulWidget {
  const ReadersPage({super.key});

  @override
  State<ReadersPage> createState() => _ReadersPageState();
}

class _ReadersPageState extends State<ReadersPage> {
  late Future<List<Map<String, dynamic>>> _readersFuture;

  @override
  void initState() {
    super.initState();
    _readersFuture = _loadReaders();
  }

  Future<List<Map<String, dynamic>>> _loadReaders() async {
    final db = await AppDatabase.instance.database;

    final readers = await db.query(
      'qurras',
      orderBy: 'order_no ASC',
    );

    final result = <Map<String, dynamic>>[];

    for (final reader in readers) {
      final narrators = await db.query(
        'riwayat',
        where: 'qari_id = ?',
        whereArgs: [reader['id']],
        orderBy: 'id ASC',
      );

      final narratorsWithTuruq = <Map<String, dynamic>>[];

      for (final narrator in narrators) {
        final turuq = await db.rawQuery(
          '''
          SELECT
            turuq.id,
            turuq.name_ar,
            turuq.source_id,
            sources.title AS source_title
          FROM turuq
          LEFT JOIN sources
            ON sources.id = turuq.source_id
          WHERE turuq.riwaya_id = ?
          ORDER BY turuq.id ASC
          ''',
          [narrator['id']],
        );

        final turuqWithNodes = <Map<String, dynamic>>[];

        for (final tariq in turuq) {
          final nodes = await db.rawQuery(
            '''
            SELECT
              tariq_nodes.*,
              sources.title AS source_title
            FROM tariq_nodes
            LEFT JOIN sources
              ON sources.id = tariq_nodes.source_id
            WHERE tariq_nodes.turuq_id = ?
            ORDER BY tariq_nodes.sort_order ASC,
                     tariq_nodes.id ASC
            ''',
            [tariq['id']],
          );

          turuqWithNodes.add({
            ...tariq,
            'nodes': nodes,
          });
        }

        narratorsWithTuruq.add({
          ...narrator,
          'turuq': turuqWithNodes,
        });
      }

      result.add({
        ...reader,
        'narrators': narratorsWithTuruq,
      });
    }

    return result;
  }

  // تحويل الفروع إلى مجموعات حسب الفرع الأب.
  Map<int?, List<Map<String, dynamic>>> _groupNodes(
      List<Map<String, dynamic>> nodes,
      ) {
    final grouped = <int?, List<Map<String, dynamic>>>{};

    for (final node in nodes) {
      final parentId = node['parent_id'] as int?;

      grouped.putIfAbsent(parentId, () => []);
      grouped[parentId]!.add(node);
    }

    return grouped;
  }

  String _reviewStatus(String? status) {
    switch (status) {
      case 'approved':
        return 'معتمد';
      case 'rejected':
        return 'مرفوض';
      case 'pending':
      default:
        return 'قيد المراجعة';
    }
  }

  Color _reviewColor(String? status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _pageReference(Map<String, dynamic> node) {
    final volume = node['volume'];
    final start = node['page_start'];
    final end = node['page_end'];

    if (volume == null && start == null && end == null) {
      return 'لم يُحدد موضع الصفحة';
    }

    final parts = <String>[];

    if (volume != null) {
      parts.add('ج$volume');
    }

    if (start != null && end != null) {
      parts.add(
        'ص${start == end ? start : '$start–$end'}',
      );
    } else if (start != null) {
      parts.add('ص$start');
    } else if (end != null) {
      parts.add('ص$end');
    }

    return parts.join(' - ');
  }

  // بناء كل مستوى من مستويات الشجرة بصورة تكرارية.
  Widget _buildNodeTile(
      Map<String, dynamic> node,
      Map<int?, List<Map<String, dynamic>>> groupedNodes, {
        int depth = 0,
      }) {
    final id = node['id'] as int;
    final children = groupedNodes[id] ?? [];

    final status = node['review_status']?.toString();
    final source = node['source_title']?.toString();
    final notes = node['notes']?.toString();

    final metadata = <String>[
      _pageReference(node),
      if (source != null && source.isNotEmpty) source,
      _reviewStatus(status),
    ];

    return ExpansionTile(
      key: PageStorageKey('tariq_node_$id'),
      tilePadding: EdgeInsetsDirectional.only(
        start: 16.0 + (depth * 12),
        end: 12,
      ),
      leading: Icon(
        children.isEmpty
            ? Icons.subdirectory_arrow_left
            : Icons.account_tree_outlined,
        color: Colors.deepPurple,
      ),
      title: Text(
        node['name_ar']?.toString() ?? '',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            metadata.join(' • '),
            style: TextStyle(
              fontSize: 11,
              color: _reviewColor(status),
            ),
          ),
          if (notes != null && notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                notes,
                style: const TextStyle(fontSize: 11),
              ),
            ),
        ],
      ),
      trailing: children.isEmpty
          ? null
          : CircleAvatar(
        radius: 12,
        child: Text(
          '${children.length}',
          style: const TextStyle(fontSize: 11),
        ),
      ),
      children: children.map((child) {
        return _buildNodeTile(
          child,
          groupedNodes,
          depth: depth + 1,
        );
      }).toList(),
    );
  }

  Widget _buildTariq(Map<String, dynamic> tariq) {
    final nodes =
    tariq['nodes'] as List<Map<String, dynamic>>;

    final groupedNodes = _groupNodes(nodes);
    final rootNodes = groupedNodes[null] ?? [];

    return ExpansionTile(
      tilePadding: const EdgeInsetsDirectional.only(
        start: 48,
        end: 16,
      ),
      leading: const Icon(
        Icons.route,
        color: Colors.deepPurple,
      ),
      title: Text(
        tariq['name_ar']?.toString() ?? '',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text('عدد الفروع: ${nodes.length}'),
      children: [
        if (rootNodes.isEmpty)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'لم تتم إضافة فروع لهذا الطريق بعد',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ...rootNodes.map(
              (node) => _buildNodeTile(
            node,
            groupedNodes,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('القراء والرواة'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _readersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('حدث خطأ: ${snapshot.error}'),
              ),
            );
          }

          final readers = snapshot.data ?? [];

          if (readers.isEmpty) {
            return const Center(
              child: Text('لا توجد بيانات للقراء'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: readers.length,
            itemBuilder: (context, index) {
              final reader = readers[index];

              final narrators =
              reader['narrators']
              as List<Map<String, dynamic>>;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    child: Text('${index + 1}'),
                  ),
                  title: Text(
                    reader['name_ar']?.toString() ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'عدد الروايات: ${narrators.length}',
                  ),
                  children: narrators.map((narrator) {
                    final turuq =
                    narrator['turuq']
                    as List<Map<String, dynamic>>;

                    return ExpansionTile(
                      tilePadding:
                      const EdgeInsetsDirectional.only(
                        start: 32,
                        end: 16,
                      ),
                      leading: const Icon(Icons.menu_book),
                      title: Text(
                        narrator['name_ar']?.toString() ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'عدد الطرق الرئيسية: ${turuq.length}',
                      ),
                      children: [
                        if (turuq.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'لم تتم إضافة طرق لهذه الرواية بعد',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ...turuq.map(_buildTariq),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
