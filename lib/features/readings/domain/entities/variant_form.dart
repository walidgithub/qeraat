
class VariantForm {
  final int id;
  final int variantId;
  final int tariqId;
  final String label;
  final String readingText;
  final String? differenceText;
  final String? notes;

  const VariantForm({
    required this.id,
    required this.variantId,
    required this.tariqId,
    required this.label,
    required this.readingText,
    this.differenceText,
    this.notes,
  });

  factory VariantForm.fromMap(Map<String, Object?> map) {
    return VariantForm(
      id: map['id'] as int,
      variantId: map['variant_id'] as int,
      tariqId: map['tariq_id'] as int,
      label: map['label'] as String,
      readingText: map['reading_text'] as String,
      differenceText: map['difference_text'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'variant_id': variantId,
      'tariq_id': tariqId,
      'label': label,
      'reading_text': readingText,
      'difference_text': differenceText,
      'notes': notes,
    };
  }
}
