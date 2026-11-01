// Unit test model fromJson, validator và tầng data (ApiClient, repository) với máy chủ giả.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ocop_client/data/api_client.dart';
import 'package:ocop_client/data/cua_toi_repository.dart';
import 'package:ocop_client/data/don_hang_repository.dart';
import 'package:ocop_client/data/phien_dang_nhap.dart';
import 'package:ocop_client/data/tai_anh_repository.dart';
import 'package:ocop_client/data/tai_khoan_repository.dart';
import 'package:ocop_client/data/token_store.dart';
import 'package:ocop_client/models/chung_nhan.dart';
import 'package:ocop_client/models/danh_gia.dart';
import 'package:ocop_client/models/don_hang.dart';
import 'package:ocop_client/models/gio_hang.dart';
import 'package:ocop_client/models/nguoi_dung.dart';
import 'package:ocop_client/models/nha_cung_cap.dart';
import 'package:ocop_client/models/phan_anh.dart';
import 'package:ocop_client/models/san_pham.dart';
import 'package:ocop_client/utils/kiem_tra.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'may_chu_gia.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PhienDangNhap.dat(null);
  });

  group('Model fromJson', () {
    test('đăng nhập: token và người dùng', () {
      final kq = KetQuaDangNhap.fromJson({'token': 'abc', 'nguoiDung': nguoiDungKhach});
      expect(kq.token, 'abc');
      expect(kq.nguoiDung.laKhach, isTrue);
      expect(kq.nguoiDung.tenVaiTro, 'Khách hàng');
      expect(NguoiDung.fromJson(nguoiDungNcc).laNhaCungCap, isTrue);
      expect(NguoiDung.fromJson(kq.nguoiDung.toJson()).email, 'khach1@ocop.example');
    });

    test('giỏ hàng: dòng, tạm tính, số lượng theo sản phẩm', () {
      final gio = GioHang.fromJson(gioMau([2, 1]));
      expect(gio.duLieu.length, 2);
      expect(gio.tamTinh, 860000);
      expect(gio.soLuongCua(1), 2);
      expect(gio.soLuongCua(99), 0);
      expect(gio.duLieu.first.conHang, 532);
    });

    test('chi tiết đơn: dòng có mã lô, cờ đã đánh giá, lịch sử; quyền thao tác theo trạng thái', () {
      final don = DonHang.fromJson(donMau());
      expect(don.chiTiet.map((d) => d.maTruyXuat), ['012880F9779E6D99FBAC', '787AFF2921276A200D18']);
      expect(don.chiTiet.map((d) => d.daDanhGia), [true, false]);
      expect(don.lichSu.length, 2);
      expect(don.duocDanhGia, isTrue);
      expect(don.duocHuy, isFalse);
      expect(DonHang.fromJson(donMau(trangThai: 'CHO_XAC_NHAN')).duocHuy, isTrue);
      expect(DonHang.fromJson(donMau(trangThai: 'DA_GIAO')).duocXacNhanNhan, isTrue);
      expect(TrangThaiDon.ten('DANG_GIAO'), 'Đang giao');
    });

    test('đơn trong danh sách', () {
      final d = DonHangTomTat.fromJson({
        'id': 45, 'trangThai': 'DA_GIAO', 'hinhThucGiao': 'TIEU_CHUAN', 'tongTien': 90000,
        'taoLuc': '2026-09-17T21:00:00.000Z', 'capNhatLuc': '2026-09-19T03:00:00.000Z', 'khachId': 3,
        'tenKhach': 'Khách mẫu 1', 'tenNguoiNhan': 'Khách mẫu 1', 'soSanPham': 1,
        'tenSanPhamDau': 'Bánh tráng trộn hộp', 'anhSanPhamDau': null,
      });
      expect(d.tongTien, 90000);
      expect(d.tenSanPhamDau, 'Bánh tráng trộn hộp');
      expect(HinhThucGiao.fromJson(hinhThucGiaoMau[1]).phiGiao, 50000);
    });

    test('chi tiết sản phẩm: nhà cung cấp, chứng nhận, đánh giá', () {
      final ct = ChiTietSanPham.fromJson(chiTietSanPhamMau);
      expect(ct.sanPham.nhaCungCapId, 1);
      expect(ct.sanPham.gia, 320000);
      expect(ct.chungNhan.single.ngayCap, '2024-03-11');
      expect(ct.danhGiaGanDay.single.soSao, 5);
      final dg = TrangDanhGia.fromJson(trangDanhGiaMau);
      expect(dg.soDanhGia, 1);
      expect(dg.diemTrungBinh, 5.0);
    });

    test('trang nhà cung cấp, theo dõi, yêu thích', () {
      final ncc = NhaCungCap.fromJson({
        'id': 1, 'ten': 'HTX', 'nguoiDaiDien': 'An', 'soDienThoai': '0281000001', 'diaChi': 'Cần Giờ',
        'vungId': 1, 'tenVung': 'Cần Giờ', 'anhCoSoUrl': null, 'trangThaiDuyet': 'DA_DUYET', 'soNguoiTheoDoi': 2,
        'chungNhan': chiTietSanPhamMau['chungNhan'],
        'sanPham': [{'id': 1, 'ten': 'Khô cá dứa 500 g', 'gia': 320000, 'donViTinh': 'gói', 'hangSao': 4, 'anhUrl': null}],
      });
      expect(ncc.soNguoiTheoDoi, 2);
      expect(ncc.sanPham.single.hangSao, 4);
      final td = NhaCungCapTheoDoi.fromJson({
        'id': 3, 'ten': 'Yến sào', 'diaChi': 'Cần Thạnh', 'anhCoSoUrl': null, 'tenVung': 'Cần Giờ',
        'taoLuc': '2026-11-01T08:07:58.328Z', 'soSanPham': 5,
      });
      expect(td.soSanPham, 5);
      final yt = SanPhamTomTat.fromJson({
        'id': 11, 'ten': 'Yến thô 50 g', 'gia': 1500000, 'donViTinh': 'hộp', 'hangSao': 5, 'anhUrl': null,
        'nhaCungCapId': 3, 'tenNhaCungCap': 'Yến sào', 'taoLuc': '2026-11-01T08:07:58.328Z',
      });
      expect(yt.tenNhaCungCap, 'Yến sào');
    });

    test('hồ sơ và sản phẩm của nhà cung cấp: trạng thái duyệt, lý do, quyền sửa', () {
      final hs = HoSoNhaCungCap.fromJson(hoSoMau);
      expect(hs.trangThaiDuyet, TrangThaiDuyet.tuChoi);
      expect(hs.lyDoTuChoi, 'Ảnh chứng nhận mờ');
      expect(hs.duocSua, isTrue);
      final ds = sanPhamCuaToiMau.map(SanPhamCuaToi.fromJson).toList();
      expect(ds.first.duocSua, isFalse); // đã duyệt
      expect(ds.first.tonKho, 543);
      expect(ds.last.hangSao, isNull);
      expect(ds.last.lyDoTuChoi, 'Thiếu ảnh nhãn');
    });

    test('phản ánh', () {
      final p = PhanAnh.fromJson({
        'id': 1, 'sanPhamId': 1, 'tenSanPham': 'Khô cá dứa', 'anhSanPham': null, 'nhaCungCapId': 1,
        'tenNhaCungCap': 'HTX', 'loId': 3, 'maTruyXuat': 'B056FB25CA6642785532', 'loai': 'HANG_GIA',
        'noiDung': 'Bao bì khác ảnh', 'anhUrl': null, 'trangThai': 'DA_XU_LY', 'ketQuaXuLy': 'Đã thu hồi lô',
        'xuLyLuc': '2026-10-01T00:00:00.000Z', 'taoLuc': '2026-09-30T00:00:00.000Z', 'nguoiBaoId': 3,
        'tenNguoiBao': 'Khách', 'tenNguoiXuLy': 'QT',
      });
      expect(p.ketQuaXuLy, 'Đã thu hồi lô');
      expect(LoaiPhanAnh.ten(p.loai), 'Nghi hàng giả');
      expect(TrangThaiPhanAnh.ten(p.trangThai), 'Đã xử lý');
    });

    test('chứng nhận gửi lên không kèm conHieuLuc, bỏ ngày hết hạn trống', () {
      const cn = ChungNhan(loai: 'OCOP', soHieu: 'X-1', ngayCap: '2025-01-01', ngayHetHan: '', conHieuLuc: true);
      expect(cn.toJson(), {'loai': 'OCOP', 'soHieu': 'X-1', 'ngayCap': '2025-01-01'});
    });
  });

  group('KiemTra (validator)', () {
    test('email, mật khẩu, số điện thoại', () {
      expect(KiemTra.email(''), isNotNull);
      expect(KiemTra.email('a@b'), isNotNull);
      expect(KiemTra.email('khach1@ocop.example'), isNull);
      expect(KiemTra.matKhau('1234567'), isNotNull);
      expect(KiemTra.matKhau('Demo@12345'), isNull);
      expect(KiemTra.soDienThoai('09 11.000-001'), isNull);
      expect(KiemTra.soDienThoai('12ab'), isNotNull);
      expect(KiemTra.soDienThoai('', batBuoc: false), isNull);
    });

    test('giá nguyên VND, URL ảnh, ngày', () {
      expect(KiemTra.gia('320000'), isNull);
      expect(KiemTra.gia('320.000'), isNotNull);
      expect(KiemTra.gia('0'), isNotNull);
      expect(KiemTra.urlTuyChon(''), isNull);
      expect(KiemTra.urlTuyChon('ftp://x'), isNotNull);
      expect(KiemTra.urlTuyChon('https://a.vn/x.jpg'), isNull);
      expect(KiemTra.laNgay('2026-02-30'), isFalse);
      expect(KiemTra.laNgay('2026-02-28'), isTrue);
    });
  });

  group('ApiClient và repository', () {
    test('POST gửi JSON có Content-Type; đăng nhập lưu token và cập nhật phiên', () async {
      final may = MayChuGia({'POST /auth/dang-nhap': (_) => traJson({'token': 'tk1', 'nguoiDung': nguoiDungKhach})});
      final nd = await TaiKhoanRepository(may.api).dangNhap(email: ' khach1@ocop.example ', matKhau: 'Demo@12345');
      expect(nd.id, 3);
      expect(may.cuoi('POST /auth/dang-nhap').headers['Content-Type'], startsWith('application/json'));
      expect(may.body('POST /auth/dang-nhap'), {'email': 'khach1@ocop.example', 'matKhau': 'Demo@12345'});
      expect(await TokenStore.layToken(), 'tk1');
      expect((await TokenStore.layNguoiDung())!.vaiTro, 'KHACH');
      expect(PhienDangNhap.laKhach, isTrue);
    });

    test('sai mật khẩu (401 khi chưa có token) chỉ báo lỗi, không coi là hết phiên', () async {
      var hetPhien = false;
      final sub = PhienDangNhap.hetPhien.listen((_) => hetPhien = true);
      final may = MayChuGia({'POST /auth/dang-nhap': (_) => traLoi(401, 'SAI_DANG_NHAP', 'Sai email hoặc mật khẩu.')});
      await expectLater(
        TaiKhoanRepository(may.api).dangNhap(email: 'a@b.vn', matKhau: '12345678'),
        throwsA(isA<ApiException>().having((e) => e.thongDiep, 'thongDiep', 'Sai email hoặc mật khẩu.')),
      );
      await Future<void>.delayed(Duration.zero);
      expect(hetPhien, isFalse);
      await sub.cancel();
    });

    test('401 khi có token: xóa token, báo hết phiên để app về đăng nhập', () async {
      SharedPreferences.setMockInitialValues({'token': 'cu', 'nguoiDung': '{"id":3,"email":"k@x.vn","hoTen":"K","vaiTro":"KHACH"}'});
      await TaiKhoanRepository(MayChuGia({}).api).khoiPhucPhien();
      expect(PhienDangNhap.daDangNhap, isTrue);
      final hetPhien = Completer<void>();
      final sub = PhienDangNhap.hetPhien.listen((_) => hetPhien.complete());
      final may = MayChuGia({'GET /gio-hang': (_) => traLoi(401, 'TOKEN_HET_HAN', 'Token hết hạn.')});
      await expectLater(
        DonHangRepository(may.api).gioHang(),
        throwsA(isA<ApiException>().having((e) => e.maHttp, 'maHttp', 401)),
      );
      await hetPhien.future.timeout(const Duration(seconds: 1));
      expect(await TokenStore.layToken(), isNull);
      expect(PhienDangNhap.daDangNhap, isFalse);
      await sub.cancel();
    });

    test('lỗi 400 kèm chi tiết từng trường', () async {
      final may = MayChuGia({
        'POST /don-hang': (_) => traJson({
              'loi': {
                'ma': 'DU_LIEU_KHONG_HOP_LE',
                'thongDiep': 'Dữ liệu không hợp lệ.',
                'chiTiet': [{'truong': 'sdtNguoiNhan', 'thongDiep': 'Số điện thoại không hợp lệ.'}],
              }
            }, 400),
      });
      await expectLater(
        DonHangRepository(may.api).datHang(hinhThucGiao: 'NHANH', tenNguoiNhan: 'A', sdtNguoiNhan: 'x', diaChiGiao: 'B'),
        throwsA(isA<ApiException>()
            .having((e) => e.ma, 'ma', 'DU_LIEU_KHONG_HOP_LE')
            .having((e) => e.thongDiepDayDu, 'thongDiepDayDu', contains('Số điện thoại không hợp lệ.'))),
      );
    });

    test('đặt hàng không gửi cacDong (đặt cả giỏ) và không gửi giá', () async {
      final may = MayChuGia({'POST /don-hang': (_) => traJson(donMau(id: 99, trangThai: 'CHO_XAC_NHAN'), 201)});
      final don = await DonHangRepository(may.api).datHang(
          hinhThucGiao: 'NHANH', tenNguoiNhan: ' An ', sdtNguoiNhan: '0911000001', diaChiGiao: 'Q1', ghiChu: '');
      expect(don.id, 99);
      expect(may.body('POST /don-hang'),
          {'hinhThucGiao': 'NHANH', 'tenNguoiNhan': 'An', 'sdtNguoiNhan': '0911000001', 'diaChiGiao': 'Q1'});
    });

    test('thêm vào giỏ cộng dồn số lượng đang có rồi PUT', () async {
      final may = MayChuGia({
        'GET /gio-hang': (_) => traJson(gioMau([2])),
        'PUT /gio-hang/1': (_) => traJson(gioMau([5])),
      });
      final gio = await DonHangRepository(may.api).themVaoGio(1, 3);
      expect(may.body('PUT /gio-hang/1'), {'soLuong': 5});
      expect(gio.soLuongCua(1), 5);
    });

    test('hồ sơ nhà cung cấp: 404 CHUA_CO_HO_SO thành null', () async {
      final may = MayChuGia({'GET /cua-toi/nha-cung-cap': (_) => traLoi(404, 'CHUA_CO_HO_SO', 'Chưa có hồ sơ.')});
      expect(await CuaToiRepository(may.api).hoSo(), isNull);
    });

    test('tải ảnh gửi byte thô đúng Content-Type; 503 nhận ra là chưa cấu hình kho ảnh', () async {
      final may = MayChuGia({'POST /tai-len/anh': (_) => traJson({'url': 'https://kho/anh.png'}, 201)});
      final url = await TaiAnhRepository(may.api).taiAnh([0x89, 0x50, 0x4e, 0x47], tenTep: 'a.PNG', mucDich: 'danh-gia');
      expect(url, 'https://kho/anh.png');
      final req = may.cuoi('POST /tai-len/anh');
      expect(req.headers['Content-Type'], 'image/png');
      expect(req.url.queryParameters, {'mucDich': 'danh-gia'});
      expect(req.bodyBytes, [0x89, 0x50, 0x4e, 0x47]);

      final may503 = MayChuGia({
        'POST /tai-len/anh': (_) => traLoi(503, 'CHUA_CAU_HINH_LUU_ANH', 'Máy chủ chưa cấu hình lưu ảnh.'),
      });
      try {
        await TaiAnhRepository(may503.api).taiAnh([1, 2], tenTep: 'a.jpg', mucDich: 'danh-gia');
        fail('phải ném ApiException');
      } on ApiException catch (e) {
        expect(TaiAnhRepository.laChuaCauHinh(e), isTrue);
      }
      expect(TaiAnhRepository.loaiAnh('x.webp'), 'image/webp');
      expect(TaiAnhRepository.loaiAnh('x.jpeg'), 'image/jpeg');
    });
  });
}
