
class Tariq {
  final int id;
  final int riwayahId;
  final String nameAr;
  final int? sourceId;

  const Tariq({
    required this.id,
    required this.riwayahId,
    required this.nameAr,
    this.sourceId,
  });

  factory Tariq.fromMap(Map<String, Object?> map) {
    return Tariq(
      id: map['id'] as int,
      riwayahId: map['riwaya_id'] as int,
      nameAr: map['name_ar'] as String,
      sourceId: map['source_id'] as int?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'riwaya_id': riwayahId,
      'name_ar': nameAr,
      'source_id': sourceId,
    };
  }
}
