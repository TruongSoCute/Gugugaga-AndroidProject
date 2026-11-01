import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/phan_anh_repository.dart';
import '../models/phan_anh.dart';
import '../utils/dinh_dang.dart';
import '../widgets/anh_mang.dart';
import '../widgets/chip_trang_thai.dart';
import '../widgets/trang_thai_loi.dart';
import '../widgets/trang_trong.dart';

/// Phản ánh của tôi (GET /bao-cao-vi-pham): trạng thái và kết quả xử lý của quản trị.
class PhanAnhCuaToiScreen extends StatefulWidget {
  const PhanAnhCuaToiScreen({super.key, this.repository});

  final PhanAnhRepository? repository;

  @override
  State<PhanAnhCuaToiScreen> createState() => _PhanAnhCuaToiScreenState();
}

class _PhanAnhCuaToiScreenState extends State<PhanAnhCuaToiScreen> {
  late final PhanAnhRepository _repo = widget.repository ?? PhanAnhRepository(ApiClient.macDinh);

  bool _dangTai = true;
  String? _loi;
  List<PhanAnh> _ds = const [];

  @override
  void initState() {
    super.initState();
    _tai();
  }

  Future<void> _tai() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    try {
      final ds = await _repo.dsCuaToi();
      if (!mounted) return;
      setState(() {
        _ds = ds;
        _dangTai = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loi = e.thongDiep;
        _dangTai = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Phản ánh của tôi')), body: _noiDung());
  }

  Widget _noiDung() {
    if (_dangTai) return const Center(child: CircularProgressIndicator());
    if (_loi != null) return TrangThaiLoi(thongDiep: _loi!, onThuLai: _tai);
    if (_ds.isEmpty) {
      return const TrangTrong(
        icon: Icons.report_outlined,
        thongDiep: 'Bạn chưa gửi phản ánh nào.\nGặp hàng nghi giả? Mở hành trình lô hoặc chi tiết sản phẩm và chọn "Phản ánh".',
      );
    }
    return RefreshIndicator(
      onRefresh: _tai,
      child: ListView.builder(
        itemCount: _ds.length,
        itemBuilder: (context, i) {
          final p = _ds[i];
          final theme = Theme.of(context);
          return Card(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AnhMang(url: p.anhUrl ?? p.anhSanPham, width: 48, height: 48),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.tenSanPham, style: theme.textTheme.titleSmall),
                            Text('${LoaiPhanAnh.ten(p.loai)} · ${DinhDang.thoiDiem(p.taoLuc)}',
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      ChipTrangThai(nhan: TrangThaiPhanAnh.ten(p.trangThai), mau: ChipTrangThai.mauCua(p.trangThai)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(p.noiDung),
                  if (p.maTruyXuat != null) Text('Lô: ${p.maTruyXuat}', style: theme.textTheme.bodySmall),
                  if (p.ketQuaXuLy != null) ...[
                    const Divider(),
                    Text('Kết quả xử lý', style: theme.textTheme.labelLarge),
                    Text(p.ketQuaXuLy!),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
