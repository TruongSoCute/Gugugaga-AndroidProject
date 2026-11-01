/// Vai trò tài khoản do backend cấp. App Client dùng cho KHACH và NHA_CUNG_CAP.
class VaiTro {
  VaiTro._();

  static const khach = 'KHACH';
  static const nhaCungCap = 'NHA_CUNG_CAP';
}

/// Tài khoản đang đăng nhập (POST /auth/dang-nhap, GET /auth/toi). Không bao giờ có mật khẩu.
class NguoiDung {
  final int id;
  final String email;
  final String hoTen;
  final String? soDienThoai;
  final String vaiTro;

  const NguoiDung({
    required this.id,
    required this.email,
    required this.hoTen,
    required this.vaiTro,
    this.soDienThoai,
  });

  bool get laKhach => vaiTro == VaiTro.khach;
  bool get laNhaCungCap => vaiTro == VaiTro.nhaCungCap;

  String get tenVaiTro => switch (vaiTro) {
        VaiTro.khach => 'Khách hàng',
        VaiTro.nhaCungCap => 'Nhà cung cấp',
        _ => vaiTro,
      };

  factory NguoiDung.fromJson(Map<String, dynamic> json) => NguoiDung(
        id: (json['id'] as num).toInt(),
        email: json['email'] as String,
        hoTen: json['hoTen'] as String? ?? '',
        soDienThoai: json['soDienThoai'] as String?,
        vaiTro: json['vaiTro'] as String,
      );

  /// Dùng để lưu thông tin phiên cạnh token (mở lại app vẫn biết vai trò).
  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'hoTen': hoTen,
        'soDienThoai': soDienThoai,
        'vaiTro': vaiTro,
      };
}

/// Kết quả đăng nhập/đăng ký: { token, nguoiDung }.
class KetQuaDangNhap {
  final String token;
  final NguoiDung nguoiDung;

  const KetQuaDangNhap({required this.token, required this.nguoiDung});

  factory KetQuaDangNhap.fromJson(Map<String, dynamic> json) => KetQuaDangNhap(
        token: json['token'] as String,
        nguoiDung: NguoiDung.fromJson(json['nguoiDung'] as Map<String, dynamic>),
      );
}
