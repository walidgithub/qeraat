
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

        narratorsWithTuruq.add({
          ...narrator,
          'turuq': turuq,
        });
      }

      result.add({
        ...reader,
        'narrators': narratorsWithTuruq,
      });
    }

    return result;
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
          if (snapshot.connectionState == ConnectionState.waiting) {
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
              reader['narrators'] as List<Map<String, dynamic>>;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                    child: Text('${index + 1}'),
                  ),
                  title: Text(
                    reader['name_ar']?.toString() ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text('عدد الروايات: ${narrators.length}'),
                  children: narrators.map((narrator) {
                    final turuq =
                    narrator['turuq'] as List<Map<String, dynamic>>;

                    return ExpansionTile(
                      tilePadding: const EdgeInsetsDirectional.only(
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
                      subtitle: Text('عدد الطرق الرئيسية: ${turuq.length}'),
                      children: [
                        if (turuq.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'لم تتم إضافة طرق لهذه الرواية بعد',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),

                        ...turuq.map((tariq) {
                          final name =
                              tariq['name_ar']?.toString() ?? '';

                          final displayName = name.replaceAllMapped(
                            RegExp(r'(\d+)\s*-\s*(\d+)'),
                                (match) => '\u200E${match.group(1)}–${match.group(2)}\u200E',
                          );

                          final source =
                          tariq['source_title']?.toString();

                          return ListTile(
                            contentPadding:
                            const EdgeInsetsDirectional.only(
                              start: 64,
                              end: 16,
                            ),
                            leading: const Icon(
                              Icons.subdirectory_arrow_left,
                              color: Colors.deepPurple,
                            ),
                            title: Text(
                              displayName,
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: source == null
                                ? null
                                : Text(
                              'المصدر: $source',
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }),
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
