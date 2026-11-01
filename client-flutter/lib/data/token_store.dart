import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/nguoi_dung.dart';

/// Lưu token đăng nhập bằng shared_preferences (yêu cầu C.2 #1).
/// Đây là nơi DUY NHẤT đọc/ghi shared_preferences (test kiến trúc kiểm tra).
/// Lưu kèm thông tin người dùng (không có mật khẩu) để mở lại app vẫn biết vai trò.
class TokenStore {
  TokenStore._();

  static const _keyToken = 'token';
  static const _keyNguoiDung = 'nguoiDung';

  static Future<String?> layToken() async =>
      (await SharedPreferences.getInstance()).getString(_keyToken);

  static Future<void> luuToken(String token) async =>
      (await SharedPreferences.getInstance()).setString(_keyToken, token);

  static Future<void> luuNguoiDung(NguoiDung nguoiDung) async =>
      (await SharedPreferences.getInstance()).setString(_keyNguoiDung, jsonEncode(nguoiDung.toJson()));

  static Future<NguoiDung?> layNguoiDung() async {
    final chuoi = (await SharedPreferences.getInstance()).getString(_keyNguoiDung);
    if (chuoi == null) return null;
    try {
      return NguoiDung.fromJson(jsonDecode(chuoi) as Map<String, dynamic>);
    } on Object {
      return null; // dữ liệu cũ hỏng thì coi như chưa đăng nhập
    }
  }

  /// Xóa phiên (đăng xuất hoặc token hết hạn).
  static Future<void> xoa() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyNguoiDung);
  }
}
