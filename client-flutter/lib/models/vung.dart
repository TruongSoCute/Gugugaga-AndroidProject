/// Vùng nguyên liệu (GET /vung-nguyen-lieu).
class Vung {
  final int id;
  final String ten;

  const Vung({required this.id, required this.ten});

  factory Vung.fromJson(Map<String, dynamic> json) =>
      Vung(id: json['id'] as int, ten: json['ten'] as String);
}
