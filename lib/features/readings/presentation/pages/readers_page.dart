
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

      result.add({
        ...reader,
        'narrators': narrators,
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
              child: Text('حدث خطأ: ${snapshot.error}'),
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
                    return ListTile(
                      leading: const Icon(Icons.menu_book),
                      title: Text(narrator['name_ar']?.toString() ?? ''),
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
