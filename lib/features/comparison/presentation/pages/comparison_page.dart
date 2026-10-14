import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/comparison_cubit.dart';

class ComparisonPage extends StatelessWidget {
  final bool embedded;

  const ComparisonPage({
    super.key,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = BlocBuilder<ComparisonCubit, ComparisonState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'حدث خطأ أثناء تحميل المقارنة:\n${state.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (state.items.isEmpty) {
          return const Center(
            child: Text('لا توجد بيانات مقارنة حتى الآن.'),
          );
        }

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: SegmentedButton<ComparisonViewMode>(
                  segments: const [
                    ButtonSegment(
                      value: ComparisonViewMode.table,
                      label: Text('جدول'),
                      icon: Icon(Icons.table_chart),
                    ),
                    ButtonSegment(
                      value: ComparisonViewMode.highlighted,
                      label: Text('إبراز'),
                      icon: Icon(Icons.format_color_text),
                    ),
                  ],
                  selected: {state.viewMode},
                  onSelectionChanged: (selection) {
                    context
                        .read<ComparisonCubit>()
                        .setViewMode(selection.first);
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'بيانات توضيحية تجريبية وليست نصًا قرآنيًا '
                      'أو أوجه قراءة معتمدة.',
                  style: TextStyle(
                    color: Colors.deepOrange,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: state.viewMode == ComparisonViewMode.table
                    ? _buildTable(context, state)
                    : _buildHighlighted(context, state),
              ),
            ],
          ),
        );
      },
    );

    if (embedded) {
      return Material(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF24143D),
              child: const Text(
                'هامش المقارنة',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('مقارنة القراءات'),
      ),
      body: content,
    );
  }

  Widget _buildTable(
      BuildContext context,
      ComparisonState state,
      ) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Row(
          children: [
            Expanded(
              child: Text(
                'الوجه التجريبي',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(
                'البيان',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const Divider(),
        for (final item in state.items)
          InkWell(
            onTap: () => context
                .read<ComparisonCubit>()
                .selectItem(item.id),
            child: Container(
              color: item.id == state.selectedItemId
                  ? const Color(0xFFEDE7F6)
                  : null,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(item.readingText)),
                  Expanded(child: Text(item.differenceText)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHighlighted(
      BuildContext context,
      ComparisonState state,
      ) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final item in state.items)
          Card(
            color: item.id == state.selectedItemId
                ? const Color(0xFFEDE7F6)
                : null,
            child: InkWell(
              onTap: () => context
                  .read<ComparisonCubit>()
                  .selectItem(item.id),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      item.readingText,
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'موضع المقارنة: ${item.differenceText}',
                      style: const TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (item.explanation.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(item.explanation),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}