import '../models/hanh_trinh_lo.dart';
import 'api_client.dart';

/// Truy xuất nguồn gốc theo lô: API CÔNG KHAI, không cần đăng nhập.
class TruyXuatRepository {
  TruyXuatRepository(this._api);

  final ApiClient _api;

  static final RegExp _ma = RegExp(r'^[0-9A-F]{20}$');

  /// Nhận mã 20 ký tự hex HOẶC nội dung QR dạng `.../truy-xuat/MA`.
  /// Trả mã đã chuẩn hóa (in hoa), hoặc null nếu không hợp lệ.
  static String? tachMa(String noiDung) {
    var s = noiDung.trim();
    final viTri = s.lastIndexOf('/truy-xuat/');
    if (viTri >= 0) s = s.substring(viTri + '/truy-xuat/'.length);
    s = s.split(RegExp(r'[/?#]')).first.toUpperCase();
    return _ma.hasMatch(s) ? s : null;
  }

  Future<HanhTrinhLo> layHanhTrinh(String ma) async {
    final json = await _api.get('/truy-xuat/$ma') as Map<String, dynamic>;
    return HanhTrinhLo.fromJson(json);
  }
}
