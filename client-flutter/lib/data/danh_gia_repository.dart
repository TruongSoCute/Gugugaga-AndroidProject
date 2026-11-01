import 'api_client.dart';

/// Gửi đánh giá sản phẩm đã mua (đơn DA_NHAN). Danh sách đánh giá công khai ở SanPhamRepository.
class DanhGiaRepository {
  DanhGiaRepository(this._api);

  final ApiClient _api;

  /// POST /danh-gia. `anhUrls` là URL đã tải lên qua TaiAnhRepository (tối đa 5).
  Future<void> guiDanhGia({
    required int donHangId,
    required int sanPhamId,
    required int soSao,
    String? noiDung,
    List<String> anhUrls = const [],
  }) async {
    await _api.post('/danh-gia', body: {
      'donHangId': donHangId,
      'sanPhamId': sanPhamId,
      'soSao': soSao,
      if (noiDung != null && noiDung.trim().isNotEmpty) 'noiDung': noiDung.trim(),
      if (anhUrls.isNotEmpty) 'anhUrls': anhUrls,
    });
  }
}
