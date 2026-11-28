import '../models/supplier.dart';
import '../models/product.dart';
import 'api_client.dart';

/// Yêu thích sản phẩm và theo dõi nhà cung cấp (chỉ khách). PUT/DELETE gọi lại nhiều lần không lỗi.
class CustomerInteractionsRepository {
  CustomerInteractionsRepository(this._api);

  final ApiClient _api;

  Future<List<ProductSummary>> dsYeuThich() async => (await _api.get('/yeu-thich') as List<dynamic>)
      .map((e) => ProductSummary.fromJson(e as Map<String, dynamic>))
      .toList();

  Future<void> yeuThich(int sanPhamId) => _api.put('/yeu-thich/$sanPhamId');

  Future<void> boYeuThich(int sanPhamId) => _api.delete('/yeu-thich/$sanPhamId');

  Future<List<FollowedSupplier>> dsTheoDoi() async => (await _api.get('/theo-doi') as List<dynamic>)
      .map((e) => FollowedSupplier.fromJson(e as Map<String, dynamic>))
      .toList();

  Future<void> theoDoi(int nhaCungCapId) => _api.put('/theo-doi/$nhaCungCapId');

  Future<void> boTheoDoi(int nhaCungCapId) => _api.delete('/theo-doi/$nhaCungCapId');
}
