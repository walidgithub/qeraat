
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/gestures.dart';
import '../widgets/quran_import_button.dart';
import '../../../comparison/presentation/cubit/comparison_cubit.dart';
import '../../../comparison/presentation/pages/comparison_page.dart';
import '../cubit/mushaf_reader_cubit.dart';
import '../cubit/mushaf_reader_state.dart';

const Color _deepPurple = Color(0xFF24143D);
const Color _purple = Color(0xFF443182);
const Color _pageColor = Color(0xFFFCF8EF);
const Color _goldColor = Color(0xFFB79555);

class MushafReaderPage extends StatelessWidget {
  const MushafReaderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<MushafReaderCubit, MushafReaderState>(
      listenWhen: (previous, current) =>
      previous.ayahId != current.ayahId,
      listener: (context, state) {
        context
            .read<ComparisonCubit>()
            .loadApprovedForAyah(state.ayahId);
      },
      child: Scaffold(
        backgroundColor: _pageColor,
        appBar: AppBar(
          title: const Column(
            children: [
              Text(
                'بصائر القراءات',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              Text(
                'المصحف مع المقارنة',
                style: TextStyle(fontSize: 11),
              ),
            ],
          ),
          actions: const [
            QuranImportButton(),
          ],
        ),
        body: BlocBuilder<MushafReaderCubit, MushafReaderState>(
          builder: (context, state) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 850;

                return Row(
                  children: [
                    Expanded(
                      child: _ReadingArea(
                        state: state,
                      ),
                    ),
                    if (isWide) ...[
                      const VerticalDivider(
                        width: 1,
                        color: Color(0xFFE5DCCB),
                      ),
                      SizedBox(
                        width: 370,
                        child: BlocBuilder<
                            ComparisonCubit, ComparisonState>(
                          builder: (context, comparisonState) {
                            if (!comparisonState.showComparison) {
                              return const Center(
                                child: Text('المقارنة مخفية'),
                              );
                            }

                            return const ComparisonPage(
                              embedded: true,
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                );
              },
            );
          },
        ),
        floatingActionButton:
        MediaQuery.sizeOf(context).width < 850
            ? FloatingActionButton.extended(
          backgroundColor: _purple,
          foregroundColor: Colors.white,
          onPressed: () {
            final comparisonCubit =
            context.read<ComparisonCubit>();

            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: _pageColor,
              builder: (sheetContext) {
                return BlocProvider.value(
                  value: comparisonCubit,
                  child: SizedBox(
                    height:
                    MediaQuery.sizeOf(sheetContext).height *
                        0.80,
                    child: const ComparisonPage(
                      embedded: true,
                    ),
                  ),
                );
              },
            );
          },
          icon: const Icon(Icons.compare_arrows),
          label: const Text('مقارنة القراءات'),
        )
            : null,
      ),
    );
  }
}

class _ReadingArea extends StatelessWidget {
  final MushafReaderState state;

  const _ReadingArea({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MushafReaderCubit>();

    if (state.isLoading && state.surahs.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null && state.surahs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: cubit.loadSurahs,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.surahs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book_rounded,
                size: 64,
                color: _purple,
              ),
              SizedBox(height: 16),
              Text(
                'المصحف غير مستورد بعد',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: _deepPurple,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'استخدم زر الاستيراد بالأعلى لإضافة نص المصحف '
                    'من الملف الذي تم التحقق منه.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _SurahSelector(
          state: state,
          onSurahChanged: (id) {
            if (id == null) return;

            final surah = state.surahs.firstWhere(
                  (item) => item['id'] == id,
            );

            cubit.selectSurah(surah);
          },
          onAyahChanged: (number) {
            if (number == null) return;

            final ayah = state.ayahs.firstWhere(
                  (item) => item['ayah_number'] == number,
            );

            cubit.selectAyah(ayah);
          },
        ),
        const Divider(
          height: 1,
          color: Color(0xFFE5DCCB),
        ),
        Expanded(
          child: state.isLoading
              ? const Center(
            child: CircularProgressIndicator(),
          )
              : state.ayahs.isEmpty
              ? const Center(
            child: Text('لا توجد آيات متاحة لهذه السورة.'),
          )
              : _SurahContent(
            state: state,
            onAyahSelected: cubit.selectAyah,
          ),
        ),
      ],
    );
  }
}

class _SurahSelector extends StatelessWidget {
  final MushafReaderState state;
  final ValueChanged<int?> onSurahChanged;
  final ValueChanged<int?> onAyahChanged;

  const _SurahSelector({
    required this.state,
    required this.onSurahChanged,
    required this.onAyahChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedSurahExists = state.surahs.any(
          (surah) => surah['id'] == state.surahId,
    );

    final selectedAyahExists = state.ayahs.any(
          (ayah) => ayah['ayah_number'] == state.ayahNumber,
    );

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          const Icon(
            Icons.menu_book_rounded,
            color: _purple,
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<int>(
              value: selectedSurahExists ? state.surahId : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'اختر السورة',
                filled: true,
                fillColor: _pageColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              items: state.surahs.map((surah) {
                final id = surah['id'] as int;
                final name = surah['name_ar'] as String;

                return DropdownMenuItem<int>(
                  value: id,
                  child: Text(
                    '$name',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: onSurahChanged,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<int>(
              value: selectedAyahExists ? state.ayahNumber : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'اذهب إلى آية',
                filled: true,
                fillColor: _pageColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              items: state.ayahs.map((ayah) {
                final number = ayah['ayah_number'] as int;

                return DropdownMenuItem<int>(
                  value: number,
                  child: Text('$number'),
                );
              }).toList(),
              onChanged: state.ayahs.isEmpty ? null : onAyahChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _SurahContent extends StatefulWidget {
  final MushafReaderState state;
  final String selectedSurahName;
  final ValueChanged<Map<String, Object?>> onAyahSelected;

  const _SurahContent({
    required this.state,
    required this.selectedSurahName,
    required this.onAyahSelected,
  });

  @override
  State<_SurahContent> createState() => _SurahContentState();
}

class _SurahContentState extends State<_SurahContent> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void didUpdateWidget(covariant _SurahContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    _disposeRecognizers();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  String _getAyahText(Map<String, Object?> ayah) {
    return ayah['uthmani_text']?.toString() ?? '';
  }

  String _arabicNumber(int number) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((digit) => digits[int.parse(digit)])
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    final spans = <InlineSpan>[];

    for (final ayah in state.ayahs) {
      final number = (ayah['ayah_number'] as num).toInt();
      final text = _getAyahText(ayah);
      final isSelected = ayah['id'] == state.ayahId;

      final recognizer = TapGestureRecognizer()
        ..onTap = () => widget.onAyahSelected(ayah);

      _recognizers.add(recognizer);

      // نص الآية: يتلوّن عند الاختيار دون إطار.
      spans.add(
        TextSpan(
          text: '$text ',
          recognizer: recognizer,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFF443182)
                : const Color(0xFF211B18),
            backgroundColor: isSelected
                ? const Color(0xFFE8DDF8)
                : Colors.transparent,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      );

      // علامة رقم الآية داخل النص المتصل.
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            onTap: () => widget.onAyahSelected(ayah),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFF443182)
                    : const Color(0xFFF2E9D7),
                border: Border.all(
                  color: const Color(0xFFB79555),
                  width: 1,
                ),
              ),
              child: Text(
                _arabicNumber(number),
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF443182),
                ),
              ),
            ),
          ),
        ),
      );

      spans.add(const TextSpan(text: ' '));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 100),
      children: [
        _SurahHeader(
          name: widget.selectedSurahName,
          ayahCount: state.ayahs.length,
        ),
        const SizedBox(height: 24),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFCF8EF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 27,
                  height: 2.1,
                ),
                children: spans,
              ),
              textAlign: TextAlign.justify,
              textDirection: TextDirection.rtl,
            ),
          ),
        ),
      ],
    );
  }
}

class _SurahHeader extends StatelessWidget {
  final String name;
  final int ayahCount;

  const _SurahHeader({
    required this.name,
    required this.ayahCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 22,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF24143D),
            Color(0xFF443182),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _goldColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _deepPurple.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.auto_awesome,
            color: Color(0xFFE7CF9A),
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            'سُورَةُ $name',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 29,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: _goldColor.withValues(alpha: 0.7),
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$ayahCount آية',
              style: const TextStyle(
                color: Color(0xFFE7CF9A),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AyahNumber extends StatelessWidget {
  final int number;

  const _AyahNumber({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 35,
      height: 35,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF4EBD8),
        border: Border.all(
          color: _goldColor,
          width: 1.2,
        ),
      ),
      child: Text(
        _toArabicDigits(number),
        style: const TextStyle(
          color: _deepPurple,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _toArabicDigits(int value) {
    const western = '0123456789';
    const arabic = '٠١٢٣٤٥٦٧٨٩';

    return value.toString().split('').map((digit) {
      final index = western.indexOf(digit);
      return index < 0 ? digit : arabic[index];
    }).join();
  }
}
