// Máy chủ giả cho test: trả JSON theo "PHƯƠNG_THỨC /đường-dẫn" và ghi lại mọi yêu cầu,
// dựa trên MockClient của package:http/testing.dart (không gọi mạng thật).
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ocop_client/data/api_client.dart';

http.Response traJson(Object? body, [int maHttp = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      maHttp,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

http.Response traLoi(int maHttp, String ma, String thongDiep) =>
    traJson({'loi': {'ma': ma, 'thongDiep': thongDiep}}, maHttp);

/// Một tuyến giả: nhận yêu cầu, trả phản hồi.
typedef TuyenGia = http.Response Function(http.Request req);

class MayChuGia {
  MayChuGia(this.tuyen);

  /// Khóa dạng 'GET /gio-hang'. Không có tuyến thì trả 404.
  final Map<String, TuyenGia> tuyen;
  final List<http.Request> daNhan = [];

  late final ApiClient api = ApiClient(
    baseUrl: 'http://may-chu',
    client: MockClient((req) async {
      daNhan.add(req);
      final f = tuyen['${req.method} ${req.url.path}'];
      return f == null ? traLoi(404, 'KHONG_TIM_THAY', 'Không tìm thấy.') : f(req);
    }),
  );

  /// Các yêu cầu theo "PHƯƠNG_THỨC /đường-dẫn".
  List<String> get dsGoi => [for (final r in daNhan) '${r.method} ${r.url.path}'];

  http.Request cuoi(String khoa) => daNhan.lastWhere((r) => '${r.method} ${r.url.path}' == khoa);

  Map<String, dynamic> body(String khoa) => jsonDecode(cuoi(khoa).body) as Map<String, dynamic>;
}

// ---- JSON mẫu chép từ backend thật (docs/development/API.md) ----

const nguoiDungKhach = {
  'id': 3,
  'email': 'khach1@ocop.example',
  'hoTen': 'Khách mẫu 1',
  'soDienThoai': '0911000001',
  'vaiTro': 'KHACH',
};

const nguoiDungNcc = {
  'id': 7,
  'email': 'ncc1@ocop.example',
  'hoTen': 'Nhà cung cấp 1',
  'soDienThoai': null,
  'vaiTro': 'NHA_CUNG_CAP',
};

Map<String, dynamic> gioMau(List<int> soLuong) {
  final dong = [
    {
      'sanPhamId': 1, 'ten': 'Khô cá dứa 500 g', 'anhUrl': null, 'donViTinh': 'gói', 'gia': 320000,
      'soLuong': soLuong[0], 'thanhTien': 320000 * soLuong[0], 'dangBan': true, 'conHang': 532,
    },
    if (soLuong.length > 1)
      {
        'sanPhamId': 31, 'ten': 'Hạt điều rang muối 500 g', 'anhUrl': null, 'donViTinh': 'hũ', 'gia': 220000,
        'soLuong': soLuong[1], 'thanhTien': 220000 * soLuong[1], 'dangBan': true, 'conHang': 467,
      },
  ].where((d) => (d['soLuong'] as int) > 0).toList();
  return {'duLieu': dong, 'tamTinh': dong.fold<int>(0, (t, d) => t + (d['thanhTien'] as int))};
}

Map<String, dynamic> donMau({int id = 50, String trangThai = 'DA_NHAN'}) => {
      'id': id, 'khachId': 3, 'tenKhach': 'Khách mẫu 1', 'emailKhach': 'khach1@ocop.example',
      'trangThai': trangThai, 'hinhThucGiao': 'NHAN_TAI_CHO', 'phiGiao': 0, 'tienHang': 85000, 'tongTien': 85000,
      'tenNguoiNhan': 'Khách mẫu 1', 'sdtNguoiNhan': '0911000001', 'diaChiGiao': 'Quận 1', 'ghiChu': null,
      'taoLuc': '2026-09-26T15:00:00.000Z', 'capNhatLuc': '2026-09-27T21:00:00.000Z',
      'chiTiet': [
        {
          'sanPhamId': 16, 'tenSanPham': 'Rau muống thủy canh 500 g', 'anhUrl': null, 'donViTinh': 'bó',
          'loId': 64, 'maTruyXuat': '012880F9779E6D99FBAC', 'ngaySanXuat': '2026-05-04', 'vungNguyenLieu': 'Củ Chi',
          'soLuong': 1, 'donGia': 25000, 'thanhTien': 25000, 'daDanhGia': true,
        },
        {
          'sanPhamId': 29, 'tenSanPham': 'Bánh tráng trộn hộp', 'anhUrl': null, 'donViTinh': 'hộp',
          'loId': 77, 'maTruyXuat': '787AFF2921276A200D18', 'ngaySanXuat': '2026-05-17', 'vungNguyenLieu': 'Củ Chi',
          'soLuong': 2, 'donGia': 30000, 'thanhTien': 60000, 'daDanhGia': false,
        },
      ],
      'lichSu': [
        {'trangThai': 'CHO_XAC_NHAN', 'ghiChu': null, 'thoiDiem': '2026-09-26T15:00:00.000Z', 'nguoiThucHien': 'Khách mẫu 1'},
        {'trangThai': trangThai, 'ghiChu': 'Dữ liệu mẫu', 'thoiDiem': '2026-09-27T15:00:00.000Z', 'nguoiThucHien': 'Nhân viên mẫu'},
      ],
    };

const hinhThucGiaoMau = [
  {'ma': 'TIEU_CHUAN', 'ten': 'Giao tiêu chuẩn (3–5 ngày)', 'phiGiao': 30000},
  {'ma': 'NHANH', 'ten': 'Giao nhanh (1–2 ngày)', 'phiGiao': 50000},
  {'ma': 'NHAN_TAI_CHO', 'ten': 'Nhận tại điểm bán', 'phiGiao': 0},
];

const chiTietSanPhamMau = {
  'id': 1, 'ten': 'Khô cá dứa 500 g', 'moTa': 'Cá dứa làm sạch, phơi nắng tự nhiên.', 'donViTinh': 'gói',
  'gia': 320000, 'hangSao': 4, 'anhUrl': null, 'nhaCungCapId': 1, 'tenNhaCungCap': 'HTX Hải sản khô Cần Giờ (mẫu)',
  'vungId': 1, 'tenVung': 'Cần Giờ', 'soDanhGia': 1, 'diemTrungBinh': 5,
  'diaChiNhaCungCap': 'Xã Long Hòa, huyện Cần Giờ', 'anhCoSoUrl': null,
  'chungNhan': [
    {'id': 1, 'loai': 'OCOP', 'soHieu': 'MAU-OCOP-001', 'ngayCap': '2024-03-11', 'ngayHetHan': '2027-03-11', 'anhUrl': null, 'conHieuLuc': true},
  ],
  'danhGiaGanDay': [
    {'id': 17, 'soSao': 5, 'noiDung': 'Rất hài lòng, sẽ mua lại.', 'taoLuc': '2026-09-13T03:00:00.000Z', 'tenNguoiDanhGia': 'Khách mẫu 2', 'anh': <String>[]},
  ],
};

const trangDanhGiaMau = {
  'duLieu': [
    {'id': 17, 'sanPhamId': 1, 'donHangId': 41, 'soSao': 5, 'noiDung': 'Rất hài lòng, sẽ mua lại.', 'taoLuc': '2026-09-13T03:00:00.000Z', 'tenNguoiDanhGia': 'Khách mẫu 2', 'anh': <String>[]},
  ],
  'phanTrang': {'trang': 1, 'kichThuoc': 50, 'tong': 1},
  'tongHop': {'soDanhGia': 1, 'diemTrungBinh': 5},
};

const hoSoMau = {
  'id': 11, 'ten': 'Cơ sở Mật ong Bình Chánh (mẫu)', 'nguoiDaiDien': 'Lý Văn Minh', 'soDienThoai': '0281000011',
  'diaChi': 'Xã Vĩnh Lộc A', 'vungId': 5, 'tenVung': 'Bình Chánh', 'anhCoSoUrl': null,
  'trangThaiDuyet': 'TU_CHOI', 'lyDoTuChoi': 'Ảnh chứng nhận mờ', 'duyetLuc': null, 'taoLuc': '2026-09-20T02:00:00.000Z',
  'nguoiDuyet': null, 'tuGui': true,
  'chungNhan': [
    {'id': 11, 'loai': 'OCOP', 'soHieu': 'MAU-OCOP-011', 'ngayCap': '2024-06-19', 'ngayHetHan': '2027-06-19', 'anhUrl': null, 'conHieuLuc': true},
  ],
};

const sanPhamCuaToiMau = [
  {
    'id': 5, 'ten': 'Mắm ruốc Cần Giờ 300 g', 'moTa': 'Ruốc ủ muối.', 'donViTinh': 'hũ', 'gia': 70000, 'hangSao': 3,
    'anhUrl': null, 'trangThaiDuyet': 'DA_DUYET', 'lyDoTuChoi': null, 'duyetLuc': '2026-02-10T07:00:00.000Z',
    'taoLuc': '2026-02-06T07:00:00.000Z', 'soLo': 2, 'tonKho': 543,
  },
  {
    'id': 55, 'ten': 'Mật ong chanh đào 500 ml', 'moTa': null, 'donViTinh': 'chai', 'gia': 160000, 'hangSao': null,
    'anhUrl': null, 'trangThaiDuyet': 'TU_CHOI', 'lyDoTuChoi': 'Thiếu ảnh nhãn', 'duyetLuc': null,
    'taoLuc': '2026-02-08T09:00:00.000Z', 'soLo': 0, 'tonKho': 0,
  },
];
