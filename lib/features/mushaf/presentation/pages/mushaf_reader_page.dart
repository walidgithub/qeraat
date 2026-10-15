
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../comparison/presentation/cubit/comparison_cubit.dart';
import '../../../comparison/presentation/pages/comparison_page.dart';
import '../cubit/mushaf_reader_cubit.dart';
import '../cubit/mushaf_reader_state.dart';

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
        appBar: AppBar(
          title: const Text('بصائر القراءات'),
        ),
        body: BlocBuilder<MushafReaderCubit, MushafReaderState>(
          builder: (context, state) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 800;

                return Row(
                  children: [
                    Expanded(
                      child: _ReadingArea(state: state),
                    ),
                    if (isWide) ...[
                      const VerticalDivider(width: 1),
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
        floatingActionButton: MediaQuery.sizeOf(context).width < 800
            ? FloatingActionButton.extended(
          onPressed: () {
            final comparisonCubit =
            context.read<ComparisonCubit>();

            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (sheetContext) {
                return BlocProvider.value(
                  value: comparisonCubit,
                  child: SizedBox(
                    height:
                    MediaQuery.sizeOf(sheetContext).height *
                        0.75,
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
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.surahs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.error!, textAlign: TextAlign.center),
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
              Icon(Icons.menu_book_outlined, size: 56),
              SizedBox(height: 16),
              Text(
                'قاعدة البيانات لا تحتوي على سور حتى الآن.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 8),
              Text(
                'أضف بيانات المصحف من مصدر موثوق ومراجَع.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Text('السورة:'),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: state.surahs.any(
                        (s) => s['id'] == state.surahId,
                  )
                      ? state.surahId
                      : null,
                  hint: const Text('اختر السورة'),
                  items: state.surahs.map((surah) {
                    return DropdownMenuItem<int>(
                      value: surah['id'] as int,
                      child: Text(surah['name_ar'] as String),
                    );
                  }).toList(),
                  onChanged: (id) {
                    if (id == null) return;

                    final surah = state.surahs.firstWhere(
                          (s) => s['id'] == id,
                    );

                    cubit.selectSurah(surah);
                  },
                ),
              ),
              const SizedBox(width: 8),
              const Text('الآية:'),
              const SizedBox(width: 4),
              DropdownButton<int>(
                value: state.ayahs.any(
                      (a) => a['ayah_number'] == state.ayahNumber,
                )
                    ? state.ayahNumber
                    : null,
                hint: const Text('—'),
                items: state.ayahs.map((ayah) {
                  final number = ayah['ayah_number'] as int;

                  return DropdownMenuItem<int>(
                    value: number,
                    child: Text('$number'),
                  );
                }).toList(),
                onChanged: (number) {
                  if (number == null) return;

                  final ayah = state.ayahs.firstWhere(
                        (a) => a['ayah_number'] == number,
                  );

                  cubit.selectAyah(ayah);
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.ayahText == null
              ? const Center(
            child: Text('لا توجد آيات متاحة لهذه السورة.'),
          )
              : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  state.surahName ?? '',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                SelectableText(
                  state.ayahText!,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 28,
                    height: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Text('الآية ${state.ayahNumber}'),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: state.ayahs.isEmpty || state.isLoading
                    ? null
                    : cubit.previousAyah,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('السابقة'),
              ),
              Flexible(
                child: Text(
                  state.surahName == null
                      ? 'لم يتم اختيار سورة'
                      : '${state.surahName} - ${state.ayahNumber}',
                  textAlign: TextAlign.center,
                ),
              ),
              OutlinedButton.icon(
                onPressed: state.ayahs.isEmpty || state.isLoading
                    ? null
                    : cubit.nextAyah,
                icon: const Icon(Icons.arrow_back),
                label: const Text('التالية'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
