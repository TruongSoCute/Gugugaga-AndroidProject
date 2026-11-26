/// Vùng nguyên liệu (GET /vung-nguyen-lieu).
class Vung {
  final int id;
  final String ten;
  final String? moTa;
  final double? viDo;
  final double? kinhDo;

  const Vung({
    required this.id,
    required this.ten,
    this.moTa,
    this.viDo,
    this.kinhDo,
  });

  bool get coToaDo => viDo != null && kinhDo != null;

  factory Vung.fromJson(Map<String, dynamic> json) => Vung(
        id: json['id'] as int,
        ten: json['ten'] as String,
        moTa: json['moTa'] as String?,
        viDo: _toDouble(json['viDo']),
        kinhDo: _toDouble(json['kinhDo']),
      );

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
