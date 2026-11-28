/// Trạng thái đơn hàng và tên hiển thị (khớp backend).
class OrderStatus {
  OrderStatus._();

  static const choXacNhan = 'CHO_XAC_NHAN';
  static const daXacNhan = 'DA_XAC_NHAN';
  static const dangGiao = 'DANG_GIAO';
  static const daGiao = 'DA_GIAO';
  static const daNhan = 'DA_NHAN';
  static const daHuy = 'DA_HUY';

  static const tatCa = [choXacNhan, daXacNhan, dangGiao, daGiao, daNhan, daHuy];

  static String ten(String ma) => switch (ma) {
        choXacNhan => 'Chờ xác nhận',
        daXacNhan => 'Đã xác nhận',
        dangGiao => 'Đang giao',
        daGiao => 'Đã giao',
        daNhan => 'Đã nhận',
        daHuy => 'Đã hủy',
        _ => ma,
      };
}

/// Hình thức giao (GET /don-hang/hinh-thuc-giao). Phí giao do backend quyết định.
class DeliveryMethod {
  final String ma;
  final String ten;
  final int phiGiao;

  const DeliveryMethod({required this.ma, required this.ten, required this.phiGiao});

  factory DeliveryMethod.fromJson(Map<String, dynamic> json) => DeliveryMethod(
        ma: json['ma'] as String,
        ten: json['ten'] as String,
        phiGiao: (json['phiGiao'] as num).toInt(),
      );
}

/// Một đơn trong danh sách "Đơn hàng của tôi" (GET /don-hang).
class OrderSummary {
  final int id;
  final String trangThai;
  final String hinhThucGiao;
  final int tongTien;
  final String taoLuc;
  final int soSanPham;
  final String? tenSanPhamDau;
  final String? anhSanPhamDau;

  const OrderSummary({
    required this.id,
    required this.trangThai,
    required this.hinhThucGiao,
    required this.tongTien,
    required this.taoLuc,
    this.soSanPham = 0,
    this.tenSanPhamDau,
    this.anhSanPhamDau,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) => OrderSummary(
        id: (json['id'] as num).toInt(),
        trangThai: json['trangThai'] as String,
        hinhThucGiao: json['hinhThucGiao'] as String? ?? '',
        tongTien: (json['tongTien'] as num).toInt(),
        taoLuc: json['taoLuc'] as String,
        soSanPham: (json['soSanPham'] as num?)?.toInt() ?? 0,
        tenSanPhamDau: json['tenSanPhamDau'] as String?,
        anhSanPhamDau: json['anhSanPhamDau'] as String?,
      );
}

/// Một dòng của đơn: sản phẩm, lô đã gán (maTruyXuat) và cờ đã đánh giá.
class OrderItem {
  final int sanPhamId;
  final String tenSanPham;
  final String? anhUrl;
  final String donViTinh;
  final String? maTruyXuat;
  final String? vungNguyenLieu;
  final int soLuong;
  final int donGia;
  final int thanhTien;
  final bool daDanhGia;

  const OrderItem({
    required this.sanPhamId,
    required this.tenSanPham,
    required this.donViTinh,
    required this.soLuong,
    required this.donGia,
    required this.thanhTien,
    this.anhUrl,
    this.maTruyXuat,
    this.vungNguyenLieu,
    this.daDanhGia = false,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        sanPhamId: (json['sanPhamId'] as num).toInt(),
        tenSanPham: json['tenSanPham'] as String,
        anhUrl: json['anhUrl'] as String?,
        donViTinh: json['donViTinh'] as String? ?? '',
        maTruyXuat: json['maTruyXuat'] as String?,
        vungNguyenLieu: json['vungNguyenLieu'] as String?,
        soLuong: (json['soLuong'] as num).toInt(),
        donGia: (json['donGia'] as num).toInt(),
        thanhTien: (json['thanhTien'] as num).toInt(),
        daDanhGia: json['daDanhGia'] as bool? ?? false,
      );
}

/// Một lần đổi trạng thái của đơn.
class OrderStatusEntry {
  final String trangThai;
  final String? ghiChu;
  final String thoiDiem;
  final String? nguoiThucHien;

  const OrderStatusEntry({required this.trangThai, required this.thoiDiem, this.ghiChu, this.nguoiThucHien});

  factory OrderStatusEntry.fromJson(Map<String, dynamic> json) => OrderStatusEntry(
        trangThai: json['trangThai'] as String,
        ghiChu: json['ghiChu'] as String?,
        thoiDiem: json['thoiDiem'] as String,
        nguoiThucHien: json['nguoiThucHien'] as String?,
      );
}

/// Chi tiết đơn (GET /don-hang/:id, cũng là kết quả POST /don-hang).
class Order {
  final int id;
  final String trangThai;
  final String hinhThucGiao;
  final int phiGiao;
  final int tienHang;
  final int tongTien;
  final String tenNguoiNhan;
  final String sdtNguoiNhan;
  final String diaChiGiao;
  final String? ghiChu;
  final String taoLuc;
  final List<OrderItem> chiTiet;
  final List<OrderStatusEntry> lichSu;

  const Order({
    required this.id,
    required this.trangThai,
    required this.hinhThucGiao,
    required this.phiGiao,
    required this.tienHang,
    required this.tongTien,
    required this.tenNguoiNhan,
    required this.sdtNguoiNhan,
    required this.diaChiGiao,
    required this.taoLuc,
    required this.chiTiet,
    required this.lichSu,
    this.ghiChu,
  });

  /// Khách chỉ được hủy khi đơn còn chờ xác nhận, xác nhận đã nhận khi đơn đã giao.
  /// (Chỉ để ẩn/hiện nút; backend vẫn kiểm tra và trả 409 nếu sai.)
  bool get duocHuy => trangThai == OrderStatus.choXacNhan;
  bool get duocXacNhanNhan => trangThai == OrderStatus.daGiao;
  bool get duocDanhGia => trangThai == OrderStatus.daNhan;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: (json['id'] as num).toInt(),
        trangThai: json['trangThai'] as String,
        hinhThucGiao: json['hinhThucGiao'] as String? ?? '',
        phiGiao: (json['phiGiao'] as num?)?.toInt() ?? 0,
        tienHang: (json['tienHang'] as num?)?.toInt() ?? 0,
        tongTien: (json['tongTien'] as num).toInt(),
        tenNguoiNhan: json['tenNguoiNhan'] as String? ?? '',
        sdtNguoiNhan: json['sdtNguoiNhan'] as String? ?? '',
        diaChiGiao: json['diaChiGiao'] as String? ?? '',
        ghiChu: json['ghiChu'] as String?,
        taoLuc: json['taoLuc'] as String,
        chiTiet: (json['chiTiet'] as List<dynamic>? ?? const [])
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        lichSu: (json['lichSu'] as List<dynamic>? ?? const [])
            .map((e) => OrderStatusEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
