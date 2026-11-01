/// Một đánh giá công khai (GET /danh-gia, danhGiaGanDay của chi tiết sản phẩm).
/// Không có email hay số điện thoại người đánh giá.
class DanhGia {
  final int soSao;
  final String? noiDung;
  final String taoLuc;
  final String tenNguoiDanhGia;
  final List<String> anh;

  const DanhGia({
    required this.soSao,
    required this.taoLuc,
    required this.tenNguoiDanhGia,
    required this.anh,
    this.noiDung,
  });

  factory DanhGia.fromJson(Map<String, dynamic> json) => DanhGia(
        soSao: (json['soSao'] as num).toInt(),
        noiDung: json['noiDung'] as String?,
        taoLuc: json['taoLuc'] as String,
        tenNguoiDanhGia: json['tenNguoiDanhGia'] as String? ?? '',
        anh: (json['anh'] as List<dynamic>? ?? const []).map((e) => e as String).toList(),
      );
}

/// Trang đánh giá: { duLieu, phanTrang, tongHop: { soDanhGia, diemTrungBinh } }.
class TrangDanhGia {
  final List<DanhGia> duLieu;
  final int soDanhGia;
  final double? diemTrungBinh;

  const TrangDanhGia({required this.duLieu, required this.soDanhGia, this.diemTrungBinh});

  factory TrangDanhGia.fromJson(Map<String, dynamic> json) {
    final tongHop = json['tongHop'] as Map<String, dynamic>? ?? const {};
    return TrangDanhGia(
      duLieu: (json['duLieu'] as List<dynamic>)
          .map((e) => DanhGia.fromJson(e as Map<String, dynamic>))
          .toList(),
      soDanhGia: (tongHop['soDanhGia'] as num?)?.toInt() ?? 0,
      diemTrungBinh: (tongHop['diemTrungBinh'] as num?)?.toDouble(),
    );
  }
}
