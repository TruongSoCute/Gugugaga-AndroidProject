// Widget test các màn hình chính với máy chủ giả (MockClient): form chặn dữ liệu sai,
// Navigator trả kết quả, xác nhận xóa + SnackBar Hoàn tác, bộ tab theo vai trò, hết phiên.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocop_client/data/api_client.dart';
import 'package:ocop_client/data/cua_toi_repository.dart';
import 'package:ocop_client/data/danh_gia_repository.dart';
import 'package:ocop_client/data/don_hang_repository.dart';
import 'package:ocop_client/data/phan_anh_repository.dart';
import 'package:ocop_client/data/phien_dang_nhap.dart';
import 'package:ocop_client/data/san_pham_repository.dart';
import 'package:ocop_client/data/tai_khoan_repository.dart';
import 'package:ocop_client/data/token_store.dart';
import 'package:ocop_client/data/tuong_tac_repository.dart';
import 'package:ocop_client/models/don_hang.dart';
import 'package:ocop_client/models/nguoi_dung.dart';
import 'package:ocop_client/screens/chi_tiet_don_screen.dart';
import 'package:ocop_client/screens/chi_tiet_san_pham_screen.dart';
import 'package:ocop_client/screens/danh_gia_screen.dart';
import 'package:ocop_client/screens/dang_nhap_screen.dart';
import 'package:ocop_client/screens/dat_hang_screen.dart';
import 'package:ocop_client/screens/don_hang_screen.dart';
import 'package:ocop_client/screens/gio_hang_screen.dart';
import 'package:ocop_client/screens/ho_so_ncc_screen.dart';
import 'package:ocop_client/screens/khung_chinh.dart';
import 'package:ocop_client/screens/phan_anh_screen.dart';
import 'package:ocop_client/screens/san_pham_cua_toi_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'may_chu_gia.dart';

/// Trang chủ giả có một nút mở màn hình cần thử và ghi lại kết quả Navigator trả về.
class _TrangMo<T> extends StatefulWidget {
  const _TrangMo(this.manHinh);

  final Widget manHinh;

  @override
  State<_TrangMo<T>> createState() => _TrangMoState<T>();
}

class _TrangMoState<T> extends State<_TrangMo<T>> {
  Object? ketQua = 'chưa';

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(children: [
          TextButton(
            onPressed: () async {
              final kq = await Navigator.push<T>(context, MaterialPageRoute(builder: (_) => widget.manHinh));
              setState(() => ketQua = kq);
            },
            child: const Text('Mở'),
          ),
          Text('Kết quả: $ketQua'),
        ]),
      );
}

Future<_TrangMoState<T>> _moQuaTrangChu<T>(WidgetTester tester, Widget manHinh) async {
  await tester.pumpWidget(MaterialApp(home: _TrangMo<T>(manHinh)));
  await tester.tap(find.text('Mở'));
  await tester.pumpAndSettle();
  return tester.state<_TrangMoState<T>>(find.byType(_TrangMo<T>, skipOffstage: false));
}

Future<void> _dangNhapKhach() async {
  SharedPreferences.setMockInitialValues({'token': 'tk', 'nguoiDung': jsonEncode(nguoiDungKhach)});
  PhienDangNhap.dat(NguoiDung.fromJson(nguoiDungKhach));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PhienDangNhap.dat(null);
  });

  group('Đăng nhập', () {
    testWidgets('form chặn gửi khi email sai hoặc thiếu mật khẩu', (tester) async {
      final may = MayChuGia({});
      await tester.pumpWidget(MaterialApp(home: DangNhapScreen(repository: TaiKhoanRepository(may.api))));
      await tester.tap(find.byKey(const Key('nutDangNhap')));
      await tester.pump();
      expect(find.text('Vui lòng nhập email'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('oEmail')), 'khong-phai-email');
      await tester.tap(find.byKey(const Key('nutDangNhap')));
      await tester.pump();
      expect(find.text('Email không hợp lệ'), findsOneWidget);
      expect(may.daNhan, isEmpty); // không gửi gì lên máy chủ
    });

    testWidgets('thành công thì lưu token và Navigator trả người dùng về màn hình gọi', (tester) async {
      final may = MayChuGia({'POST /auth/dang-nhap': (_) => traJson({'token': 'tk-moi', 'nguoiDung': nguoiDungKhach})});
      final trang = await _moQuaTrangChu<NguoiDung>(tester, DangNhapScreen(repository: TaiKhoanRepository(may.api)));
      await tester.enterText(find.byKey(const Key('oEmail')), 'khach1@ocop.example');
      await tester.enterText(find.byKey(const Key('oMatKhau')), 'Demo@12345');
      await tester.tap(find.byKey(const Key('nutDangNhap')));
      await tester.pumpAndSettle();
      expect(trang.ketQua, isA<NguoiDung>().having((n) => n.email, 'email', 'khach1@ocop.example'));
      expect(await TokenStore.layToken(), 'tk-moi');
      expect(PhienDangNhap.laKhach, isTrue);
    });

    testWidgets('sai mật khẩu hiện SnackBar và ở lại màn hình', (tester) async {
      final may = MayChuGia({'POST /auth/dang-nhap': (_) => traLoi(401, 'SAI_DANG_NHAP', 'Email hoặc mật khẩu không đúng.')});
      await tester.pumpWidget(MaterialApp(home: DangNhapScreen(repository: TaiKhoanRepository(may.api))));
      await tester.enterText(find.byKey(const Key('oEmail')), 'khach1@ocop.example');
      await tester.enterText(find.byKey(const Key('oMatKhau')), 'sai-mat-khau');
      await tester.tap(find.byKey(const Key('nutDangNhap')));
      await tester.pumpAndSettle();
      expect(find.text('Email hoặc mật khẩu không đúng.'), findsOneWidget);
      expect(find.byType(DangNhapScreen), findsOneWidget);
    });
  });

  group('Giỏ hàng và đặt hàng', () {
    testWidgets('xóa có hộp thoại xác nhận, SnackBar Hoàn tác PUT lại số lượng cũ', (tester) async {
      await _dangNhapKhach();
      final may = MayChuGia({
        'GET /gio-hang': (_) => traJson(gioMau([2, 1])),
        'DELETE /gio-hang/1': (_) => traJson(gioMau([0, 1])),
        'PUT /gio-hang/1': (_) => traJson(gioMau([2, 1])),
      });
      await tester.pumpWidget(MaterialApp(home: GioHangScreen(repository: DonHangRepository(may.api))));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Khô cá dứa 500 g'), findsOneWidget);
      expect(find.text('860.000 đ'), findsOneWidget); // tạm tính do backend tính

      await tester.tap(find.byKey(const Key('xoa1')));
      await tester.pumpAndSettle();
      expect(find.text('Xóa khỏi giỏ'), findsOneWidget); // hộp thoại xác nhận
      await tester.tap(find.text('Không'));
      await tester.pumpAndSettle();
      expect(may.dsGoi, isNot(contains('DELETE /gio-hang/1'))); // không đồng ý thì không xóa

      await tester.tap(find.byKey(const Key('xoa1')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
      await tester.pumpAndSettle();
      expect(may.dsGoi, contains('DELETE /gio-hang/1'));
      expect(find.text('Khô cá dứa 500 g'), findsNothing);
      expect(find.text('Hoàn tác'), findsOneWidget);

      await tester.tap(find.text('Hoàn tác'));
      await tester.pumpAndSettle();
      expect(may.body('PUT /gio-hang/1'), {'soLuong': 2});
      expect(find.text('Khô cá dứa 500 g'), findsOneWidget);
    });

    testWidgets('form đặt hàng chặn gửi khi thiếu dữ liệu; hợp lệ thì pop trả đơn mới', (tester) async {
      await _dangNhapKhach();
      final may = MayChuGia({
        'GET /don-hang/hinh-thuc-giao': (_) => traJson(hinhThucGiaoMau),
        'POST /don-hang': (_) => traJson(donMau(id: 77, trangThai: 'CHO_XAC_NHAN'), 201),
      });
      final trang = await _moQuaTrangChu<DonHang>(
          tester, DatHangScreen(tamTinh: 860000, repository: DonHangRepository(may.api)));
      expect(find.text('0911000001'), findsOneWidget); // điền sẵn từ tài khoản

      await tester.ensureVisible(find.byKey(const Key('nutXacNhanDat')));
      await tester.tap(find.byKey(const Key('nutXacNhanDat')));
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
          find.byKey(const Key('oHinhThucGiao')), find.byType(SingleChildScrollView), const Offset(0, 300));
      expect(find.text('Vui lòng chọn hình thức giao'), findsOneWidget);
      expect(find.text('Vui lòng nhập địa chỉ giao'), findsOneWidget);
      expect(may.dsGoi, isNot(contains('POST /don-hang')));

      await tester.tap(find.byKey(const Key('oHinhThucGiao')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Giao nhanh').last);
      await tester.pumpAndSettle();
      expect(find.text('910.000 đ'), findsOneWidget); // ước tính = tạm tính + phí giao
      await tester.enterText(find.byKey(const Key('oDiaChi')), '12 Lê Lợi, Quận 1');
      await tester.ensureVisible(find.byKey(const Key('nutXacNhanDat')));
      await tester.tap(find.byKey(const Key('nutXacNhanDat')));
      await tester.pumpAndSettle();

      final body = may.body('POST /don-hang');
      expect(body['hinhThucGiao'], 'NHANH');
      expect(body.containsKey('cacDong'), isFalse); // đặt cả giỏ
      expect(body.containsKey('tongTien'), isFalse); // tiền do backend tính
      expect(trang.ketQua, isA<DonHang>().having((d) => d.id, 'id', 77));
    });
  });

  group('Đơn hàng', () {
    testWidgets('danh sách đơn ListView.builder và lọc theo trạng thái', (tester) async {
      await _dangNhapKhach();
      final may = MayChuGia({
        'GET /don-hang': (req) => traJson({
              'duLieu': [
                {
                  'id': 45, 'trangThai': req.url.queryParameters['trangThai'] ?? 'DA_GIAO', 'hinhThucGiao': 'TIEU_CHUAN',
                  'tongTien': 90000, 'taoLuc': '2026-09-17T21:00:00.000Z', 'soSanPham': 2,
                  'tenSanPhamDau': 'Bánh tráng trộn hộp', 'anhSanPhamDau': null,
                },
              ],
              'phanTrang': {'trang': 1, 'kichThuoc': 100, 'tong': 1},
            }),
      });
      await tester.pumpWidget(MaterialApp(home: DonHangScreen(repository: DonHangRepository(may.api))));
      await tester.pumpAndSettle();
      expect(find.text('Đơn #45'), findsOneWidget);
      expect(find.text('Bánh tráng trộn hộp và 1 sản phẩm khác'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Chờ xác nhận'));
      await tester.pumpAndSettle();
      expect(may.cuoi('GET /don-hang').url.queryParameters['trangThai'], 'CHO_XAC_NHAN');
    });

    testWidgets('đơn đã giao: xác nhận "Đã nhận hàng" rồi hiện nút Đánh giá cho sản phẩm chưa đánh giá',
        (tester) async {
      await _dangNhapKhach();
      var trangThai = 'DA_GIAO';
      final may = MayChuGia({
        'GET /don-hang/50': (_) => traJson(donMau(trangThai: trangThai)),
        'PATCH /don-hang/50/trang-thai': (req) {
          trangThai = (jsonDecode(req.body) as Map)['trangThai'] as String;
          return traJson({'id': 50, 'trangThai': trangThai});
        },
      });
      await tester.pumpWidget(
          MaterialApp(home: ChiTietDonScreen(donHangId: 50, repository: DonHangRepository(may.api))));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('nutHuyDon')), findsNothing);
      expect(find.byKey(const Key('danhGia29')), findsNothing); // chưa nhận thì chưa đánh giá
      expect(find.textContaining('012880F9779E6D99FBAC'), findsOneWidget); // mã lô của dòng đơn

      await tester.tap(find.byKey(const Key('nutDaNhan')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Đã nhận'));
      await tester.pumpAndSettle();
      expect(may.body('PATCH /don-hang/50/trang-thai')['trangThai'], 'DA_NHAN');
      expect(find.byKey(const Key('danhGia29')), findsOneWidget);
      expect(find.text('Đã đánh giá'), findsOneWidget); // dòng 16 đã đánh giá
    });

    testWidgets('đơn chờ xác nhận có nút Hủy kèm xác nhận', (tester) async {
      await _dangNhapKhach();
      final may = MayChuGia({
        'GET /don-hang/50': (_) => traJson(donMau(trangThai: 'CHO_XAC_NHAN')),
        'PATCH /don-hang/50/trang-thai': (_) => traJson({}),
      });
      await tester.pumpWidget(
          MaterialApp(home: ChiTietDonScreen(donHangId: 50, repository: DonHangRepository(may.api))));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nutHuyDon')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Hủy đơn'));
      await tester.pumpAndSettle();
      expect(may.body('PATCH /don-hang/50/trang-thai')['trangThai'], 'DA_HUY');
    });
  });

  group('Đánh giá và phản ánh', () {
    testWidgets('đánh giá bắt buộc chọn sao, gửi đúng body và pop trả true', (tester) async {
      await _dangNhapKhach();
      final may = MayChuGia({'POST /danh-gia': (_) => traJson({'id': 1}, 201)});
      final trang = await _moQuaTrangChu<bool>(
        tester,
        DanhGiaScreen(donHangId: 50, sanPhamId: 29, tenSanPham: 'Bánh tráng', repository: DanhGiaRepository(may.api)),
      );
      await tester.tap(find.byKey(const Key('nutGuiDanhGia')));
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng chọn số sao'), findsOneWidget);
      expect(may.daNhan, isEmpty);

      await tester.tap(find.byKey(const Key('sao4')));
      await tester.enterText(find.byKey(const Key('oNoiDungDanhGia')), 'Ngon, giòn');
      await tester.tap(find.byKey(const Key('nutGuiDanhGia')));
      await tester.pumpAndSettle();
      expect(may.body('POST /danh-gia'), {'donHangId': 50, 'sanPhamId': 29, 'soSao': 4, 'noiDung': 'Ngon, giòn'});
      expect(trang.ketQua, true);
    });

    testWidgets('phản ánh từ hành trình lô gửi kèm mã lô; nội dung quá ngắn bị chặn', (tester) async {
      await _dangNhapKhach();
      final may = MayChuGia({'POST /bao-cao-vi-pham': (_) => traJson({'id': 1}, 201)});
      final trang = await _moQuaTrangChu<bool>(
        tester,
        PhanAnhScreen(
          sanPhamId: 1,
          tenSanPham: 'Khô cá dứa',
          maTruyXuat: 'B056FB25CA6642785532',
          repository: PhanAnhRepository(may.api),
        ),
      );
      await tester.tap(find.byKey(const Key('oLoaiPhanAnh')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nghi hàng giả').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('oNoiDungPhanAnh')), 'ngắn');
      await tester.tap(find.byKey(const Key('nutGuiPhanAnh')));
      await tester.pumpAndSettle();
      expect(find.text('Mô tả cụ thể hơn (ít nhất 10 ký tự)'), findsOneWidget);
      expect(may.daNhan, isEmpty);

      await tester.enterText(find.byKey(const Key('oNoiDungPhanAnh')), 'Bao bì khác hẳn ảnh trên app');
      await tester.tap(find.byKey(const Key('nutGuiPhanAnh')));
      await tester.pumpAndSettle();
      expect(may.body('POST /bao-cao-vi-pham'), {
        'sanPhamId': 1,
        'loai': 'HANG_GIA',
        'noiDung': 'Bao bì khác hẳn ảnh trên app',
        'maTruyXuat': 'B056FB25CA6642785532',
      });
      expect(trang.ketQua, true);
    });
  });

  testWidgets('chi tiết sản phẩm: khách chưa đăng nhập bấm Thêm vào giỏ thì mở đăng nhập, xong quay lại thêm',
      (tester) async {
    final may = MayChuGia({
      'GET /san-pham/1': (_) => traJson(chiTietSanPhamMau),
      'GET /danh-gia': (_) => traJson(trangDanhGiaMau),
      'POST /auth/dang-nhap': (_) => traJson({'token': 'tk', 'nguoiDung': nguoiDungKhach}),
      'GET /yeu-thich': (_) => traJson([]),
      'GET /gio-hang': (_) => traJson(gioMau([2])),
      'PUT /gio-hang/1': (_) => traJson(gioMau([3])),
    });
    ApiClient.macDinh = may.api; // màn hình đăng nhập mở từ chi tiết dùng ApiClient chung
    await tester.pumpWidget(MaterialApp(
      home: ChiTietSanPhamScreen(
        sanPhamId: 1,
        sanPhamRepository: SanPhamRepository(may.api),
        donHangRepository: DonHangRepository(may.api),
        tuongTacRepository: TuongTacRepository(may.api),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Khô cá dứa 500 g'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Rất hài lòng, sẽ mua lại.'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('MAU-OCOP-001'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nutThemVaoGio')));
    await tester.pumpAndSettle();
    expect(find.byType(DangNhapScreen), findsOneWidget);
    await tester.enterText(find.byKey(const Key('oEmail')), 'khach1@ocop.example');
    await tester.enterText(find.byKey(const Key('oMatKhau')), 'Demo@12345');
    await tester.tap(find.byKey(const Key('nutDangNhap')));
    await tester.pumpAndSettle();

    expect(find.byType(DangNhapScreen), findsNothing);
    expect(may.body('PUT /gio-hang/1'), {'soLuong': 3}); // 2 đang có + 1
    expect(find.textContaining('Đã thêm vào giỏ'), findsOneWidget);
  });

  group('Nhà cung cấp', () {
    testWidgets('chưa có hồ sơ (404 CHUA_CO_HO_SO) thì mời tạo hồ sơ', (tester) async {
      final may = MayChuGia({'GET /cua-toi/nha-cung-cap': (_) => traLoi(404, 'CHUA_CO_HO_SO', 'Chưa có hồ sơ.')});
      await tester.pumpWidget(MaterialApp(home: HoSoNccScreen(repository: CuaToiRepository(may.api))));
      await tester.pumpAndSettle();
      expect(find.textContaining('Bạn chưa gửi hồ sơ'), findsOneWidget);
      expect(find.text('Tạo hồ sơ'), findsOneWidget);
    });

    testWidgets('hồ sơ bị từ chối hiện lý do và cho sửa; hồ sơ đã duyệt thì khóa sửa', (tester) async {
      var hoSo = Map<String, dynamic>.from(hoSoMau);
      final may = MayChuGia({'GET /cua-toi/nha-cung-cap': (_) => traJson(hoSo)});
      await tester.pumpWidget(MaterialApp(home: HoSoNccScreen(repository: CuaToiRepository(may.api))));
      await tester.pumpAndSettle();
      expect(find.text('Bị từ chối'), findsOneWidget);
      expect(find.textContaining('Ảnh chứng nhận mờ'), findsOneWidget);
      expect(find.byKey(const Key('nutSuaHoSo')), findsOneWidget);

      hoSo = {...hoSoMau, 'trangThaiDuyet': 'DA_DUYET', 'lyDoTuChoi': null};
      await tester.pumpWidget(MaterialApp(home: HoSoNccScreen(key: UniqueKey(), repository: CuaToiRepository(may.api))));
      await tester.pumpAndSettle();
      expect(find.text('Đã duyệt'), findsOneWidget);
      expect(find.byKey(const Key('nutSuaHoSo')), findsNothing);
    });

    testWidgets('sản phẩm của tôi: chip trạng thái, lý do từ chối, số lô, tồn kho', (tester) async {
      final may = MayChuGia({'GET /cua-toi/san-pham': (_) => traJson(sanPhamCuaToiMau)});
      await tester.pumpWidget(MaterialApp(home: SanPhamCuaToiScreen(repository: CuaToiRepository(may.api))));
      await tester.pumpAndSettle();
      expect(find.text('Đã duyệt'), findsOneWidget);
      expect(find.text('Bị từ chối'), findsOneWidget);
      expect(find.text('Lý do từ chối: Thiếu ảnh nhãn'), findsOneWidget);
      expect(find.text('2 lô · tồn 543'), findsOneWidget);
    });
  });

  group('Khung app theo vai trò', () {
    Map<String, TuyenGia> tuyenChung() => {
          'GET /vung-nguyen-lieu': (_) => traJson([]),
          'GET /san-pham': (_) => traJson({'duLieu': [], 'phanTrang': {'trang': 1, 'kichThuoc': 100, 'tong': 0}}),
          'GET /gio-hang': (_) => traJson(gioMau([1])),
          'GET /don-hang': (_) => traJson({'duLieu': [], 'phanTrang': {'trang': 1, 'kichThuoc': 100, 'tong': 0}}),
          'GET /cua-toi/nha-cung-cap': (_) => traJson(hoSoMau),
          'GET /cua-toi/san-pham': (_) => traJson([]),
        };

    testWidgets('khách vãng lai thấy tab Giỏ hàng nhưng được mời đăng nhập', (tester) async {
      ApiClient.macDinh = MayChuGia(tuyenChung()).api;
      await tester.pumpWidget(const MaterialApp(home: KhungChinh()));
      await tester.pumpAndSettle();
      expect(find.text('Giỏ hàng'), findsOneWidget);
      await tester.tap(find.text('Giỏ hàng'));
      await tester.pumpAndSettle();
      expect(find.text('Đăng nhập để xem giỏ hàng.'), findsOneWidget);
    });

    testWidgets('nhà cung cấp thấy bộ tab riêng, không có giỏ/đơn', (tester) async {
      SharedPreferences.setMockInitialValues({'token': 'tk', 'nguoiDung': jsonEncode(nguoiDungNcc)});
      ApiClient.macDinh = MayChuGia({...tuyenChung(), 'GET /auth/toi': (_) => traJson(nguoiDungNcc)}).api;
      await tester.pumpWidget(const MaterialApp(home: KhungChinh()));
      await tester.pumpAndSettle();
      expect(find.text('Hồ sơ'), findsOneWidget);
      expect(find.text('Giỏ hàng'), findsNothing);
      expect(find.text('Đơn hàng'), findsNothing);
    });

    testWidgets('token hết hạn (401 ở /auth/toi): xóa phiên và đưa về màn hình đăng nhập', (tester) async {
      SharedPreferences.setMockInitialValues({'token': 'het-han', 'nguoiDung': jsonEncode(nguoiDungKhach)});
      ApiClient.macDinh = MayChuGia({
        ...tuyenChung(),
        'GET /auth/toi': (_) => traLoi(401, 'TOKEN_HET_HAN', 'Token hết hạn.'),
        'GET /gio-hang': (_) => traLoi(401, 'TOKEN_HET_HAN', 'Token hết hạn.'),
        'GET /don-hang': (_) => traLoi(401, 'TOKEN_HET_HAN', 'Token hết hạn.'),
      }).api;
      await tester.pumpWidget(const MaterialApp(home: KhungChinh()));
      await tester.pumpAndSettle();
      expect(find.byType(DangNhapScreen), findsOneWidget);
      expect(find.text('Phiên đăng nhập đã hết hạn.'), findsOneWidget);
      expect(await TokenStore.layToken(), isNull);
      expect(PhienDangNhap.daDangNhap, isFalse);
    });
  });
}
