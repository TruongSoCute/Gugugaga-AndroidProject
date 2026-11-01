/// Giấy chứng nhận của nhà cung cấp (OCOP, ATTP, VietGAP…).
/// Dùng chung cho truy xuất lô, chi tiết sản phẩm, trang nhà cung cấp và hồ sơ của tôi.
class ChungNhan {
  final String loai;
  final String soHieu;
  final String? ngayCap;
  final String? ngayHetHan;
  final String? anhUrl;
  final bool conHieuLuc;

  const ChungNhan({
    required this.loai,
    required this.soHieu,
    required this.conHieuLuc,
    this.ngayCap,
    this.ngayHetHan,
    this.anhUrl,
  });

  factory ChungNhan.fromJson(Map<String, dynamic> json) => ChungNhan(
        loai: json['loai'] as String,
        soHieu: json['soHieu'] as String,
        ngayCap: json['ngayCap'] as String?,
        ngayHetHan: json['ngayHetHan'] as String?,
        anhUrl: json['anhUrl'] as String?,
        conHieuLuc: json['conHieuLuc'] as bool? ?? false,
      );

  /// Body gửi lên khi nhà cung cấp tạo/sửa hồ sơ (không gửi conHieuLuc: backend tự tính).
  Map<String, dynamic> toJson() => {
        'loai': loai,
        'soHieu': soHieu,
        'ngayCap': ngayCap,
        if (ngayHetHan != null && ngayHetHan!.isNotEmpty) 'ngayHetHan': ngayHetHan,
        if (anhUrl != null && anhUrl!.isNotEmpty) 'anhUrl': anhUrl,
      };
}

/// Đọc danh sách chứng nhận (có thể thiếu trong JSON).
List<ChungNhan> docDsChungNhan(Object? json) => (json as List<dynamic>? ?? const [])
    .map((e) => ChungNhan.fromJson(e as Map<String, dynamic>))
    .toList();
