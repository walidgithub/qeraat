
class Riwayah {
  final int id;
  final int qariId;
  final String nameAr;

  const Riwayah({
    required this.id,
    required this.qariId,
    required this.nameAr,
  });

  factory Riwayah.fromMap(Map<String, Object?> map) {
    return Riwayah(
      id: map['id'] as int,
      qariId: map['qari_id'] as int,
      nameAr: map['name_ar'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'qari_id': qariId,
      'name_ar': nameAr,
    };
  }
}
