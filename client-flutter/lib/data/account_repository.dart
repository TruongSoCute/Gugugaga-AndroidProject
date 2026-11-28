import '../models/user.dart';
import 'api_client.dart';
import 'auth_session.dart';
import 'token_store.dart';

/// Đăng ký, đăng nhập, đăng xuất và khôi phục phiên khi mở lại app.
class AccountRepository {
  AccountRepository(this._api);

  final ApiClient _api;

  /// POST /auth/dang-nhap. Thành công thì lưu token (shared_preferences) và cập nhật phiên.
  Future<User> dangNhap({required String email, required String matKhau}) async {
    final json = await _api.post('/auth/dang-nhap', body: {'email': email.trim(), 'matKhau': matKhau});
    return _luuPhien(LoginResult.fromJson(json as Map<String, dynamic>));
  }

  /// POST /auth/dang-ky. `loaiTaiKhoan` chỉ là KHACH hoặc NHA_CUNG_CAP (backend kiểm tra lại).
  Future<User> dangKy({
    required String email,
    required String matKhau,
    required String hoTen,
    String? soDienThoai,
    String loaiTaiKhoan = UserRole.khach,
  }) async {
    final json = await _api.post('/auth/dang-ky', body: {
      'email': email.trim(),
      'matKhau': matKhau,
      'hoTen': hoTen.trim(),
      if (soDienThoai != null && soDienThoai.trim().isNotEmpty) 'soDienThoai': soDienThoai.trim(),
      'loaiTaiKhoan': loaiTaiKhoan,
    });
    return _luuPhien(LoginResult.fromJson(json as Map<String, dynamic>));
  }

  Future<User> _luuPhien(LoginResult kq) async {
    await TokenStore.luuToken(kq.token);
    await TokenStore.luuNguoiDung(kq.nguoiDung);
    AuthSession.dat(kq.nguoiDung);
    return kq.nguoiDung;
  }

  /// Mở lại app: đọc phiên đã lưu (không cần mạng). Trả người dùng hoặc null.
  Future<User?> khoiPhucPhien() async {
    final token = await TokenStore.layToken();
    final nd = token == null ? null : await TokenStore.layNguoiDung();
    AuthSession.dat(nd);
    return nd;
  }

  /// GET /auth/toi: kiểm tra token còn hạn. 401 thì ApiClient tự xóa phiên.
  /// Lỗi mạng thì giữ phiên đã lưu (Render có thể đang ngủ).
  Future<void> kiemTraPhien() async {
    if (await TokenStore.layToken() == null) return;
    try {
      final nd = User.fromJson(await _api.get('/auth/toi') as Map<String, dynamic>);
      await TokenStore.luuNguoiDung(nd);
      AuthSession.dat(nd);
    } on ApiException {
      // 401 đã được ApiClient xử lý; lỗi khác bỏ qua.
    }
  }

  Future<void> dangXuat() async {
    await TokenStore.xoa();
    AuthSession.dat(null);
  }
}
