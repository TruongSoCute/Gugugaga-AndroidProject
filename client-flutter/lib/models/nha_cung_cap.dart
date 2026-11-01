import 'chung_nhan.dart';
import 'san_pham.dart';

/// Trang công khai của nhà cung cấp đã duyệt (GET /nha-cung-cap/:id).
class NhaCungCap {
  final int id;
  final String ten;
  final String? nguoiDaiDien;
  final String? soDienThoai;
  final String diaChi;
  final String tenVung;
  final String? anhCoSoUrl;
  final int soNguoiTheoDoi;
  final List<ChungNhan> chungNhan;
  final List<SanPhamTomTat> sanPham;

  const NhaCungCap({
    required this.id,
    required this.ten,
    required this.diaChi,
    required this.tenVung,
    required this.chungNhan,
    required this.sanPham,
    this.nguoiDaiDien,
    this.soDienThoai,
    this.anhCoSoUrl,
    this.soNguoiTheoDoi = 0,
  });

  factory NhaCungCap.fromJson(Map<String, dynamic> json) => NhaCungCap(
        id: (json['id'] as num).toInt(),
        ten: json['ten'] as String,
        nguoiDaiDien: json['nguoiDaiDien'] as String?,
        soDienThoai: json['soDienThoai'] as String?,
        diaChi: json['diaChi'] as String? ?? '',
        tenVung: json['tenVung'] as String? ?? '',
        anhCoSoUrl: json['anhCoSoUrl'] as String?,
        soNguoiTheoDoi: (json['soNguoiTheoDoi'] as num?)?.toInt() ?? 0,
        chungNhan: docDsChungNhan(json['chungNhan']),
        sanPham: (json['sanPham'] as List<dynamic>? ?? const [])
            .map((e) => SanPhamTomTat.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Nhà cung cấp khách đang theo dõi (GET /theo-doi).
class NhaCungCapTheoDoi {
  final int id;
  final String ten;
  final String diaChi;
  final String? anhCoSoUrl;
  final String tenVung;
  final int soSanPham;

  const NhaCungCapTheoDoi({
    required this.id,
    required this.ten,
    required this.diaChi,
    required this.tenVung,
    this.anhCoSoUrl,
    this.soSanPham = 0,
  });

  factory NhaCungCapTheoDoi.fromJson(Map<String, dynamic> json) => NhaCungCapTheoDoi(
        id: (json['id'] as num).toInt(),
        ten: json['ten'] as String,
        diaChi: json['diaChi'] as String? ?? '',
        anhCoSoUrl: json['anhCoSoUrl'] as String?,
        tenVung: json['tenVung'] as String? ?? '',
        soSanPham: (json['soSanPham'] as num?)?.toInt() ?? 0,
      );
}

/// Hồ sơ của chính nhà cung cấp đang đăng nhập (GET /cua-toi/nha-cung-cap).
class HoSoNhaCungCap {
  final int id;
  final String ten;
  final String nguoiDaiDien;
  final String soDienThoai;
  final String diaChi;
  final int vungId;
  final String tenVung;
  final String? anhCoSoUrl;
  final String trangThaiDuyet;
  final String? lyDoTuChoi;
  final String? duyetLuc;
  final List<ChungNhan> chungNhan;

  const HoSoNhaCungCap({
    required this.id,
    required this.ten,
    required this.nguoiDaiDien,
    required this.soDienThoai,
    required this.diaChi,
    required this.vungId,
    required this.tenVung,
    required this.trangThaiDuyet,
    required this.chungNhan,
    this.anhCoSoUrl,
    this.lyDoTuChoi,
    this.duyetLuc,
  });

  /// Hồ sơ đã duyệt thì backend không cho sửa (409 HO_SO_DA_DUYET).
  bool get duocSua => trangThaiDuyet != TrangThaiDuyet.daDuyet;

  factory HoSoNhaCungCap.fromJson(Map<String, dynamic> json) => HoSoNhaCungCap(
        id: (json['id'] as num).toInt(),
        ten: json['ten'] as String,
        nguoiDaiDien: json['nguoiDaiDien'] as String? ?? '',
        soDienThoai: json['soDienThoai'] as String? ?? '',
        diaChi: json['diaChi'] as String? ?? '',
        vungId: (json['vungId'] as num).toInt(),
        tenVung: json['tenVung'] as String? ?? '',
        anhCoSoUrl: json['anhCoSoUrl'] as String?,
        trangThaiDuyet: json['trangThaiDuyet'] as String,
        lyDoTuChoi: json['lyDoTuChoi'] as String?,
        duyetLuc: json['duyetLuc'] as String?,
        chungNhan: docDsChungNhan(json['chungNhan']),
      );
}
