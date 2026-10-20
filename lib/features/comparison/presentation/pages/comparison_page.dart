
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/comparison_item.dart';
import '../cubit/comparison_cubit.dart';

class ComparisonPage extends StatelessWidget {
  const ComparisonPage({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
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
                    message:
                    'اختر آية من المصحف لعرض أوجه القراءة المعتمدة.',
                  );
                }

                if (state.items.isEmpty) {
                  return const _MessageView(
                    icon: Icons.compare_arrows,
                    title: 'لا توجد أوجه معتمدة لهذه الآية',
                    message:
                    'ستظهر المقارنة هنا بعد إدخال بيانات موثقة '
                        'ومراجعتها واعتمادها.',
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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: Row(
        children: [
          Icon(
            Icons.compare_arrows,
            color: theme.colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'مقارنة القراءات',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          PopupMenuButton<ComparisonViewMode>(
            tooltip: 'طريقة العرض',
            icon: const Icon(Icons.view_agenda_outlined),
            onSelected: (mode) {
              context.read<ComparisonCubit>().setViewMode(mode);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: ComparisonViewMode.table,
                child: Row(
                  children: [
                    Icon(Icons.list_alt),
                    SizedBox(width: 10),
                    Text('قائمة الأوجه'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: ComparisonViewMode.highlighted,
                child: Row(
                  children: [
                    Icon(Icons.article_outlined),
                    SizedBox(width: 10),
                    Text('تفاصيل الوجه'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComparisonContent extends StatelessWidget {
  const _ComparisonContent({required this.state});

  final ComparisonState state;

  @override
  Widget build(BuildContext context) {
    if (state.viewMode == ComparisonViewMode.table) {
      return _ComparisonList(items: state.items);
    }

    ComparisonItem? selectedItem;

    for (final item in state.items) {
      if (item.id == state.selectedItemId) {
        selectedItem = item;
        break;
      }
    }

    selectedItem ??= state.items.first;

    return _ComparisonDetails(item: selectedItem);
  }
}

class _ComparisonList extends StatelessWidget {
  const _ComparisonList({required this.items});

  final List<ComparisonItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedId = context.select<ComparisonCubit, int?>(
          (cubit) => cubit.state.selectedItemId,
    );

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = item.id == selectedId;

        return Card(
          elevation: isSelected ? 2 : 0,
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerLow,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              final cubit = context.read<ComparisonCubit>();
              cubit.selectItem(item.id);
              cubit.setViewMode(ComparisonViewMode.highlighted);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        child: Text('${index + 1}'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _value(item.qariName, 'القارئ غير محدد'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_left),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetadataChip(
                        icon: Icons.menu_book_outlined,
                        label: _value(item.riwayahName, 'الرواية غير محددة'),
                      ),
                      _MetadataChip(
                        icon: Icons.route_outlined,
                        label: _value(item.tariqName, 'الطريق غير محدد'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SectionLabel(
                    icon: Icons.format_quote,
                    title: 'وجه القراءة',
                  ),
                  const SizedBox(height: 6),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: SelectableText(
                      _value(
                        item.readingText,
                        'لم يُدخل نص وجه القراءة.',
                      ),
                      textAlign: TextAlign.right,
                      style: theme.textTheme.titleLarge?.copyWith(
                        height: 1.9,
                        fontSize: 21,
                      ),
                    ),
                  ),
                  if (_hasText(item.differenceText)) ...[
                    const SizedBox(height: 14),
                    _DifferencePanel(text: item.differenceText),
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
  const _ComparisonDetails({required this.item});

  final ComparisonItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final sourceDetails = <MapEntry<String, String>>[
      if (_hasText(item.sourceTitle))
        MapEntry('الكتاب', item.sourceTitle!),
      if (_hasText(item.sourceAuthor))
        MapEntry('المؤلف', item.sourceAuthor!),
      if (_hasText(item.sourceEdition))
        MapEntry('الطبعة', item.sourceEdition!),
      if (_hasText(item.sourcePage))
        MapEntry('الصفحة أو المرجع', item.sourcePage!),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _value(item.qariName, 'القارئ غير محدد'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                _InfoRow(
                  label: 'الرواية',
                  value: _value(item.riwayahName, 'غير محددة'),
                ),
                _InfoRow(
                  label: 'الطريق',
                  value: _value(item.tariqName, 'غير محدد'),
                ),
                _InfoRow(
                  label: 'نوع الاختلاف',
                  value: _value(item.category, 'غير محدد'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SectionLabel(
          icon: Icons.menu_book,
          title: 'وجه القراءة',
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: SelectableText(
              _value(
                item.readingText,
                'لم يُدخل نص وجه القراءة.',
              ),
              textAlign: TextAlign.right,
              style: theme.textTheme.headlineSmall?.copyWith(
                height: 2,
              ),
            ),
          ),
        ),
        if (_hasText(item.differenceText)) ...[
          const SizedBox(height: 18),
          _DifferencePanel(text: item.differenceText),
        ],
        if (_hasText(item.explanation)) ...[
          const SizedBox(height: 20),
          _SectionLabel(
            icon: Icons.lightbulb_outline,
            title: 'الشرح',
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: SelectableText(
                item.explanation,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.8,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 22),
        const Divider(),
        const SizedBox(height: 12),
        _SectionLabel(
          icon: Icons.library_books_outlined,
          title: 'المصدر والتوثيق',
        ),
        const SizedBox(height: 8),
        if (sourceDetails.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'لم تُسجل بيانات المصدر لهذا الوجه.',
              textAlign: TextAlign.right,
            ),
          )
        else
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  for (var i = 0; i < sourceDetails.length; i++) ...[
                    _InfoRow(
                      label: sourceDetails[i].key,
                      value: sourceDetails[i].value,
                    ),
                    if (i < sourceDetails.length - 1)
                      const Divider(height: 16),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _DifferencePanel extends StatelessWidget {
  const _DifferencePanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: BorderDirectional(
          start: BorderSide(
            color: theme.colorScheme.tertiary,
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.difference_outlined,
                size: 19,
                color: theme.colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'موضع الاختلاف',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Directionality(
            textDirection: TextDirection.rtl,
            child: SelectableText(
              text,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.8,
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 17),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 21,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: SelectableText(
                value,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 52,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.7,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _value(String? value, String fallback) {
  if (value == null || value.trim().isEmpty) {
    return fallback;
  }
  return value.trim();
}

bool _hasText(String? value) {
  return value != null && value.trim().isNotEmpty;
}
