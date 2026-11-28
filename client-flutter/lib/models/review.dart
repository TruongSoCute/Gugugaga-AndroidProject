/// Một đánh giá công khai (GET /danh-gia, danhGiaGanDay của chi tiết sản phẩm).
/// Không có email hay số điện thoại người đánh giá.
class Review {
  final int soSao;
  final String? noiDung;
  final String taoLuc;
  final String tenNguoiDanhGia;
  final List<String> anh;

  const Review({
    required this.soSao,
    required this.taoLuc,
    required this.tenNguoiDanhGia,
    required this.anh,
    this.noiDung,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        soSao: (json['soSao'] as num).toInt(),
        noiDung: json['noiDung'] as String?,
        taoLuc: json['taoLuc'] as String,
        tenNguoiDanhGia: json['tenNguoiDanhGia'] as String? ?? '',
        anh: (json['anh'] as List<dynamic>? ?? const []).map((e) => e as String).toList(),
      );
}

/// Trang đánh giá: { duLieu, phanTrang, tongHop: { soDanhGia, diemTrungBinh } }.
class ReviewPage {
  final List<Review> duLieu;
  final int soDanhGia;
  final double? diemTrungBinh;

  const ReviewPage({required this.duLieu, required this.soDanhGia, this.diemTrungBinh});

  factory ReviewPage.fromJson(Map<String, dynamic> json) {
    final tongHop = json['tongHop'] as Map<String, dynamic>? ?? const {};
    return ReviewPage(
      duLieu: (json['duLieu'] as List<dynamic>)
          .map((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList(),
      soDanhGia: (tongHop['soDanhGia'] as num?)?.toInt() ?? 0,
      diemTrungBinh: (tongHop['diemTrungBinh'] as num?)?.toDouble(),
    );
  }
}
