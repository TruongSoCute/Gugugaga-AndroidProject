import '../models/san_pham.dart';
import '../models/vung.dart';
import 'api_client.dart';

/// Lấy danh mục và sản phẩm đã công bố. Không cần đăng nhập.
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
}
