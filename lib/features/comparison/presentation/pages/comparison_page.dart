
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/comparison_item.dart';
import '../cubit/comparison_cubit.dart';

class ComparisonPage extends StatelessWidget {
  final bool embedded;

  const ComparisonPage({
    super.key,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          _buildHeader(context),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<ComparisonCubit, ComparisonState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state.error != null) {
                  return _MessageView(
                    icon: Icons.error_outline,
                    title: 'تعذر تحميل المقارنة',
                    message: state.error!,
                  );
                }

                if (state.ayahId == null) {
                  return const _MessageView(
                    icon: Icons.menu_book_outlined,
                    title: 'لم يتم اختيار آية',
                    message: 'اختر آية من القارئ لعرض أوجه القراءة المعتمدة.',
                  );
                }

                if (state.items.isEmpty) {
                  return const _MessageView(
                    icon: Icons.compare_arrows,
                    title: 'لا توجد أوجه معتمدة لهذه الآية',
                    message:
                    'ستظهر المقارنة هنا بعد إضافة بيانات موثقة ومراجعتها واعتمادها.',
                  );
                }

                return _ComparisonContent(state: state);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: Row(
        children: [
          const Icon(Icons.compare_arrows),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'مقارنة القراءات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          BlocBuilder<ComparisonCubit, ComparisonState>(
            builder: (context, state) {
              return PopupMenuButton<ComparisonViewMode>(
                tooltip: 'طريقة العرض',
                icon: const Icon(Icons.view_agenda_outlined),
                onSelected: context.read<ComparisonCubit>().setViewMode,
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: ComparisonViewMode.table,
                    child: Text('عرض القائمة'),
                  ),
                  PopupMenuItem(
                    value: ComparisonViewMode.highlighted,
                    child: Text('عرض التفاصيل'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ComparisonContent extends StatelessWidget {
  final ComparisonState state;

  const _ComparisonContent({
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    if (state.viewMode == ComparisonViewMode.table) {
      return _ComparisonList(items: state.items);
    }

    final selected = state.items.where(
          (item) => item.id == state.selectedItemId,
    );

    final item = selected.isNotEmpty
        ? selected.first
        : state.items.first;

    return _ComparisonDetails(item: item);
  }
}

class _ComparisonList extends StatelessWidget {
  final List<ComparisonItem> items;

  const _ComparisonList({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ComparisonCubit>();
    final selectedId =
    context.select((ComparisonCubit c) => c.state.selectedItemId);

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final selected = item.id == selectedId;

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              cubit.selectItem(item.id);
              cubit.setViewMode(ComparisonViewMode.highlighted);
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.qariName ?? 'القارئ غير محدد',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (selected)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الرواية: ${item.riwayahName ?? 'غير محددة'}',
                  ),
                  Text(
                    'الطريق: ${item.tariqName ?? 'غير محدد'}',
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.readingText.isEmpty
                        ? 'لم يُدخل نص وجه القراءة'
                        : item.readingText,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontSize: 19,
                      height: 1.8,
                    ),
                  ),
                  if (item.differenceText.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'موضع الاختلاف: ${item.differenceText}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ComparisonDetails extends StatelessWidget {
  final ComparisonItem item;

  const _ComparisonDetails({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final sourceDetails = <String>[
      if (item.sourceTitle?.isNotEmpty == true)
        'الكتاب: ${item.sourceTitle}',
      if (item.sourceAuthor?.isNotEmpty == true)
        'المؤلف: ${item.sourceAuthor}',
      if (item.sourceEdition?.isNotEmpty == true)
        'الطبعة: ${item.sourceEdition}',
      if (item.sourcePage?.isNotEmpty == true)
        'الصفحة أو المرجع: ${item.sourcePage}',
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          item.qariName ?? 'القارئ غير محدد',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        _InfoRow(
          label: 'الرواية',
          value: item.riwayahName ?? 'غير محددة',
        ),
        _InfoRow(
          label: 'الطريق',
          value: item.tariqName ?? 'غير محدد',
        ),
        _InfoRow(
          label: 'نوع الاختلاف',
          value: item.category ?? 'غير محدد',
        ),
        const Divider(height: 28),
        Text(
          'وجه القراءة',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SelectableText(
          item.readingText.isEmpty
              ? 'لم يُدخل نص وجه القراءة.'
              : item.readingText,
          textDirection: TextDirection.rtl,
          style: const TextStyle(
            fontSize: 22,
            height: 1.9,
          ),
        ),
        if (item.differenceText.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'موضع الاختلاف',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SelectableText(
            item.differenceText,
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontSize: 18),
          ),
        ],
        if (item.explanation.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'الشرح',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SelectableText(
            item.explanation,
            textDirection: TextDirection.rtl,
          ),
        ],
        const Divider(height: 28),
        Text(
          'المصدر',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (sourceDetails.isEmpty)
          const Text('لم تُسجل بيانات المصدر لهذا الوجه.')
        else
          ...sourceDetails.map(
                (detail) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(detail),
            ),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
