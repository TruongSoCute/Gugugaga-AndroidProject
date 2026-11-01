/// Loại và trạng thái phản ánh (khớp backend).
class LoaiPhanAnh {
  LoaiPhanAnh._();

  static const hangGia = 'HANG_GIA';
  static const saiMoTa = 'SAI_MO_TA';
  static const khac = 'KHAC';

  static const tatCa = [hangGia, saiMoTa, khac];

  static String ten(String ma) => switch (ma) {
        hangGia => 'Nghi hàng giả',
        saiMoTa => 'Sai mô tả',
        khac => 'Khác',
        _ => ma,
      };
}

class TrangThaiPhanAnh {
  TrangThaiPhanAnh._();

  static String ten(String ma) => switch (ma) {
        'MOI' => 'Mới gửi',
        'DANG_XU_LY' => 'Đang xử lý',
        'DA_XU_LY' => 'Đã xử lý',
        'BAC_BO' => 'Bác bỏ',
        _ => ma,
      };
}

/// Phản ánh hàng giả/sai mô tả của khách (GET /bao-cao-vi-pham).
class PhanAnh {
  final int id;
  final int sanPhamId;
  final String tenSanPham;
  final String? anhSanPham;
  final String? tenNhaCungCap;
  final String? maTruyXuat;
  final String loai;
  final String noiDung;
  final String? anhUrl;
  final String trangThai;
  final String? ketQuaXuLy;
  final String? xuLyLuc;
  final String taoLuc;

  const PhanAnh({
    required this.id,
    required this.sanPhamId,
    required this.tenSanPham,
    required this.loai,
    required this.noiDung,
    required this.trangThai,
    required this.taoLuc,
    this.anhSanPham,
    this.tenNhaCungCap,
    this.maTruyXuat,
    this.anhUrl,
    this.ketQuaXuLy,
    this.xuLyLuc,
  });

  factory PhanAnh.fromJson(Map<String, dynamic> json) => PhanAnh(
        id: (json['id'] as num).toInt(),
        sanPhamId: (json['sanPhamId'] as num).toInt(),
        tenSanPham: json['tenSanPham'] as String? ?? '',
        anhSanPham: json['anhSanPham'] as String?,
        tenNhaCungCap: json['tenNhaCungCap'] as String?,
        maTruyXuat: json['maTruyXuat'] as String?,
        loai: json['loai'] as String,
        noiDung: json['noiDung'] as String? ?? '',
        anhUrl: json['anhUrl'] as String?,
        trangThai: json['trangThai'] as String,
        ketQuaXuLy: json['ketQuaXuLy'] as String?,
        xuLyLuc: json['xuLyLuc'] as String?,
        taoLuc: json['taoLuc'] as String,
      );
}
