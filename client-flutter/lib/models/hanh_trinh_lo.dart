import 'chung_nhan.dart';

export 'chung_nhan.dart';

/// Hành trình công khai của ĐÚNG MỘT lô (GET /truy-xuat/:maTruyXuat).
/// Đây là dữ liệu của lô, không phải thông tin chung của sản phẩm.
class HanhTrinhLo {
  final String maTruyXuat;
  final String ngaySanXuat;
  final String hanSuDung;
  final String nguoiSanXuat;
  final String? anhHienTruongUrl;
  final String vungNguyenLieu;
  final int sanPhamId;
  final String tenSanPham;
  final int? hangSao;
  final String? anhSanPhamUrl;
  final String tenNhaCungCap;
  final String diaChiNhaCungCap;
  final List<ChungNhan> chungNhan;
  final List<BuocTruyXuat> cacBuoc;

  const HanhTrinhLo({
    required this.maTruyXuat,
    required this.ngaySanXuat,
    required this.hanSuDung,
    required this.nguoiSanXuat,
    required this.vungNguyenLieu,
    required this.sanPhamId,
    required this.tenSanPham,
    required this.tenNhaCungCap,
    required this.diaChiNhaCungCap,
    required this.chungNhan,
    required this.cacBuoc,
    this.anhHienTruongUrl,
    this.hangSao,
    this.anhSanPhamUrl,
  });

  factory HanhTrinhLo.fromJson(Map<String, dynamic> json) {
    final lo = json['lo'] as Map<String, dynamic>;
    final sp = json['sanPham'] as Map<String, dynamic>;
    final ncc = json['nhaCungCap'] as Map<String, dynamic>;
    return HanhTrinhLo(
      maTruyXuat: json['maTruyXuat'] as String,
      ngaySanXuat: lo['ngaySanXuat'] as String,
      hanSuDung: lo['hanSuDung'] as String,
      nguoiSanXuat: lo['nguoiSanXuat'] as String,
      anhHienTruongUrl: lo['anhHienTruongUrl'] as String?,
      vungNguyenLieu: (lo['vungNguyenLieu'] as Map<String, dynamic>)['ten'] as String,
      sanPhamId: (sp['id'] as num?)?.toInt() ?? 0,
      tenSanPham: sp['ten'] as String,
      hangSao: sp['hangSao'] as int?,
      anhSanPhamUrl: sp['anhUrl'] as String?,
      tenNhaCungCap: ncc['ten'] as String,
      diaChiNhaCungCap: ncc['diaChi'] as String? ?? '',
      chungNhan: docDsChungNhan(ncc['chungNhan']),
      cacBuoc: (json['cacBuoc'] as List<dynamic>)
          .map((e) => BuocTruyXuat.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BuocTruyXuat {
  final int thuTu;
  final String tenBuoc;
  final String? moTa;
  final String thoiDiem;
  final String? anhUrl;

  const BuocTruyXuat({
    required this.thuTu,
    required this.tenBuoc,
    required this.thoiDiem,
    this.moTa,
    this.anhUrl,
  });

  factory BuocTruyXuat.fromJson(Map<String, dynamic> json) => BuocTruyXuat(
        thuTu: json['thuTu'] as int,
        tenBuoc: json['tenBuoc'] as String,
        moTa: json['moTa'] as String?,
        thoiDiem: json['thoiDiem'] as String,
        anhUrl: json['anhUrl'] as String?,
      );
}
