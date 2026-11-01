import 'dart:convert';

/// Các hàm validator dùng cho Form (trả thông điệp lỗi, hoặc null nếu hợp lệ).
/// Quy tắc giống backend (backend/src/utils/validator.js) để chặn sớm dữ liệu sai;
/// backend vẫn kiểm tra lại, app không phải nơi quyết định.
class KiemTra {
  KiemTra._();

  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _sdt = RegExp(r'^\+?[0-9]{8,15}$');
  static final _ngay = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  static String? batBuoc(String? v, [String ten = 'thông tin này']) =>
      (v == null || v.trim().isEmpty) ? 'Vui lòng nhập $ten' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
    if (!_email.hasMatch(v.trim()) || v.length > 255) return 'Email không hợp lệ';
    return null;
  }

  static String? matKhau(String? v) {
    if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (v.length < 8) return 'Mật khẩu cần ít nhất 8 ký tự';
    if (utf8.encode(v).length > 72) return 'Mật khẩu quá dài';
    return null;
  }

  /// Số điện thoại 8–15 chữ số, cho phép dấu cách, chấm, gạch và dấu + ở đầu.
  static String? soDienThoai(String? v, {bool batBuoc = true}) {
    if (v == null || v.trim().isEmpty) return batBuoc ? 'Vui lòng nhập số điện thoại' : null;
    if (!_sdt.hasMatch(v.replaceAll(RegExp(r'[\s.-]'), ''))) return 'Số điện thoại không hợp lệ';
    return null;
  }

  static String? doDaiToiDa(String? v, int toiDa) =>
      (v != null && v.trim().length > toiDa) ? 'Tối đa $toiDa ký tự' : null;

  /// Giá bán: số nguyên VND từ 1 đến 1 tỷ.
  static String? gia(String? v) {
    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập giá';
    final so = int.tryParse(v.trim());
    if (so == null) return 'Giá là số nguyên (đồng), không có dấu chấm';
    if (so < 1 || so > 1000000000) return 'Giá từ 1 đến 1.000.000.000 đ';
    return null;
  }

  /// Đường dẫn ảnh http(s), không bắt buộc.
  static String? urlTuyChon(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final u = Uri.tryParse(v.trim());
    if (u == null || !(u.scheme == 'http' || u.scheme == 'https') || u.host.isEmpty) {
      return 'Đường dẫn phải bắt đầu bằng http:// hoặc https://';
    }
    return null;
  }

  /// Ngày dạng YYYY-MM-DD có thật.
  static bool laNgay(String v) {
    if (!_ngay.hasMatch(v)) return false;
    final t = DateTime.tryParse(v);
    return t != null && t.toIso8601String().startsWith(v);
  }
}
