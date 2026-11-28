import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ocop_client/data/api_client.dart';
import 'package:ocop_client/data/product_repository.dart';
import 'package:ocop_client/data/traceability_repository.dart';
import 'package:ocop_client/models/batch_journey.dart';
import 'package:ocop_client/utils/formatting.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// JSON mẫu đúng dạng backend trả về (docs/development/API.md).
const hanhTrinhMau = '''
{
  "maTruyXuat": "B056FB25CA6642785532",
  "lo": {
    "ngaySanXuat": "2026-03-02", "hanSuDung": "2027-03-02",
    "nguoiSanXuat": "Tổ sản xuất B (mẫu)", "anhHienTruongUrl": "https://example.com/lo.jpg",
    "vungNguyenLieu": { "id": 1, "ten": "Cần Giờ", "moTa": "…", "viDo": 10.4114, "kinhDo": 106.9539 }
  },
  "sanPham": { "id": 1, "ten": "Khô cá dứa 500 g", "moTa": "…", "donViTinh": "gói", "hangSao": 4, "anhUrl": null },
  "nhaCungCap": {
    "id": 1, "ten": "HTX Hải sản khô Cần Giờ (mẫu)", "diaChi": "Xã Long Hòa", "anhCoSoUrl": null, "vung": "Cần Giờ",
    "chungNhan": [{ "loai": "OCOP", "soHieu": "MAU-OCOP-001", "ngayCap": "2024-03-11", "ngayHetHan": "2027-03-11", "anhUrl": null, "conHieuLuc": true }]
  },
  "cacBuoc": [
    { "thuTu": 1, "tenBuoc": "Thu hoạch", "moTa": "…", "thoiDiem": "2026-02-27T00:00:00.000Z", "anhUrl": null },
    { "thuTu": 2, "tenBuoc": "Sơ chế", "moTa": null, "thoiDiem": "2026-02-28T01:00:00.000Z", "anhUrl": null }
  ]
}
''';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Formatting', () {
    test('định dạng tiền theo kiểu Việt Nam', () {
      expect(Formatting.tien(320000), '320.000 đ');
      expect(Formatting.tien(2200000), '2.200.000 đ');
      expect(Formatting.tien(500), '500 đ');
      expect(Formatting.tien(0), '0 đ');
    });

    test('đổi ngày YYYY-MM-DD sang DD/MM/YYYY', () {
      expect(Formatting.ngay('2026-03-02'), '02/03/2026');
    });
  });

  group('Tách mã truy xuất', () {
    test('nhận mã 20 ký tự, chấp nhận chữ thường và khoảng trắng', () {
      expect(TraceabilityRepository.tachMa(' b056fb25ca6642785532 '), 'B056FB25CA6642785532');
    });

    test('nhận nội dung QR dạng đường dẫn', () {
      expect(TraceabilityRepository.tachMa('https://ocop-backend.onrender.com/truy-xuat/B056FB25CA6642785532'),
          'B056FB25CA6642785532');
      expect(TraceabilityRepository.tachMa('http://10.0.2.2:3000/truy-xuat/b056fb25ca6642785532?x=1'),
          'B056FB25CA6642785532');
    });

    test('từ chối mã sai định dạng', () {
      expect(TraceabilityRepository.tachMa(''), isNull);
      expect(TraceabilityRepository.tachMa('LO-001'), isNull);
      expect(TraceabilityRepository.tachMa('B056FB25CA664278553'), isNull); // 19 ký tự
      expect(TraceabilityRepository.tachMa("' OR 1=1 --"), isNull);
    });
  });

  test('đọc đúng hành trình của lô từ JSON backend', () {
    final lo = BatchJourney.fromJson(jsonDecode(hanhTrinhMau) as Map<String, dynamic>);
    expect(lo.maTruyXuat, 'B056FB25CA6642785532');
    expect(lo.vungNguyenLieu, 'Cần Giờ');
    expect(lo.hangSao, 4);
    expect(lo.chungNhan.single.conHieuLuc, isTrue);
    expect(lo.cacBuoc.map((b) => b.tenBuoc), ['Thu hoạch', 'Sơ chế']);
  });

  group('ApiClient', () {
    test('gọi đúng đường dẫn truy xuất và không gửi token khi chưa đăng nhập', () async {
      late http.Request daGui;
      final api = ApiClient(
        baseUrl: 'http://may-chu',
        client: MockClient((req) async {
          daGui = req;
          return http.Response.bytes(utf8.encode(hanhTrinhMau), 200,
              headers: {'content-type': 'application/json; charset=utf-8'});
        }),
      );
      final lo = await TraceabilityRepository(api).layHanhTrinh('B056FB25CA6642785532');
      expect(daGui.url.toString(), 'http://may-chu/truy-xuat/B056FB25CA6642785532');
      expect(daGui.headers.containsKey('Authorization'), isFalse);
      expect(lo.tenSanPham, 'Khô cá dứa 500 g');
    });

    test('gắn token khi đã đăng nhập', () async {
      SharedPreferences.setMockInitialValues({'token': 'abc'});
      late http.Request daGui;
      final api = ApiClient(
        baseUrl: 'http://may-chu',
        client: MockClient((req) async {
          daGui = req;
          return http.Response('[]', 200);
        }),
      );
      await api.get('/vung-nguyen-lieu');
      expect(daGui.headers['Authorization'], 'Bearer abc');
    });

    test('lỗi 404 mang thông điệp và mã HTTP của backend', () async {
      final api = ApiClient(
        baseUrl: 'http://may-chu',
        client: MockClient((req) async => http.Response.bytes(
            utf8.encode('{"loi":{"ma":"KHONG_TIM_THAY","thongDiep":"Không tìm thấy lô."}}'), 404)),
      );
      await expectLater(
        TraceabilityRepository(api).layHanhTrinh('0123456789ABCDEF0123'),
        throwsA(isA<ApiException>()
            .having((e) => e.maHttp, 'maHttp', 404)
            .having((e) => e.thongDiep, 'thongDiep', 'Không tìm thấy lô.')),
      );
    });

    test('lỗi mạng trả thông điệp dễ hiểu, không có mã HTTP', () async {
      final api = ApiClient(
        baseUrl: 'http://may-chu',
        client: MockClient((req) async => throw http.ClientException('mất mạng')),
      );
      await expectLater(
        api.get('/san-pham'),
        throwsA(isA<ApiException>().having((e) => e.loiMang, 'loiMang', isTrue)),
      );
    });

    test('lọc sản phẩm gửi đúng tham số vung và hangSao', () async {
      late http.Request daGui;
      final api = ApiClient(
        baseUrl: 'http://may-chu',
        client: MockClient((req) async {
          daGui = req;
          return http.Response('{"duLieu":[],"phanTrang":{"trang":1,"kichThuoc":100,"tong":0}}', 200);
        }),
      );
      final kq = await ProductRepository(api).dsSanPham(vungId: 1, hangSao: 5);
      expect(daGui.url.queryParameters, {'kichThuoc': '100', 'vung': '1', 'hangSao': '5'});
      expect(kq.tong, 0);
    });
  });
}
