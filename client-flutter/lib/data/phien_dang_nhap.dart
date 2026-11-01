import 'dart:async';

import '../models/nguoi_dung.dart';

/// Trạng thái phiên đăng nhập dùng chung cho cả app.
///
/// Tầng data không được dùng Flutter (test kiến trúc), nên thay vì ValueNotifier ở đây dùng
/// Stream thuần của Dart: màn hình nghe [thayDoi] bằng StreamBuilder/listen.
/// - [thayDoi]: phát người dùng mới mỗi khi đăng nhập, đăng xuất hoặc hết phiên.
/// - [hetPhien]: phát khi backend trả 401 cho một yêu cầu có token (token hết hạn/bị khóa),
///   để khung app đưa người dùng về màn hình đăng nhập.
class PhienDangNhap {
  PhienDangNhap._();

  static NguoiDung? _hienTai;
  static final _thayDoi = StreamController<NguoiDung?>.broadcast();
  static final _hetPhien = StreamController<void>.broadcast();

  static NguoiDung? get hienTai => _hienTai;
  static bool get daDangNhap => _hienTai != null;
  static bool get laKhach => _hienTai?.laKhach ?? false;
  static bool get laNhaCungCap => _hienTai?.laNhaCungCap ?? false;

  static Stream<NguoiDung?> get thayDoi => _thayDoi.stream;
  static Stream<void> get hetPhien => _hetPhien.stream;

  static void dat(NguoiDung? nguoiDung) {
    _hienTai = nguoiDung;
    _thayDoi.add(nguoiDung);
  }

  /// Gọi từ ApiClient khi nhận 401: token đã bị xóa, báo app quay về đăng nhập.
  static void baoHetPhien() {
    if (_hienTai == null) return; // đã đăng xuất rồi thì không báo lần nữa
    dat(null);
    _hetPhien.add(null);
  }
}
