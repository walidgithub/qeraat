
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'basair_qiraat.db');

    _database = await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createTables(db);
        await _insertDemoData(db);
      },
    );

    return _database!;
  }

  Future<void> _createTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE surahs (
        id INTEGER PRIMARY KEY,
        name_ar TEXT NOT NULL,
        ayah_count INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE ayahs (
        id INTEGER PRIMARY KEY,
        surah_id INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        uthmani_text TEXT NOT NULL,
        UNIQUE(surah_id, ayah_number),
        FOREIGN KEY(surah_id) REFERENCES surahs(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE qurras (
        id INTEGER PRIMARY KEY,
        name_ar TEXT NOT NULL,
        order_no INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE riwayat (
        id INTEGER PRIMARY KEY,
        qari_id INTEGER NOT NULL,
        name_ar TEXT NOT NULL,
        FOREIGN KEY(qari_id) REFERENCES qurras(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sources (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT,
        edition TEXT,
        page_reference TEXT,
        review_status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE turuq (
        id INTEGER PRIMARY KEY,
        riwaya_id INTEGER NOT NULL,
        name_ar TEXT NOT NULL,
        source_id INTEGER,
        FOREIGN KEY(riwaya_id) REFERENCES riwayat(id),
        FOREIGN KEY(source_id) REFERENCES sources(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE reading_variants (
        id INTEGER PRIMARY KEY,
        ayah_id INTEGER NOT NULL,
        variant_group TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT,
        review_status TEXT NOT NULL DEFAULT 'pending',
        source_id INTEGER,
        FOREIGN KEY(ayah_id) REFERENCES ayahs(id),
        FOREIGN KEY(source_id) REFERENCES sources(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE variant_forms (
        id INTEGER PRIMARY KEY,
        variant_id INTEGER NOT NULL,
        tariq_id INTEGER NOT NULL,
        label TEXT NOT NULL,
        reading_text TEXT NOT NULL,
        difference_text TEXT,
        notes TEXT,
        FOREIGN KEY(variant_id) REFERENCES reading_variants(id),
        FOREIGN KEY(tariq_id) REFERENCES turuq(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE bookmarks (
        id INTEGER PRIMARY KEY,
        ayah_id INTEGER NOT NULL,
        selected_tariq_id INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY(ayah_id) REFERENCES ayahs(id),
        FOREIGN KEY(selected_tariq_id) REFERENCES turuq(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE student_notes (
        id INTEGER PRIMARY KEY,
        ayah_id INTEGER NOT NULL,
        variant_id INTEGER,
        note_text TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(ayah_id) REFERENCES ayahs(id),
        FOREIGN KEY(variant_id) REFERENCES reading_variants(id)
      )
    ''');

    // بيانات واجهة اصطناعية مستقلة عن بيانات القرآن.
    await db.execute('''
      CREATE TABLE demo_comparison_items (
        id INTEGER PRIMARY KEY,
        label TEXT NOT NULL,
        reading_text TEXT NOT NULL,
        difference_text TEXT NOT NULL,
        explanation TEXT NOT NULL
      )
    ''');
  }

  Future<void> _insertDemoData(DatabaseExecutor db) async {
    await db.insert('demo_comparison_items', {
      'id': 1,
      'label': 'مثال اصطناعي أ',
      'reading_text': 'هذه عبارة تجريبية ألف',
      'difference_text': 'ألف',
      'explanation': 'بيانات واجهة فقط، وليست قراءة قرآنية.',
    });

    await db.insert('demo_comparison_items', {
      'id': 2,
      'label': 'مثال اصطناعي ب',
      'reading_text': 'هذه عبارة تجريبية باء',
      'difference_text': 'باء',
      'explanation': 'بيانات واجهة فقط، وليست قراءة قرآنية.',
    });
  }

  Future<List<Map<String, Object?>>> getDemoItems() async {
    final db = await database;
    return db.query('demo_comparison_items', orderBy: 'id ASC');
  }
}
