import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ocop_client/data/api_client.dart';
import 'package:ocop_client/data/san_pham_repository.dart';
import 'package:ocop_client/screens/san_pham_screen.dart';
import 'package:ocop_client/screens/tra_cuu_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Form tra cứu chặn gửi khi mã trống hoặc sai định dạng', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TraCuuScreen()));

    await tester.tap(find.text('Xem hành trình lô'));
    await tester.pump();
    expect(find.text('Vui lòng nhập mã truy xuất in trên bao bì'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('oMaTruyXuat')), 'LO-001');
    await tester.tap(find.text('Xem hành trình lô'));
    await tester.pump();
    expect(find.textContaining('Mã gồm 20 ký tự'), findsOneWidget);
  });

  testWidgets('Danh sách sản phẩm hiện dữ liệu từ API', (tester) async {
    final api = ApiClient(
      baseUrl: 'http://may-chu',
      client: MockClient((req) async {
        if (req.url.path == '/vung-nguyen-lieu') {
          return http.Response.bytes(utf8.encode('[{"id":1,"ten":"Cần Giờ"}]'), 200);
        }
        return http.Response.bytes(
          utf8.encode('{"duLieu":[{"id":1,"ten":"Khô cá dứa 500 g","donViTinh":"gói","gia":320000,'
              '"hangSao":4,"anhUrl":null,"tenNhaCungCap":"HTX Cần Giờ","tenVung":"Cần Giờ","soDanhGia":2,'
              '"diemTrungBinh":4.5}],"phanTrang":{"trang":1,"kichThuoc":100,"tong":1}}'),
          200,
        );
      }),
    );
    await tester.pumpWidget(MaterialApp(home: SanPhamScreen(repository: SanPhamRepository(api))));
    expect(find.byType(CircularProgressIndicator), findsOneWidget); // trạng thái đang tải
    await tester.pumpAndSettle();
    expect(find.text('Khô cá dứa 500 g'), findsOneWidget);
    expect(find.text('320.000 đ'), findsOneWidget);
  });

  testWidgets('Danh sách sản phẩm báo lỗi và có nút Thử lại khi mất mạng', (tester) async {
    final api = ApiClient(
      baseUrl: 'http://may-chu',
      client: MockClient((req) async => throw http.ClientException('mất mạng')),
    );
    await tester.pumpWidget(MaterialApp(home: SanPhamScreen(repository: SanPhamRepository(api))));
    await tester.pumpAndSettle();
    expect(find.textContaining('Không kết nối được máy chủ'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });
}
