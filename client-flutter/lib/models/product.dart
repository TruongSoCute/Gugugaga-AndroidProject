import 'certificate.dart';
import 'review.dart';

/// Sản phẩm đã công bố (GET /san-pham). Tên trường khớp JSON camelCase của backend.
class Product {
  final int id;
  final String ten;
  final String? moTa;
  final String donViTinh;
  final int gia;
  final int? hangSao;
  final String? anhUrl;
  final int? nhaCungCapId;
  final String tenNhaCungCap;
  final String tenVung;
  final int soDanhGia;
  final double? diemTrungBinh;

  const Product({
    required this.id,
    required this.ten,
    required this.donViTinh,
    required this.gia,
    required this.tenNhaCungCap,
    required this.tenVung,
    this.nhaCungCapId,
    this.moTa,
    this.hangSao,
    this.anhUrl,
    this.soDanhGia = 0,
    this.diemTrungBinh,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as int,
        ten: json['ten'] as String,
        moTa: json['moTa'] as String?,
        donViTinh: json['donViTinh'] as String? ?? '',
        gia: (json['gia'] as num).toInt(),
        hangSao: json['hangSao'] as int?,
        anhUrl: json['anhUrl'] as String?,
        nhaCungCapId: (json['nhaCungCapId'] as num?)?.toInt(),
        tenNhaCungCap: json['tenNhaCungCap'] as String? ?? '',
        tenVung: json['tenVung'] as String? ?? '',
        soDanhGia: (json['soDanhGia'] as num?)?.toInt() ?? 0,
        diemTrungBinh: (json['diemTrungBinh'] as num?)?.toDouble(),
      );
}

/// Một trang kết quả: { duLieu: [...], phanTrang: { trang, kichThuoc, tong } }.
class ProductPage {
  final List<Product> duLieu;
  final int tong;

  const ProductPage({required this.duLieu, required this.tong});

  factory ProductPage.fromJson(Map<String, dynamic> json) => ProductPage(
        duLieu: (json['duLieu'] as List<dynamic>)
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList(),
        tong: ((json['phanTrang'] as Map<String, dynamic>)['tong'] as num).toInt(),
      );
}

/// Chi tiết sản phẩm (GET /san-pham/:id): thông tin sản phẩm, nhà cung cấp, chứng nhận
/// và vài đánh giá gần đây.
class ProductDetails {
  final Product sanPham;
  final String? diaChiNhaCungCap;
  final String? anhCoSoUrl;
  final List<Certificate> chungNhan;
  final List<Review> danhGiaGanDay;

  const ProductDetails({
    required this.sanPham,
    required this.chungNhan,
    required this.danhGiaGanDay,
    this.diaChiNhaCungCap,
    this.anhCoSoUrl,
  });

  factory ProductDetails.fromJson(Map<String, dynamic> json) => ProductDetails(
        sanPham: Product.fromJson(json),
        diaChiNhaCungCap: json['diaChiNhaCungCap'] as String?,
        anhCoSoUrl: json['anhCoSoUrl'] as String?,
        chungNhan: docDsChungNhan(json['chungNhan']),
        danhGiaGanDay: (json['danhGiaGanDay'] as List<dynamic>? ?? const [])
            .map((e) => Review.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Sản phẩm rút gọn trong trang nhà cung cấp, danh sách yêu thích.
class ProductSummary {
  final int id;
  final String ten;
  final int gia;
  final String donViTinh;
  final int? hangSao;
  final String? anhUrl;
  final String? tenNhaCungCap;

  const ProductSummary({
    required this.id,
    required this.ten,
    required this.gia,
    required this.donViTinh,
    this.hangSao,
    this.anhUrl,
    this.tenNhaCungCap,
  });

  factory ProductSummary.fromJson(Map<String, dynamic> json) => ProductSummary(
        id: (json['id'] as num).toInt(),
        ten: json['ten'] as String,
        gia: (json['gia'] as num).toInt(),
        donViTinh: json['donViTinh'] as String? ?? '',
        hangSao: (json['hangSao'] as num?)?.toInt(),
        anhUrl: json['anhUrl'] as String?,
        tenNhaCungCap: json['tenNhaCungCap'] as String?,
      );
}

/// Trạng thái duyệt dùng chung cho hồ sơ nhà cung cấp và sản phẩm.
class ApprovalStatus {
  ApprovalStatus._();

  static const choDuyet = 'CHO_DUYET';
  static const daDuyet = 'DA_DUYET';
  static const tuChoi = 'TU_CHOI';

  static String ten(String ma) => switch (ma) {
        choDuyet => 'Chờ duyệt',
        daDuyet => 'Đã duyệt',
        tuChoi => 'Bị từ chối',
        _ => ma,
      };
}

/// Sản phẩm của nhà cung cấp đang đăng nhập (GET /cua-toi/san-pham), mọi trạng thái.
class MyProduct {
  final int id;
  final String ten;
  final String? moTa;
  final String donViTinh;
  final int gia;
  final int? hangSao;
  final String? anhUrl;
  final String trangThaiDuyet;
  final String? lyDoTuChoi;
  final int soLo;
  final int tonKho;

  const MyProduct({
    required this.id,
    required this.ten,
    required this.donViTinh,
    required this.gia,
    required this.trangThaiDuyet,
    this.moTa,
    this.hangSao,
    this.anhUrl,
    this.lyDoTuChoi,
    this.soLo = 0,
    this.tonKho = 0,
  });

  /// Backend chỉ cho sửa sản phẩm chờ duyệt hoặc bị từ chối (409 SAN_PHAM_DA_DUYET).
  bool get duocSua => trangThaiDuyet != ApprovalStatus.daDuyet;

  factory MyProduct.fromJson(Map<String, dynamic> json) => MyProduct(
        id: (json['id'] as num).toInt(),
        ten: json['ten'] as String,
        moTa: json['moTa'] as String?,
        donViTinh: json['donViTinh'] as String? ?? '',
        gia: (json['gia'] as num).toInt(),
        hangSao: (json['hangSao'] as num?)?.toInt(),
        anhUrl: json['anhUrl'] as String?,
        trangThaiDuyet: json['trangThaiDuyet'] as String,
        lyDoTuChoi: json['lyDoTuChoi'] as String?,
        soLo: (json['soLo'] as num?)?.toInt() ?? 0,
        tonKho: (json['tonKho'] as num?)?.toInt() ?? 0,
      );
}
