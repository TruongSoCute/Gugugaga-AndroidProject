import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocop_client/models/batch_journey.dart';
import 'package:ocop_client/models/sourcing_region.dart';
import 'package:ocop_client/screens/region_map_screen.dart';

void main() {
  test('SourcingRegion.fromJson đọc tọa độ và mô tả từ API', () {
    final v = SourcingRegion.fromJson({
      'id': 1,
      'ten': 'Cần Giờ',
      'moTa': 'Vùng ven biển',
      'viDo': 10.4114,
      'kinhDo': '106.9539',
    });
    expect(v.id, 1);
    expect(v.ten, 'Cần Giờ');
    expect(v.moTa, 'Vùng ven biển');
    expect(v.viDo, closeTo(10.4114, 0.0001));
    expect(v.kinhDo, closeTo(106.9539, 0.0001));
    expect(v.coToaDo, true);
  });

  test('BatchJourney.fromJson đọc tọa độ vùng nguyên liệu', () {
    final lo = BatchJourney.fromJson({
      'maTruyXuat': 'B056FB25CA6642785532',
      'lo': {
        'ngaySanXuat': '2026-03-02',
        'hanSuDung': '2027-03-02',
        'nguoiSanXuat': 'Tổ A',
        'vungNguyenLieu': {
          'id': 2,
          'ten': 'Củ Chi',
          'moTa': 'Đất phù sa',
          'viDo': 10.9733,
          'kinhDo': 106.4932,
        },
      },
      'sanPham': {'id': 1, 'ten': 'Mật ong'},
      'nhaCungCap': {'ten': 'HTX A', 'chungNhan': []},
      'cacBuoc': [],
    });
    expect(lo.vungId, 2);
    expect(lo.vungNguyenLieu, 'Củ Chi');
    expect(lo.vungMoTa, 'Đất phù sa');
    expect(lo.vungViDo, closeTo(10.9733, 0.0001));
    expect(lo.vungKinhDo, closeTo(106.4932, 0.0001));
  });

  testWidgets('RegionMapScreen hiển thị thông báo khi chưa có tọa độ', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RegionMapScreen(dsVung: [SourcingRegion(id: 1, ten: 'Vùng chưa có tọa độ')]),
      ),
    );
    expect(find.textContaining('Chưa có tọa độ'), findsOneWidget);
  });

  testWidgets('RegionMapScreen hiển thị vùng đã chọn và nút lọc sản phẩm', (tester) async {
    int? ketQua;
    const ds = [
      SourcingRegion(id: 1, ten: 'Cần Giờ', moTa: 'Ven biển', viDo: 10.4114, kinhDo: 106.9539),
      SourcingRegion(id: 2, ten: 'Củ Chi', moTa: 'Phù sa', viDo: 10.9733, kinhDo: 106.4932),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              ketQua = await Navigator.push<int>(
                context,
                MaterialPageRoute(
                  builder: (_) => const RegionMapScreen(dsVung: ds, choPhepLoc: true),
                ),
              );
            },
            child: const Text('Mở bản đồ'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mở bản đồ'));
    await tester.pumpAndSettle();

    expect(find.text('Cần Giờ'), findsOneWidget);
    expect(find.text('OpenStreetMap contributors'), findsOneWidget);
    await tester.tap(find.byKey(const Key('markerVung_2')));
    await tester.pumpAndSettle();
    expect(find.text('Củ Chi'), findsOneWidget);
    await tester.tap(find.text('Lọc sản phẩm vùng này'));
    await tester.pumpAndSettle();
    expect(ketQua, 2);
  });
}
