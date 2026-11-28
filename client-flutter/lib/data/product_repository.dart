import '../models/review.dart';
import '../models/supplier.dart';
import '../models/product.dart';
import '../models/sourcing_region.dart';
import 'api_client.dart';

/// Lấy danh mục, sản phẩm và nhà cung cấp đã công bố. Không cần đăng nhập.
class ProductRepository {
  ProductRepository(this._api);

  final ApiClient _api;

  Future<List<SourcingRegion>> dsVung() async {
    final json = await _api.get('/vung-nguyen-lieu') as List<dynamic>;
    return json.map((e) => SourcingRegion.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /san-pham?vung=&hangSao=&tuKhoa= (lọc theo vùng và hạng sao — chức năng bắt buộc).
  Future<ProductPage> dsSanPham({int? vungId, int? hangSao, String? tuKhoa}) async {
    final query = <String, String>{'kichThuoc': '100'};
    if (vungId != null) query['vung'] = '$vungId';
    if (hangSao != null) query['hangSao'] = '$hangSao';
    if (tuKhoa != null && tuKhoa.trim().isNotEmpty) query['tuKhoa'] = tuKhoa.trim();
    final json = await _api.get('/san-pham', query: query) as Map<String, dynamic>;
    return ProductPage.fromJson(json);
  }

  /// GET /san-pham/:id: thông tin, nhà cung cấp, chứng nhận, đánh giá gần đây.
  Future<ProductDetails> chiTiet(int id) async =>
      ProductDetails.fromJson(await _api.get('/san-pham/$id') as Map<String, dynamic>);

  /// GET /danh-gia?sanPhamId= (công khai), kèm ảnh thật của người mua.
  Future<ReviewPage> dsDanhGia(int sanPhamId) async => ReviewPage.fromJson(
      await _api.get('/danh-gia', query: {'sanPhamId': '$sanPhamId', 'kichThuoc': '50'})
          as Map<String, dynamic>);

  /// GET /nha-cung-cap/:id: chứng nhận và sản phẩm đã duyệt.
  Future<Supplier> nhaCungCap(int id) async =>
      Supplier.fromJson(await _api.get('/nha-cung-cap/$id') as Map<String, dynamic>);
}
