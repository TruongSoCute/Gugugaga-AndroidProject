// Kiểm thử hợp đồng API với backend THẬT: repository và model của app có đọc đúng JSON không.
// Chỉ chạy khi có biến môi trường OCOP_API_TEST_URL (vd http://localhost:3000) trỏ tới
// backend vừa chạy db:reset; nếu không thì bỏ qua.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ocop_client/data/api_client.dart';
import 'package:ocop_client/data/cua_toi_repository.dart';
import 'package:ocop_client/data/don_hang_repository.dart';
import 'package:ocop_client/data/phan_anh_repository.dart';
import 'package:ocop_client/data/phien_dang_nhap.dart';
import 'package:ocop_client/data/san_pham_repository.dart';
import 'package:ocop_client/data/tai_anh_repository.dart';
import 'package:ocop_client/data/tai_khoan_repository.dart';
import 'package:ocop_client/data/token_store.dart';
import 'package:ocop_client/data/truy_xuat_repository.dart';
import 'package:ocop_client/data/tuong_tac_repository.dart';
import 'package:ocop_client/models/san_pham.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final url = Platform.environment['OCOP_API_TEST_URL'];
  final boQua = url == null || url.isEmpty ? 'chưa đặt OCOP_API_TEST_URL' : null;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PhienDangNhap.dat(null);
  });

  ApiClient api() => ApiClient(baseUrl: url!.replaceAll(RegExp(r'/+$'), ''));

  test('vùng và sản phẩm đã công bố, lọc vùng + hạng sao', () async {
    final repo = SanPhamRepository(api());
    final vung = await repo.dsVung();
    expect(vung.length, greaterThanOrEqualTo(4));
    final tatCa = await repo.dsSanPham();
    expect(tatCa.tong, greaterThan(0));
    final loc = await repo.dsSanPham(vungId: 1, hangSao: 5);
    expect(loc.duLieu, isNotEmpty);
    expect(loc.duLieu.every((sp) => sp.hangSao == 5 && sp.tenVung == 'Cần Giờ'), isTrue);
  }, skip: boQua);

  test('truy xuất mã lô thật trả đủ 4 bước; mã không tồn tại trả 404', () async {
    final ma = Platform.environment['OCOP_MA_LO_TEST'];
    final repo = TruyXuatRepository(api());
    if (ma != null) {
      final lo = await repo.layHanhTrinh(ma);
      expect(lo.maTruyXuat, ma);
      expect(lo.cacBuoc.length, 4);
      expect(lo.chungNhan, isNotEmpty);
    }
    await expectLater(
      repo.layHanhTrinh('0123456789ABCDEF0123'),
      throwsA(isA<ApiException>().having((e) => e.maHttp, 'maHttp', 404)),
    );
  }, skip: boQua);

  // Các test dưới chỉ ĐỌC dữ liệu mẫu (đăng nhập rồi GET), không làm đổi CSDL.
  const matKhauMau = 'Demo@12345';

  test('chi tiết sản phẩm, đánh giá, trang nhà cung cấp, hình thức giao (công khai)', () async {
    final repo = SanPhamRepository(api());
    final ct = await repo.chiTiet(1);
    expect(ct.sanPham.nhaCungCapId, isNotNull);
    expect(ct.chungNhan, isNotEmpty);
    final dg = await repo.dsDanhGia(1);
    expect(dg.soDanhGia, dg.duLieu.length);
    final ncc = await repo.nhaCungCap(ct.sanPham.nhaCungCapId!);
    expect(ncc.sanPham.any((sp) => sp.id == 1), isTrue);
    final ht = await DonHangRepository(api()).dsHinhThucGiao();
    expect(ht.map((h) => h.ma), containsAll(['TIEU_CHUAN', 'NHANH', 'NHAN_TAI_CHO']));
  }, skip: boQua);

  test('khach1: đăng nhập lưu token; đọc giỏ, đơn, chi tiết đơn, yêu thích, theo dõi, phản ánh', () async {
    final a = api();
    final nd = await TaiKhoanRepository(a).dangNhap(email: 'khach1@ocop.example', matKhau: matKhauMau);
    expect(nd.laKhach, isTrue);
    expect(await TokenStore.layToken(), isNotNull);

    final donRepo = DonHangRepository(a);
    final gio = await donRepo.gioHang();
    expect(gio.tamTinh, greaterThanOrEqualTo(0));
    final dsDon = await donRepo.dsDonHang();
    expect(dsDon, isNotEmpty);
    final daNhan = await donRepo.dsDonHang(trangThai: 'DA_NHAN');
    expect(daNhan, isNotEmpty);
    expect(daNhan.every((d) => d.trangThai == 'DA_NHAN'), isTrue);
    final ct = await donRepo.chiTietDon(daNhan.first.id);
    expect(ct.chiTiet, isNotEmpty);
    expect(ct.chiTiet.every((d) => d.maTruyXuat != null && d.maTruyXuat!.length == 20), isTrue);
    expect(ct.lichSu.last.trangThai, 'DA_NHAN');
    expect((await donRepo.dsDonHang(trangThai: 'DA_GIAO')), isNotEmpty);

    // Mã lô trong đơn mở được hành trình công khai đúng sản phẩm.
    final dong = ct.chiTiet.first;
    final lo = await TruyXuatRepository(a).layHanhTrinh(dong.maTruyXuat!);
    expect(lo.sanPhamId, dong.sanPhamId);

    final tt = TuongTacRepository(a);
    await tt.dsYeuThich();
    await tt.dsTheoDoi();
    await PhanAnhRepository(a).dsCuaToi();
  }, skip: boQua);

  test('khach1 gọi API nhà cung cấp bị 403; tải ảnh trả URL hoặc 503 khi chưa cấu hình kho ảnh', () async {
    final a = api();
    await TaiKhoanRepository(a).dangNhap(email: 'khach1@ocop.example', matKhau: matKhauMau);
    await expectLater(CuaToiRepository(a).dsSanPham(),
        throwsA(isA<ApiException>().having((e) => e.maHttp, 'maHttp', 403)));
    // PNG 1x1 hợp lệ.
    const png = [
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
      0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
      0x42, 0x60, 0x82,
    ];
    try {
      final url = await TaiAnhRepository(a).taiAnh(png, tenTep: 'thu.png', mucDich: 'danh-gia');
      expect(url, startsWith('http'));
    } on ApiException catch (e) {
      expect(TaiAnhRepository.laChuaCauHinh(e), isTrue, reason: 'lỗi khác 503: ${e.thongDiepDayDu}');
    }
  }, skip: boQua);

  test('token sai: 401, ApiClient xóa token và báo hết phiên', () async {
    SharedPreferences.setMockInitialValues({'token': 'token-gia'});
    var hetPhien = false;
    PhienDangNhap.dat(null);
    await TaiKhoanRepository(api()).khoiPhucPhien();
    final sub = PhienDangNhap.hetPhien.listen((_) => hetPhien = true);
    await expectLater(DonHangRepository(api()).gioHang(),
        throwsA(isA<ApiException>().having((e) => e.maHttp, 'maHttp', 401)));
    expect(await TokenStore.layToken(), isNull);
    await sub.cancel();
    expect(hetPhien, isFalse); // không có thông tin người dùng đã lưu thì không phát hết phiên
  }, skip: boQua);

  test('ncc1 (đã duyệt): hồ sơ DA_DUYET không sửa được; sản phẩm của tôi có số lô/tồn kho', () async {
    final a = api();
    final nd = await TaiKhoanRepository(a).dangNhap(email: 'ncc1@ocop.example', matKhau: matKhauMau);
    expect(nd.laNhaCungCap, isTrue);
    final repo = CuaToiRepository(a);
    final hs = await repo.hoSo();
    expect(hs, isNotNull);
    expect(hs!.trangThaiDuyet, TrangThaiDuyet.daDuyet);
    expect(hs.duocSua, isFalse);
    expect(hs.chungNhan, isNotEmpty);
    final ds = await repo.dsSanPham();
    expect(ds.length, greaterThanOrEqualTo(5));
    expect(ds.any((sp) => sp.soLo > 0 && sp.tonKho > 0), isTrue);
    // Nhà cung cấp không dùng giỏ hàng của khách.
    await expectLater(DonHangRepository(a).gioHang(),
        throwsA(isA<ApiException>().having((e) => e.maHttp, 'maHttp', 403)));
  }, skip: boQua);

  test('ncc11 (chờ duyệt): hồ sơ CHO_DUYET sửa được; sản phẩm chưa có hạng sao', () async {
    final a = api();
    await TaiKhoanRepository(a).dangNhap(email: 'ncc11@ocop.example', matKhau: matKhauMau);
    final hs = await CuaToiRepository(a).hoSo();
    expect(hs!.trangThaiDuyet, TrangThaiDuyet.choDuyet);
    expect(hs.duocSua, isTrue);
    final ds = await CuaToiRepository(a).dsSanPham();
    expect(ds.where((sp) => sp.trangThaiDuyet == TrangThaiDuyet.choDuyet).every((sp) => sp.hangSao == null), isTrue);
  }, skip: boQua);
}
