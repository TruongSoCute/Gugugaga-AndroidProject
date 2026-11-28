import '../models/order.dart';
import '../models/cart.dart';
import 'api_client.dart';

/// Giỏ hàng và đơn hàng của khách. Giá, phí giao, tổng tiền, lô do backend quyết định;
/// app chỉ gửi sản phẩm, số lượng và thông tin người nhận.
class OrderRepository {
  OrderRepository(this._api);

  final ApiClient _api;

  Future<Cart> gioHang() async => Cart.fromJson(await _api.get('/gio-hang') as Map<String, dynamic>);

  /// PUT /gio-hang/:sanPhamId: đặt lại số lượng (1–999), thêm mới nếu chưa có. Trả giỏ mới.
  Future<Cart> datSoLuong(int sanPhamId, int soLuong) async => Cart.fromJson(
      await _api.put('/gio-hang/$sanPhamId', body: {'soLuong': soLuong}) as Map<String, dynamic>);

  /// Thêm vào giỏ: cộng dồn với số lượng đang có (tối đa 999).
  Future<Cart> themVaoGio(int sanPhamId, int soLuong) async {
    final hienCo = (await gioHang()).soLuongCua(sanPhamId);
    final moi = (hienCo + soLuong).clamp(1, 999);
    return datSoLuong(sanPhamId, moi);
  }

  Future<Cart> xoaKhoiGio(int sanPhamId) async =>
      Cart.fromJson(await _api.delete('/gio-hang/$sanPhamId') as Map<String, dynamic>);

  Future<List<DeliveryMethod>> dsHinhThucGiao() async => (await _api.get('/don-hang/hinh-thuc-giao') as List<dynamic>)
      .map((e) => DeliveryMethod.fromJson(e as Map<String, dynamic>))
      .toList();

  /// POST /don-hang không gửi cacDong: đặt toàn bộ giỏ, backend xóa giỏ sau khi đặt.
  Future<Order> datHang({
    required String hinhThucGiao,
    required String tenNguoiNhan,
    required String sdtNguoiNhan,
    required String diaChiGiao,
    String? ghiChu,
  }) async {
    final json = await _api.post('/don-hang', body: {
      'hinhThucGiao': hinhThucGiao,
      'tenNguoiNhan': tenNguoiNhan.trim(),
      'sdtNguoiNhan': sdtNguoiNhan.trim(),
      'diaChiGiao': diaChiGiao.trim(),
      if (ghiChu != null && ghiChu.trim().isNotEmpty) 'ghiChu': ghiChu.trim(),
    });
    return Order.fromJson(json as Map<String, dynamic>);
  }

  Future<List<OrderSummary>> dsDonHang({String? trangThai}) async {
    final query = <String, String>{'kichThuoc': '100'};
    if (trangThai != null) query['trangThai'] = trangThai;
    final json = await _api.get('/don-hang', query: query) as Map<String, dynamic>;
    return (json['duLieu'] as List<dynamic>)
        .map((e) => OrderSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Order> chiTietDon(int id) async =>
      Order.fromJson(await _api.get('/don-hang/$id') as Map<String, dynamic>);

  /// PATCH /don-hang/:id/trang-thai. Khách: DA_HUY (khi chờ xác nhận) hoặc DA_NHAN (khi đã giao).
  Future<Order> doiTrangThai(int id, String trangThai, {String? ghiChu}) async {
    await _api.patch('/don-hang/$id/trang-thai', body: {
      'trangThai': trangThai,
      if (ghiChu != null && ghiChu.isNotEmpty) 'ghiChu': ghiChu,
    });
    return chiTietDon(id);
  }
}
