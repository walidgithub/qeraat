
class Qari {
  final int id;
  final String nameAr;
  final int orderNo;

  const Qari({
    required this.id,
    required this.nameAr,
    required this.orderNo,
  });

  factory Qari.fromMap(Map<String, Object?> map) {
    return Qari(
      id: map['id'] as int,
      nameAr: map['name_ar'] as String,
      orderNo: map['order_no'] as int,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name_ar': nameAr,
      'order_no': orderNo,
    };
  }
}
