import '../models/danh_gia.dart';
import '../models/nha_cung_cap.dart';
import '../models/san_pham.dart';
import '../models/vung.dart';
import 'api_client.dart';

/// Lấy danh mục, sản phẩm và nhà cung cấp đã công bố. Không cần đăng nhập.
class SanPhamRepository {
  SanPhamRepository(this._api);

  final ApiClient _api;

  Future<List<Vung>> dsVung() async {
    final json = await _api.get('/vung-nguyen-lieu') as List<dynamic>;
    return json.map((e) => Vung.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /san-pham?vung=&hangSao=&tuKhoa= (lọc theo vùng và hạng sao — chức năng bắt buộc).
  Future<TrangSanPham> dsSanPham({int? vungId, int? hangSao, String? tuKhoa}) async {
    final query = <String, String>{'kichThuoc': '100'};
    if (vungId != null) query['vung'] = '$vungId';
    if (hangSao != null) query['hangSao'] = '$hangSao';
    if (tuKhoa != null && tuKhoa.trim().isNotEmpty) query['tuKhoa'] = tuKhoa.trim();
    final json = await _api.get('/san-pham', query: query) as Map<String, dynamic>;
    return TrangSanPham.fromJson(json);
  }

  /// GET /san-pham/:id: thông tin, nhà cung cấp, chứng nhận, đánh giá gần đây.
  Future<ChiTietSanPham> chiTiet(int id) async =>
      ChiTietSanPham.fromJson(await _api.get('/san-pham/$id') as Map<String, dynamic>);

  /// GET /danh-gia?sanPhamId= (công khai), kèm ảnh thật của người mua.
  Future<TrangDanhGia> dsDanhGia(int sanPhamId) async => TrangDanhGia.fromJson(
      await _api.get('/danh-gia', query: {'sanPhamId': '$sanPhamId', 'kichThuoc': '50'})
          as Map<String, dynamic>);

  /// GET /nha-cung-cap/:id: chứng nhận và sản phẩm đã duyệt.
  Future<NhaCungCap> nhaCungCap(int id) async =>
      NhaCungCap.fromJson(await _api.get('/nha-cung-cap/$id') as Map<String, dynamic>);
}
