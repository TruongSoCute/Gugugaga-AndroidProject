import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/customer_interactions_repository.dart';
import '../models/product.dart';
import '../utils/formatting.dart';
import '../widgets/network_image_view.dart';
import '../widgets/theme_widgets.dart';
import '../widgets/dialogs.dart';
import '../widgets/error_state.dart';
import '../widgets/empty_state.dart';
import 'product_details_screen.dart';

/// Sản phẩm yêu thích (GET /yeu-thich). Bỏ yêu thích có SnackBar "Hoàn tác" (PUT lại).
class FavoriteProductsScreen extends StatefulWidget {
  const FavoriteProductsScreen({super.key, this.repository});

  final CustomerInteractionsRepository? repository;

  @override
  State<FavoriteProductsScreen> createState() => _FavoriteProductsScreenState();
}

class _FavoriteProductsScreenState extends State<FavoriteProductsScreen> {
  late final CustomerInteractionsRepository _repo = widget.repository ?? CustomerInteractionsRepository(ApiClient.macDinh);

  bool _dangTai = true;
  String? _loi;
  List<ProductSummary> _ds = [];

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
      final ds = await _repo.dsYeuThich();
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

  Future<void> _bo(int viTri) async {
    final sp = _ds[viTri];
    try {
      await _repo.boYeuThich(sp.id);
      if (!mounted) return;
      setState(() => _ds.removeAt(viTri));
      thongBao(
        context,
        'Đã bỏ "${sp.ten}" khỏi yêu thích.',
        action: SnackBarAction(label: 'Hoàn tác', onPressed: () => _hoanTac(sp, viTri)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      thongBao(context, e.thongDiepDayDu);
    }
  }

  Future<void> _hoanTac(ProductSummary sp, int viTri) async {
    try {
      await _repo.yeuThich(sp.id);
      if (!mounted) return;
      setState(() => _ds.insert(viTri.clamp(0, _ds.length), sp));
    } on ApiException catch (e) {
      if (!mounted) return;
      thongBao(context, 'Không hoàn tác được: ${e.thongDiepDayDu}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Sản phẩm yêu thích')), body: _noiDung());
  }

  Widget _noiDung() {
    if (_dangTai) return const Center(child: CircularProgressIndicator());
    if (_loi != null) return ErrorState(thongDiep: _loi!, onThuLai: _tai);
    if (_ds.isEmpty) {
      return const EmptyState(icon: Icons.favorite_border_rounded, thongDiep: 'Chưa có sản phẩm yêu thích.');
    }
    return RefreshIndicator(
      onRefresh: _tai,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        itemCount: _ds.length,
        itemBuilder: (context, i) {
          final sp = _ds[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10), child: NetworkImageView(url: sp.anhUrl, width: 58, height: 58)),
              title: Text(sp.ten, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${Formatting.tien(sp.gia)} / ${sp.donViTinh}\n${sp.tenNhaCungCap ?? ''}'),
              isThreeLine: true,
              trailing: IconButton(
                key: Key('boYeuThich${sp.id}'),
                tooltip: 'Bỏ yêu thích',
                icon: const Icon(Icons.favorite_rounded, color: OcopColors.doLoi),
                onPressed: () => _bo(i),
              ),
              onTap: () async {
                await Navigator.push(
                    context, MaterialPageRoute<void>(builder: (_) => ProductDetailsScreen(sanPhamId: sp.id)));
                if (mounted) await _tai();
              },
            ),
          );
        },
      ),
    );
  }
}
