import '../models/chung_nhan.dart';
import '../models/nha_cung_cap.dart';
import '../models/san_pham.dart';
import 'api_client.dart';

/// Nhà cung cấp tự quản lý hồ sơ và sản phẩm của mình (vai trò NHA_CUNG_CAP).
/// Backend luôn đưa hồ sơ/sản phẩm về CHO_DUYET; quản trị duyệt trên app Admin.
class CuaToiRepository {
  CuaToiRepository(this._api);

  final ApiClient _api;

  /// GET /cua-toi/nha-cung-cap. Trả null khi chưa gửi hồ sơ (404 CHUA_CO_HO_SO).
  Future<HoSoNhaCungCap?> hoSo() async {
    try {
      return HoSoNhaCungCap.fromJson(await _api.get('/cua-toi/nha-cung-cap') as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.maHttp == 404) return null;
      rethrow;
    }
  }

  /// POST (tạo mới) hoặc PUT (sửa, gửi duyệt lại) /cua-toi/nha-cung-cap.
  Future<HoSoNhaCungCap> luuHoSo({
    required bool taoMoi,
    required String ten,
    required String nguoiDaiDien,
    required String soDienThoai,
    required String diaChi,
    required int vungId,
    String? anhCoSoUrl,
    List<ChungNhan> chungNhan = const [],
  }) async {
    final body = {
      'ten': ten.trim(),
      'nguoiDaiDien': nguoiDaiDien.trim(),
      'soDienThoai': soDienThoai.trim(),
      'diaChi': diaChi.trim(),
      'vungId': vungId,
      if (anhCoSoUrl != null && anhCoSoUrl.trim().isNotEmpty) 'anhCoSoUrl': anhCoSoUrl.trim(),
      'chungNhan': [for (final cn in chungNhan) cn.toJson()],
    };
    final json = taoMoi
        ? await _api.post('/cua-toi/nha-cung-cap', body: body)
        : await _api.put('/cua-toi/nha-cung-cap', body: body);
    return HoSoNhaCungCap.fromJson(json as Map<String, dynamic>);
  }

  Future<List<SanPhamCuaToi>> dsSanPham() async => (await _api.get('/cua-toi/san-pham') as List<dynamic>)
      .map((e) => SanPhamCuaToi.fromJson(e as Map<String, dynamic>))
      .toList();

  /// POST /cua-toi/san-pham (id null) hoặc PUT /cua-toi/san-pham/:id.
  Future<SanPhamCuaToi> luuSanPham({
    int? id,
    required String ten,
    required int gia,
    String? donViTinh,
    String? moTa,
    String? anhUrl,
  }) async {
    final body = {
      'ten': ten.trim(),
      'gia': gia,
      if (donViTinh != null && donViTinh.trim().isNotEmpty) 'donViTinh': donViTinh.trim(),
      if (moTa != null && moTa.trim().isNotEmpty) 'moTa': moTa.trim(),
      if (anhUrl != null && anhUrl.trim().isNotEmpty) 'anhUrl': anhUrl.trim(),
    };
    final json = id == null
        ? await _api.post('/cua-toi/san-pham', body: body)
        : await _api.put('/cua-toi/san-pham/$id', body: body);
    return SanPhamCuaToi.fromJson(json as Map<String, dynamic>);
  }
}
