/// Vai trò tài khoản do backend cấp. App Client dùng cho KHACH và NHA_CUNG_CAP.
class UserRole {
  UserRole._();

  static const khach = 'KHACH';
  static const nhaCungCap = 'NHA_CUNG_CAP';
}

/// Tài khoản đang đăng nhập (POST /auth/dang-nhap, GET /auth/toi). Không bao giờ có mật khẩu.
class User {
  final int id;
  final String email;
  final String hoTen;
  final String? soDienThoai;
  final String vaiTro;

  const User({
    required this.id,
    required this.email,
    required this.hoTen,
    required this.vaiTro,
    this.soDienThoai,
  });

  bool get laKhach => vaiTro == UserRole.khach;
  bool get laNhaCungCap => vaiTro == UserRole.nhaCungCap;

  String get tenVaiTro => switch (vaiTro) {
        UserRole.khach => 'Khách hàng',
        UserRole.nhaCungCap => 'Nhà cung cấp',
        _ => vaiTro,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
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
class LoginResult {
  final String token;
  final User nguoiDung;

  const LoginResult({required this.token, required this.nguoiDung});

  factory LoginResult.fromJson(Map<String, dynamic> json) => LoginResult(
        token: json['token'] as String,
        nguoiDung: User.fromJson(json['nguoiDung'] as Map<String, dynamic>),
      );
}
