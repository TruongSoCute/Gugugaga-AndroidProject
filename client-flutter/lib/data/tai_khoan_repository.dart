import '../models/nguoi_dung.dart';
import 'api_client.dart';
import 'phien_dang_nhap.dart';
import 'token_store.dart';

/// Đăng ký, đăng nhập, đăng xuất và khôi phục phiên khi mở lại app.
class TaiKhoanRepository {
  TaiKhoanRepository(this._api);

  final ApiClient _api;

  /// POST /auth/dang-nhap. Thành công thì lưu token (shared_preferences) và cập nhật phiên.
  Future<NguoiDung> dangNhap({required String email, required String matKhau}) async {
    final json = await _api.post('/auth/dang-nhap', body: {'email': email.trim(), 'matKhau': matKhau});
    return _luuPhien(KetQuaDangNhap.fromJson(json as Map<String, dynamic>));
  }

  /// POST /auth/dang-ky. `loaiTaiKhoan` chỉ là KHACH hoặc NHA_CUNG_CAP (backend kiểm tra lại).
  Future<NguoiDung> dangKy({
    required String email,
    required String matKhau,
    required String hoTen,
    String? soDienThoai,
    String loaiTaiKhoan = VaiTro.khach,
  }) async {
    final json = await _api.post('/auth/dang-ky', body: {
      'email': email.trim(),
      'matKhau': matKhau,
      'hoTen': hoTen.trim(),
      if (soDienThoai != null && soDienThoai.trim().isNotEmpty) 'soDienThoai': soDienThoai.trim(),
      'loaiTaiKhoan': loaiTaiKhoan,
    });
    return _luuPhien(KetQuaDangNhap.fromJson(json as Map<String, dynamic>));
  }

  Future<NguoiDung> _luuPhien(KetQuaDangNhap kq) async {
    await TokenStore.luuToken(kq.token);
    await TokenStore.luuNguoiDung(kq.nguoiDung);
    PhienDangNhap.dat(kq.nguoiDung);
    return kq.nguoiDung;
  }

  /// Mở lại app: đọc phiên đã lưu (không cần mạng). Trả người dùng hoặc null.
  Future<NguoiDung?> khoiPhucPhien() async {
    final token = await TokenStore.layToken();
    final nd = token == null ? null : await TokenStore.layNguoiDung();
    PhienDangNhap.dat(nd);
    return nd;
  }

  /// GET /auth/toi: kiểm tra token còn hạn. 401 thì ApiClient tự xóa phiên.
  /// Lỗi mạng thì giữ phiên đã lưu (Render có thể đang ngủ).
  Future<void> kiemTraPhien() async {
    if (await TokenStore.layToken() == null) return;
    try {
      final nd = NguoiDung.fromJson(await _api.get('/auth/toi') as Map<String, dynamic>);
      await TokenStore.luuNguoiDung(nd);
      PhienDangNhap.dat(nd);
    } on ApiException {
      // 401 đã được ApiClient xử lý; lỗi khác bỏ qua.
    }
  }

  Future<void> dangXuat() async {
    await TokenStore.xoa();
    PhienDangNhap.dat(null);
  }
}
