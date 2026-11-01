import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/cua_toi_repository.dart';
import '../models/san_pham.dart';
import '../utils/dinh_dang.dart';
import '../widgets/anh_mang.dart';
import '../widgets/chip_trang_thai.dart';
import '../widgets/hop_thoai.dart';
import '../widgets/trang_thai_loi.dart';
import '../widgets/trang_trong.dart';
import 'san_pham_form_screen.dart';

/// Sản phẩm của nhà cung cấp đang đăng nhập (GET /cua-toi/san-pham), mọi trạng thái:
/// chip trạng thái duyệt, lý do từ chối, số lô và tồn kho. ListView.builder.
/// Thêm/sửa mở SanPhamFormScreen và chờ sản phẩm trả về. Sản phẩm đã duyệt không sửa được.
class SanPhamCuaToiScreen extends StatefulWidget {
  const SanPhamCuaToiScreen({super.key, this.repository});

  final CuaToiRepository? repository;

  @override
  State<SanPhamCuaToiScreen> createState() => _SanPhamCuaToiScreenState();
}

class _SanPhamCuaToiScreenState extends State<SanPhamCuaToiScreen> {
  late final CuaToiRepository _repo = widget.repository ?? CuaToiRepository(ApiClient.macDinh);

  bool _dangTai = true;
  String? _loi;
  List<SanPhamCuaToi> _ds = const [];

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
      final ds = await _repo.dsSanPham();
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

  Future<void> _moForm([SanPhamCuaToi? sp]) async {
    final kq = await Navigator.push<SanPhamCuaToi>(
      context,
      MaterialPageRoute(builder: (_) => SanPhamFormScreen(sanPham: sp, repository: widget.repository)),
    );
    if (!mounted || kq == null) return;
    thongBao(context, sp == null ? 'Đã gửi "${kq.ten}" chờ duyệt.' : 'Đã cập nhật "${kq.ten}", chờ duyệt lại.');
    await _tai();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sản phẩm của tôi')),
      body: _noiDung(),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('nutThemSanPham'),
        onPressed: () => _moForm(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm sản phẩm'),
      ),
    );
  }

  Widget _noiDung() {
    if (_dangTai) return const Center(child: CircularProgressIndicator());
    if (_loi != null) return TrangThaiLoi(thongDiep: _loi!, onThuLai: _tai);
    if (_ds.isEmpty) {
      return const TrangTrong(
        icon: Icons.inventory_2_outlined,
        thongDiep: 'Chưa có sản phẩm. Hồ sơ cơ sở cần được gửi trước khi thêm sản phẩm.',
      );
    }
    return RefreshIndicator(
      onRefresh: _tai,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: _ds.length,
        itemBuilder: (context, i) {
          final sp = _ds[i];
          final theme = Theme.of(context);
          return Card(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: sp.duocSua
                  ? () => _moForm(sp)
                  : () => thongBao(context, 'Sản phẩm đã duyệt không sửa được trên app.'),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnhMang(url: sp.anhUrl, width: 88, height: 104),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(sp.ten,
                                    style: theme.textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                              ),
                              ChipTrangThai(
                                  nhan: TrangThaiDuyet.ten(sp.trangThaiDuyet),
                                  mau: ChipTrangThai.mauCua(sp.trangThaiDuyet)),
                            ],
                          ),
                          Text('${DinhDang.tien(sp.gia)} / ${sp.donViTinh}'
                              '${sp.hangSao == null ? '' : ' · ${sp.hangSao} sao OCOP'}'),
                          Text('${sp.soLo} lô · tồn ${sp.tonKho}', style: theme.textTheme.bodySmall),
                          if (sp.trangThaiDuyet == TrangThaiDuyet.tuChoi && sp.lyDoTuChoi != null)
                            Text('Lý do từ chối: ${sp.lyDoTuChoi}',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
                        ],
                      ),
                    ),
                  ),
                  if (sp.duocSua)
                    const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.edit_outlined, size: 20)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
