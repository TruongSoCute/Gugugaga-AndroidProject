// Kiểm thử hợp đồng API với backend THẬT: repository và model của app có đọc đúng JSON không.
// Chỉ chạy khi có biến môi trường OCOP_API_TEST_URL (vd http://localhost:3000) trỏ tới
// backend vừa chạy db:reset; nếu không thì bỏ qua.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ocop_client/data/api_client.dart';
import 'package:ocop_client/data/san_pham_repository.dart';
import 'package:ocop_client/data/truy_xuat_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final url = Platform.environment['OCOP_API_TEST_URL'];
  final boQua = url == null || url.isEmpty ? 'chưa đặt OCOP_API_TEST_URL' : null;

  setUp(() => SharedPreferences.setMockInitialValues({}));

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
}
