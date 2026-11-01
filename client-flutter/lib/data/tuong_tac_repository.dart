import '../models/nha_cung_cap.dart';
import '../models/san_pham.dart';
import 'api_client.dart';

/// Yêu thích sản phẩm và theo dõi nhà cung cấp (chỉ khách). PUT/DELETE gọi lại nhiều lần không lỗi.
class TuongTacRepository {
  TuongTacRepository(this._api);

  final ApiClient _api;

  Future<List<SanPhamTomTat>> dsYeuThich() async => (await _api.get('/yeu-thich') as List<dynamic>)
      .map((e) => SanPhamTomTat.fromJson(e as Map<String, dynamic>))
      .toList();

  Future<void> yeuThich(int sanPhamId) => _api.put('/yeu-thich/$sanPhamId');

  Future<void> boYeuThich(int sanPhamId) => _api.delete('/yeu-thich/$sanPhamId');

  Future<List<NhaCungCapTheoDoi>> dsTheoDoi() async => (await _api.get('/theo-doi') as List<dynamic>)
      .map((e) => NhaCungCapTheoDoi.fromJson(e as Map<String, dynamic>))
      .toList();

  Future<void> theoDoi(int nhaCungCapId) => _api.put('/theo-doi/$nhaCungCapId');

  Future<void> boTheoDoi(int nhaCungCapId) => _api.delete('/theo-doi/$nhaCungCapId');
}
