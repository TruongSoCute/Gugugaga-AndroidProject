import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config.dart';
import 'phien_dang_nhap.dart';
import 'token_store.dart';

/// Lỗi gọi API đã chuyển thành thông điệp hiển thị được cho người dùng.
class ApiException implements Exception {
  final String thongDiep;

  /// Mã HTTP; null nếu lỗi mạng (không tới được máy chủ).
  final int? maHttp;

  /// Mã lỗi nghiệp vụ của backend (loi.ma), ví dụ CHUA_CO_HO_SO, CHUA_CAU_HINH_LUU_ANH.
  final String? ma;

  /// Lỗi từng trường (loi.chiTiet) khi dữ liệu không hợp lệ.
  final List<String> chiTiet;

  const ApiException(this.thongDiep, {this.maHttp, this.ma, this.chiTiet = const []});

  bool get loiMang => maHttp == null;

  /// Thông điệp kèm lỗi từng trường (nếu có), để hiện trong SnackBar.
  String get thongDiepDayDu => chiTiet.isEmpty ? thongDiep : '$thongDiep ${chiTiet.join('; ')}';

  @override
  String toString() => thongDiepDayDu;
}

/// Một ApiClient dùng chung cho cả app: gắn token (nếu đã đăng nhập), đặt timeout,
/// đọc lỗi dạng { "loi": { "ma", "thongDiep", "chiTiet" } } của backend.
/// Màn hình không gọi http trực tiếp mà đi qua repository (docs/development/Architecture.md).
///
/// Khi backend trả 401 cho yêu cầu CÓ token (token hết hạn, tài khoản bị khóa): xóa token và
/// báo [PhienDangNhap.baoHetPhien] để app đưa người dùng về màn hình đăng nhập.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  /// Bản dùng chung của app. Kiểm thử có thể thay bằng ApiClient với MockClient.
  static ApiClient macDinh = ApiClient();

  final http.Client _client;
  final String _baseUrl;

  Future<dynamic> get(String duongDan, {Map<String, String>? query}) =>
      _gui('GET', duongDan, query: query);

  Future<dynamic> post(String duongDan, {Object? body, Map<String, String>? query}) =>
      _gui('POST', duongDan, query: query, json: body);

  Future<dynamic> put(String duongDan, {Object? body}) => _gui('PUT', duongDan, json: body);

  Future<dynamic> patch(String duongDan, {Object? body}) => _gui('PATCH', duongDan, json: body);

  Future<dynamic> delete(String duongDan) => _gui('DELETE', duongDan);

  /// Gửi byte thô (tải ảnh): body là byte ảnh, Content-Type image/jpeg|png|webp.
  Future<dynamic> postBytes(
    String duongDan,
    List<int> bytes, {
    required String contentType,
    Map<String, String>? query,
  }) =>
      _gui('POST', duongDan, query: query, bytes: bytes, contentType: contentType);

  Future<dynamic> _gui(
    String phuongThuc,
    String duongDan, {
    Map<String, String>? query,
    Object? json,
    List<int>? bytes,
    String? contentType,
  }) async {
    final uri = Uri.parse('$_baseUrl$duongDan').replace(
      queryParameters: (query == null || query.isEmpty) ? null : query,
    );
    final req = http.Request(phuongThuc, uri);
    req.headers['Accept'] = 'application/json';
    // Đăng nhập/đăng ký không gửi token cũ (sai mật khẩu cũng trả 401, không phải hết phiên).
    final token = duongDan.startsWith('/auth/dang-') ? null : await TokenStore.layToken();
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    if (bytes != null) {
      req.headers['Content-Type'] = contentType ?? 'application/octet-stream';
      req.bodyBytes = bytes;
    } else if (json != null) {
      req.headers['Content-Type'] = 'application/json; charset=utf-8';
      req.bodyBytes = utf8.encode(jsonEncode(json));
    }

    final http.Response res;
    try {
      final streamed = await _client.send(req).timeout(AppConfig.timeout);
      res = await http.Response.fromStream(streamed).timeout(AppConfig.timeout);
    } on SocketException {
      throw _loiMang('Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại.', phuongThuc, duongDan);
    } on TimeoutException {
      throw _loiMang('Máy chủ phản hồi quá lâu. Vui lòng thử lại.', phuongThuc, duongDan);
    } on http.ClientException {
      throw _loiMang('Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại.', phuongThuc, duongDan);
    }

    final body = utf8.decode(res.bodyBytes, allowMalformed: true);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body.isEmpty ? null : jsonDecode(body);
    }
    dev.log('$phuongThuc $duongDan -> ${res.statusCode}', name: AppConfig.tag);

    if (res.statusCode == 401 && token != null) {
      // Token hết hạn/không còn hợp lệ: xóa phiên và báo app quay về đăng nhập.
      await TokenStore.xoa();
      PhienDangNhap.baoHetPhien();
      throw ApiException('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
          maHttp: 401, ma: maLoi(body));
    }
    throw ApiException(
      thongDiepLoi(body) ?? 'Lỗi máy chủ (mã ${res.statusCode}). Vui lòng thử lại sau.',
      maHttp: res.statusCode,
      ma: maLoi(body),
      chiTiet: chiTietLoi(body),
    );
  }

  ApiException _loiMang(String thongDiep, String phuongThuc, String duongDan) {
    dev.log('$phuongThuc $duongDan -> lỗi mạng', name: AppConfig.tag);
    return ApiException(thongDiep);
  }

  static Map<String, dynamic>? _docLoi(String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map<String, dynamic> && json['loi'] is Map<String, dynamic>) {
        return json['loi'] as Map<String, dynamic>;
      }
    } on FormatException {
      // Không phải JSON (vd trang lỗi HTML của proxy).
    }
    return null;
  }

  /// Tách loi.thongDiep từ JSON lỗi của backend; trả null nếu không đọc được.
  static String? thongDiepLoi(String body) {
    final loi = _docLoi(body);
    return loi?['thongDiep'] is String ? loi!['thongDiep'] as String : null;
  }

  /// Tách loi.ma (mã lỗi nghiệp vụ).
  static String? maLoi(String body) {
    final loi = _docLoi(body);
    return loi?['ma'] is String ? loi!['ma'] as String : null;
  }

  /// Tách loi.chiTiet thành các dòng "trường: thông điệp".
  static List<String> chiTietLoi(String body) {
    final ds = _docLoi(body)?['chiTiet'];
    if (ds is! List) return const [];
    return [
      for (final e in ds)
        if (e is Map && e['thongDiep'] is String) e['thongDiep'] as String,
    ];
  }
}
