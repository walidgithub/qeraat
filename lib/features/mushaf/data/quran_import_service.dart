
import 'package:flutter/services.dart';

import '../../../core/database/app_database.dart';

class QuranImportService {
  final AppDatabase appDatabase;

  QuranImportService(this.appDatabase);

  static const String assetPath =
      'assets/quran/quran-uthmani.txt';

  static const List<String> surahNames = [
    'الفاتحة', 'البقرة', 'آل عمران', 'النساء',
    'المائدة', 'الأنعام', 'الأعراف', 'الأنفال',
    'التوبة', 'يونس', 'هود', 'يوسف', 'الرعد',
    'إبراهيم', 'الحجر', 'النحل', 'الإسراء', 'الكهف',
    'مريم', 'طه', 'الأنبياء', 'الحج', 'المؤمنون',
    'النور', 'الفرقان', 'الشعراء', 'النمل', 'القصص',
    'العنكبوت', 'الروم', 'لقمان', 'السجدة', 'الأحزاب',
    'سبأ', 'فاطر', 'يس', 'الصافات', 'ص', 'الزمر',
    'غافر', 'فصلت', 'الشورى', 'الزخرف', 'الدخان',
    'الجاثية', 'الأحقاف', 'محمد', 'الفتح', 'الحجرات',
    'ق', 'الذاريات', 'الطور', 'النجم', 'القمر',
    'الرحمن', 'الواقعة', 'الحديد', 'المجادلة', 'الحشر',
    'الممتحنة', 'الصف', 'الجمعة', 'المنافقون',
    'التغابن', 'الطلاق', 'التحريم', 'الملك', 'القلم',
    'الحاقة', 'المعارج', 'نوح', 'الجن', 'المزمل',
    'المدثر', 'القيامة', 'الإنسان', 'المرسلات',
    'النبأ', 'النازعات', 'عبس', 'التكوير', 'الانفطار',
    'المطففين', 'الانشقاق', 'البروج', 'الطارق',
    'الأعلى', 'الغاشية', 'الفجر', 'البلد', 'الشمس',
    'الليل', 'الضحى', 'الشرح', 'التين', 'العلق',
    'القدر', 'البينة', 'الزلزلة', 'العاديات',
    'القارعة', 'التكاثر', 'العصر', 'الهمزة', 'الفيل',
    'قريش', 'الماعون', 'الكوثر', 'الكافرون', 'النصر',
    'المسد', 'الإخلاص', 'الفلق', 'الناس',
  ];

  // أعداد الآيات وفق العدّ الكوفي الشائع في مصاحف حفص.
  static const List<int> expectedAyahCounts = [
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109,
    123, 111, 43, 52, 99, 128, 111, 110, 98, 135,
    112, 78, 118, 64, 77, 227, 93, 88, 69, 60,
    34, 30, 73, 54, 45, 83, 182, 88, 75, 85,
    54, 53, 89, 59, 37, 35, 38, 29, 18, 45,
    60, 49, 62, 55, 78, 96, 29, 22, 24, 13,
    14, 11, 11, 18, 12, 12, 30, 52, 52, 44,
    28, 28, 20, 56, 40, 31, 50, 40, 46, 42,
    29, 19, 36, 25, 22, 17, 19, 26, 30, 20,
    15, 21, 11, 8, 8, 19, 5, 8, 8, 11,
    11, 8, 3, 9, 5, 4, 7, 3, 6, 3,
    5, 4, 5, 6,
  ];

  Future<int> importFromAsset() async {
    final text = await rootBundle.loadString(assetPath);
    final parsed = _parseAndValidate(text);

    final db = await appDatabase.database;

    return db.transaction<int>((txn) async {
      final existingSurahs = await txn.query(
        'surahs',
        columns: ['id'],
        limit: 1,
      );

      final existingAyahs = await txn.query(
        'ayahs',
        columns: ['id'],
        limit: 1,
      );

      if (existingSurahs.isNotEmpty ||
          existingAyahs.isNotEmpty) {
        throw StateError(
          'توجد بيانات سور أو آيات بالفعل. '
              'تم إيقاف الاستيراد لتجنب استبدال البيانات.',
        );
      }

      var importedCount = 0;

      for (var surahNumber = 1;
      surahNumber <= 114;
      surahNumber++) {
        final ayahs = parsed[surahNumber]!;
        await txn.insert('surahs', {
          'id': surahNumber,
          'name_ar': surahNames[surahNumber - 1],
          'ayah_count': ayahs.length,
        });

        for (var ayahNumber = 1;
        ayahNumber <= ayahs.length;
        ayahNumber++) {
          await txn.insert('ayahs', {
            'surah_id': surahNumber,
            'ayah_number': ayahNumber,
            'uthmani_text': ayahs[ayahNumber]!,
          });

          importedCount++;
        }
      }

      return importedCount;
    });
  }

  Map<int, Map<int, String>> _parseAndValidate(String text) {
    if (surahNames.length != 114 ||
        expectedAyahCounts.length != 114) {
      throw StateError('إعدادات التحقق من السور غير مكتملة.');
    }

    final parsed = <int, Map<int, String>>{};

    final lines = text.split(RegExp(r'\r?\n'));

    for (var index = 0; index < lines.length; index++) {
      final line = lines[index].trim();

      if (line.isEmpty || line.startsWith('#')) continue;

      final parts = line.split('|');

      if (parts.length != 3) {
        throw FormatException(
          'تنسيق غير صحيح في السطر ${index + 1}.',
        );
      }

      final surahNumber = int.tryParse(parts[0].trim());
      final ayahNumber = int.tryParse(parts[1].trim());
      final ayahText = parts[2];

      if (surahNumber == null ||
          ayahNumber == null ||
          surahNumber < 1 ||
          surahNumber > 114 ||
          ayahNumber < 1 ||
          ayahText.trim().isEmpty) {
        throw FormatException(
          'بيانات غير صالحة في السطر ${index + 1}.',
        );
      }

      final surahAyahs = parsed.putIfAbsent(
        surahNumber,
            () => <int, String>{},
      );

      if (surahAyahs.containsKey(ayahNumber)) {
        throw FormatException(
          'تكرار الآية $surahNumber:$ayahNumber.',
        );
      }

      // نحفظ نص الآية كما ورد في الملف دون إعادة تشكيله.
      surahAyahs[ayahNumber] = ayahText;
    }

    if (parsed.length != 114) {
      throw FormatException(
        'الملف لا يحتوي على السور الـ114 كاملة.',
      );
    }

    for (var surah = 1; surah <= 114; surah++) {
      final ayahs = parsed[surah];

      if (ayahs == null) {
        throw FormatException('السورة $surah غير موجودة.');
      }

      final expectedCount = expectedAyahCounts[surah - 1];

      if (ayahs.length != expectedCount) {
        throw FormatException(
          'عدد آيات السورة $surah هو ${ayahs.length}، '
              'والمتوقع $expectedCount. لم يتم الاستيراد.',
        );
      }

      for (var number = 1; number <= expectedCount; number++) {
        if (!ayahs.containsKey(number)) {
          throw FormatException(
            'الآية $surah:$number مفقودة.',
          );
        }
      }
    }

    return parsed;
  }
}
