
class ReadingVariant {
  final int id;
  final int ayahId;
  final String variantGroup;
  final String category;
  final String? description;
  final String reviewStatus;
  final int? sourceId;

  const ReadingVariant({
    required this.id,
    required this.ayahId,
    required this.variantGroup,
    required this.category,
    this.description,
    this.reviewStatus = 'pending',
    this.sourceId,
  });

  factory ReadingVariant.fromMap(Map<String, Object?> map) {
    return ReadingVariant(
      id: map['id'] as int,
      ayahId: map['ayah_id'] as int,
      variantGroup: map['variant_group'] as String,
      category: map['category'] as String,
      description: map['description'] as String?,
      reviewStatus: map['review_status'] as String? ?? 'pending',
      sourceId: map['source_id'] as int?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'ayah_id': ayahId,
      'variant_group': variantGroup,
      'category': category,
      'description': description,
      'review_status': reviewStatus,
      'source_id': sourceId,
    };
  }
}
