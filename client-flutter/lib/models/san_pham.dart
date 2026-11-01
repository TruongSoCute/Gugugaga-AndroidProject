/// Sản phẩm đã công bố (GET /san-pham). Tên trường khớp JSON camelCase của backend.
class SanPham {
  final int id;
  final String ten;
  final String? moTa;
  final String donViTinh;
  final int gia;
  final int? hangSao;
  final String? anhUrl;
  final String tenNhaCungCap;
  final String tenVung;
  final int soDanhGia;
  final double? diemTrungBinh;

  const SanPham({
    required this.id,
    required this.ten,
    required this.donViTinh,
    required this.gia,
    required this.tenNhaCungCap,
    required this.tenVung,
    this.moTa,
    this.hangSao,
    this.anhUrl,
    this.soDanhGia = 0,
    this.diemTrungBinh,
  });

  factory SanPham.fromJson(Map<String, dynamic> json) => SanPham(
        id: json['id'] as int,
        ten: json['ten'] as String,
        moTa: json['moTa'] as String?,
        donViTinh: json['donViTinh'] as String? ?? '',
        gia: (json['gia'] as num).toInt(),
        hangSao: json['hangSao'] as int?,
        anhUrl: json['anhUrl'] as String?,
        tenNhaCungCap: json['tenNhaCungCap'] as String? ?? '',
        tenVung: json['tenVung'] as String? ?? '',
        soDanhGia: (json['soDanhGia'] as num?)?.toInt() ?? 0,
        diemTrungBinh: (json['diemTrungBinh'] as num?)?.toDouble(),
      );
}

/// Một trang kết quả: { duLieu: [...], phanTrang: { trang, kichThuoc, tong } }.
class TrangSanPham {
  final List<SanPham> duLieu;
  final int tong;

  const TrangSanPham({required this.duLieu, required this.tong});

  factory TrangSanPham.fromJson(Map<String, dynamic> json) => TrangSanPham(
        duLieu: (json['duLieu'] as List<dynamic>)
            .map((e) => SanPham.fromJson(e as Map<String, dynamic>))
            .toList(),
        tong: ((json['phanTrang'] as Map<String, dynamic>)['tong'] as num).toInt(),
      );
}
