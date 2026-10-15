
class ComparisonItem {
  final int id;
  final String label;
  final String readingText;
  final String differenceText;
  final String explanation;

  final int? variantId;
  final int? tariqId;
  final String? qariName;
  final String? riwayahName;
  final String? tariqName;
  final String? category;
  final String? sourceTitle;
  final String? sourceAuthor;
  final String? sourceEdition;
  final String? sourcePage;

  const ComparisonItem({
    required this.id,
    required this.label,
    required this.readingText,
    required this.differenceText,
    required this.explanation,
    this.variantId,
    this.tariqId,
    this.qariName,
    this.riwayahName,
    this.tariqName,
    this.category,
    this.sourceTitle,
    this.sourceAuthor,
    this.sourceEdition,
    this.sourcePage,
  });

  factory ComparisonItem.fromApprovedRow(Map<String, Object?> row) {
    String value(String key, [String fallback = '']) {
      return row[key]?.toString() ?? fallback;
    }

    return ComparisonItem(
      id: row['form_id'] as int,
      variantId: row['variant_id'] as int?,
      tariqId: row['tariq_id'] as int?,
      label: value('label', 'وجه قراءة'),
      readingText: value('reading_text'),
      differenceText: value('difference_text'),
      explanation: value('description'),
      qariName: value('qari_name'),
      riwayahName: value('riwayah_name'),
      tariqName: value('tariq_name'),
      category: value('category'),
      sourceTitle: value('source_title'),
      sourceAuthor: value('source_author'),
      sourceEdition: value('source_edition'),
      sourcePage: value('source_page'),
    );
  }
}
