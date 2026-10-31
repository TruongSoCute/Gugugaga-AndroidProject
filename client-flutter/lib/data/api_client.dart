import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config.dart';
import 'token_store.dart';

/// Lỗi gọi API đã chuyển thành thông điệp hiển thị được cho người dùng.
class ApiException implements Exception {
  final String thongDiep;

  /// Mã HTTP; null nếu lỗi mạng (không tới được máy chủ).
  final int? maHttp;

  const ApiException(this.thongDiep, {this.maHttp});

  bool get loiMang => maHttp == null;

  @override
  String toString() => thongDiep;
}

/// Một ApiClient dùng chung cho cả app: gắn token (nếu đã đăng nhập), đặt timeout,
/// đọc lỗi dạng { "loi": { "thongDiep" } } của backend. Màn hình không gọi http trực tiếp
/// mà đi qua repository (docs/development/Architecture.md).
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<dynamic> get(String duongDan, {Map<String, String>? query}) async {
    final uri = Uri.parse('$_baseUrl$duongDan').replace(
      queryParameters: (query == null || query.isEmpty) ? null : query,
    );
    final headers = <String, String>{'Accept': 'application/json'};
    final token = await TokenStore.layToken();
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final http.Response res;
    try {
      res = await _client.get(uri, headers: headers).timeout(AppConfig.timeout);
    } on SocketException {
      throw const ApiException('Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại.');
    } on TimeoutException {
      throw const ApiException('Máy chủ phản hồi quá lâu. Vui lòng thử lại.');
    } on http.ClientException {
      throw const ApiException('Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại.');
    }

    final body = utf8.decode(res.bodyBytes);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(body);
    }
    throw ApiException(
      thongDiepLoi(body) ?? 'Lỗi máy chủ (mã ${res.statusCode}). Vui lòng thử lại sau.',
      maHttp: res.statusCode,
    );
  }

  /// Tách loi.thongDiep từ JSON lỗi của backend; trả null nếu không đọc được.
  static String? thongDiepLoi(String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map<String, dynamic>) {
        final loi = json['loi'];
        if (loi is Map<String, dynamic> && loi['thongDiep'] is String) {
          return loi['thongDiep'] as String;
        }
      }
    } on FormatException {
      // Không phải JSON (vd trang lỗi HTML của proxy).
    }
    return null;
  }
}
