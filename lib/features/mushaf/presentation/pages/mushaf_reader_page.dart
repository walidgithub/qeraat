import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../comparison/presentation/cubit/comparison_cubit.dart';
import '../../../comparison/presentation/pages/comparison_page.dart';

class MushafReaderPage extends StatelessWidget {
  const MushafReaderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بصائر القراءات'),
        actions: [
          BlocBuilder<ComparisonCubit, ComparisonState>(
            builder: (context, state) {
              return IconButton(
                tooltip: state.showComparison
                    ? 'إخفاء هامش المقارنة'
                    : 'إظهار هامش المقارنة',
                icon: Icon(
                  state.showComparison ? Icons.menu_open : Icons.compare_arrows,
                ),
                onPressed: () {
                  context.read<ComparisonCubit>().toggleComparison();
                },
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 800) {
            return BlocBuilder<ComparisonCubit, ComparisonState>(
              builder: (context, state) {
                return Row(
                  children: [
                    if (state.showComparison) ...[
                      SizedBox(
                        width: 370,
                        child: const ComparisonPage(embedded: true),
                      ),
                      const VerticalDivider(width: 1),
                    ],
                    const Expanded(child: _ReadingArea()),
                  ],
                );
              },
            );
          }

          return const _ReadingArea();
        },
      ),
      floatingActionButton: LayoutBuilder(
        builder: (context, constraints) {
          return BlocBuilder<ComparisonCubit, ComparisonState>(
            builder: (context, state) {
              return FloatingActionButton.extended(
                onPressed: () async {
                  if (state.showComparison) {
                    context.read<ComparisonCubit>().toggleComparison();
                  }

                  await showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,

                    builder: (sheetContext) {
                      return BlocProvider.value(
                        value: context.read<ComparisonCubit>(),
                        child: SizedBox(
                          height: MediaQuery.sizeOf(sheetContext).height * 0.75,
                          child: const ComparisonPage(embedded: true),
                        ),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.compare_arrows),
                label: const Text('المقارنة'),
              );
            },
          );
        },
      ),
    );
  }
}

class _ReadingArea extends StatelessWidget {
  const _ReadingArea();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'موضع القراءة',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'هذه مساحة تجريبية لتصميم قارئ القرآن. '
                  'لم يُضف إليها نص قرآني بعد.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, height: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'بعد إدخال النصوص المراجعة، سيظهر هنا نص الآية '
              'ويمكن التبديل بين أوجه القراءة مع الحفاظ على موضعها.',
              style: TextStyle(height: 1.8),
            ),
            const Spacer(),
            const Text(
              'نسخة تطويرية — ليست مصحفًا للاستخدام في التلاوة',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
