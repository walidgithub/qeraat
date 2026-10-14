
class ComparisonItem {
  final int id;
  final String label;
  final String readingText;
  final String differenceText;
  final String explanation;

  const ComparisonItem({
    required this.id,
    required this.label,
    required this.readingText,
    required this.differenceText,
    required this.explanation,
  });

  factory ComparisonItem.fromMap(Map<String, Object?> map) {
    return ComparisonItem(
      id: map['id'] as int,
      label: map['label'] as String,
      readingText: map['reading_text'] as String,
      differenceText: map['difference_text'] as String,
      explanation: map['explanation'] as String,
    );
  }
}
