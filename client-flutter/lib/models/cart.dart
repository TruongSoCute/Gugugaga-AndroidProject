/// Một dòng trong giỏ (GET /gio-hang). `gia` là giá hiện hành do backend trả.
class CartItem {
  final int sanPhamId;
  final String ten;
  final String? anhUrl;
  final String donViTinh;
  final int gia;
  final int soLuong;
  final int thanhTien;
  final bool dangBan;
  final int conHang;

  const CartItem({
    required this.sanPhamId,
    required this.ten,
    required this.donViTinh,
    required this.gia,
    required this.soLuong,
    required this.thanhTien,
    required this.dangBan,
    required this.conHang,
    this.anhUrl,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        sanPhamId: (json['sanPhamId'] as num).toInt(),
        ten: json['ten'] as String,
        anhUrl: json['anhUrl'] as String?,
        donViTinh: json['donViTinh'] as String? ?? '',
        gia: (json['gia'] as num).toInt(),
        soLuong: (json['soLuong'] as num).toInt(),
        thanhTien: (json['thanhTien'] as num).toInt(),
        dangBan: json['dangBan'] as bool? ?? true,
        conHang: (json['conHang'] as num?)?.toInt() ?? 0,
      );
}

/// Giỏ hàng: { duLieu, tamTinh }. `tamTinh` chỉ cộng sản phẩm còn bán (backend tính).
class Cart {
  final List<CartItem> duLieu;
  final int tamTinh;

  const Cart({required this.duLieu, required this.tamTinh});

  bool get trong => duLieu.isEmpty;

  /// Số lượng đang có trong giỏ của một sản phẩm (0 nếu chưa có).
  int soLuongCua(int sanPhamId) {
    for (final d in duLieu) {
      if (d.sanPhamId == sanPhamId) return d.soLuong;
    }
    return 0;
  }

  factory Cart.fromJson(Map<String, dynamic> json) => Cart(
        duLieu: (json['duLieu'] as List<dynamic>)
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        tamTinh: (json['tamTinh'] as num?)?.toInt() ?? 0,
      );
}
