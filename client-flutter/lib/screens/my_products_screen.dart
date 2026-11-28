import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/my_supplier_repository.dart';
import '../models/product.dart';
import '../utils/formatting.dart';
import '../widgets/network_image_view.dart';
import '../widgets/status_chip.dart';
import '../widgets/theme_widgets.dart';
import '../widgets/dialogs.dart';
import '../widgets/error_state.dart';
import '../widgets/empty_state.dart';
import 'product_form_screen.dart';

/// Sản phẩm của nhà cung cấp đang đăng nhập (GET /cua-toi/san-pham).
class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key, this.repository});

  final MySupplierRepository? repository;

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  late final MySupplierRepository _repo = widget.repository ?? MySupplierRepository(ApiClient.macDinh);

  bool _dangTai = true;
  String? _loi;
  List<MyProduct> _ds = const [];

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

  Future<void> _moForm([MyProduct? sp]) async {
    final kq = await Navigator.push<MyProduct>(
      context,
      MaterialPageRoute(builder: (_) => ProductFormScreen(sanPham: sp, repository: widget.repository)),
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
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm sản phẩm'),
      ),
    );
  }

  Widget _noiDung() {
    if (_dangTai) return const Center(child: CircularProgressIndicator());
    if (_loi != null) return ErrorState(thongDiep: _loi!, onThuLai: _tai);
    if (_ds.isEmpty) {
      return const EmptyState(
        icon: Icons.inventory_2_outlined,
        thongDiep: 'Chưa có sản phẩm. Hồ sơ cơ sở cần được gửi trước khi thêm sản phẩm.',
      );
    }
    return RefreshIndicator(
      onRefresh: _tai,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        itemCount: _ds.length,
        itemBuilder: (context, i) {
          final sp = _ds[i];
          final theme = Theme.of(context);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: sp.duocSua
                  ? () => _moForm(sp)
                  : () => thongBao(context, 'Sản phẩm đã duyệt không sửa được trên app.'),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: NetworkImageView(url: sp.anhUrl, width: 88, height: 96),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
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
                              const SizedBox(width: 6),
                              StatusChip(
                                  nhan: ApprovalStatus.ten(sp.trangThaiDuyet),
                                  mau: StatusChip.mauCua(sp.trangThaiDuyet)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${Formatting.tien(sp.gia)} / ${sp.donViTinh}'
                            '${sp.hangSao == null ? '' : ' · ${sp.hangSao} sao OCOP'}',
                            style: const TextStyle(color: OcopColors.xanhOcop, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text('${sp.soLo} lô · tồn ${sp.tonKho}', style: theme.textTheme.bodySmall),
                          if (sp.trangThaiDuyet == ApprovalStatus.tuChoi && sp.lyDoTuChoi != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text('Lý do từ chối: ${sp.lyDoTuChoi}',
                                  style: theme.textTheme.bodySmall?.copyWith(color: OcopColors.doLoi)),
                            ),
                        ],
                      ),
                    ),
                    if (sp.duocSua)
                      const Padding(
                        padding: EdgeInsets.only(left: 4, top: 2),
                        child: Icon(Icons.edit_outlined, size: 18, color: OcopColors.chuPhu),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
