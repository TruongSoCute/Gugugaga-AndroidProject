import 'package:shared_preferences/shared_preferences.dart';

/// Lưu token đăng nhập bằng shared_preferences (yêu cầu C.2 #1).
/// Màn hình đăng nhập/đăng ký của Client sẽ ghi token vào đây.
class TokenStore {
  TokenStore._();

  static const _keyToken = 'token';

  static Future<String?> layToken() async =>
      (await SharedPreferences.getInstance()).getString(_keyToken);

  static Future<void> luuToken(String token) async =>
      (await SharedPreferences.getInstance()).setString(_keyToken, token);

  static Future<void> xoa() async =>
      (await SharedPreferences.getInstance()).remove(_keyToken);
}
