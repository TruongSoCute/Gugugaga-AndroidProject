import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/customer_interactions_repository.dart';
import '../models/supplier.dart';
import '../widgets/network_image_view.dart';
import '../widgets/dialogs.dart';
import '../widgets/error_state.dart';
import '../widgets/empty_state.dart';
import 'suppliers_screen.dart';

/// Nhà cung cấp đang theo dõi (GET /theo-doi). Bỏ theo dõi có SnackBar "Hoàn tác".
class FollowedSuppliersScreen extends StatefulWidget {
  const FollowedSuppliersScreen({super.key, this.repository});

  final CustomerInteractionsRepository? repository;

  @override
  State<FollowedSuppliersScreen> createState() => _FollowedSuppliersScreenState();
}

class _FollowedSuppliersScreenState extends State<FollowedSuppliersScreen> {
  late final CustomerInteractionsRepository _repo = widget.repository ?? CustomerInteractionsRepository(ApiClient.macDinh);

  bool _dangTai = true;
  String? _loi;
  List<FollowedSupplier> _ds = [];

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
      final ds = await _repo.dsTheoDoi();
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
    final ncc = _ds[viTri];
    try {
      await _repo.boTheoDoi(ncc.id);
      if (!mounted) return;
      setState(() => _ds.removeAt(viTri));
      thongBao(
        context,
        'Đã bỏ theo dõi ${ncc.ten}.',
        action: SnackBarAction(label: 'Hoàn tác', onPressed: () => _hoanTac(ncc, viTri)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      thongBao(context, e.thongDiepDayDu);
    }
  }

  Future<void> _hoanTac(FollowedSupplier ncc, int viTri) async {
    try {
      await _repo.theoDoi(ncc.id);
      if (!mounted) return;
      setState(() => _ds.insert(viTri.clamp(0, _ds.length), ncc));
    } on ApiException catch (e) {
      if (!mounted) return;
      thongBao(context, 'Không hoàn tác được: ${e.thongDiepDayDu}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Nhà cung cấp đang theo dõi')), body: _noiDung());
  }

  Widget _noiDung() {
    if (_dangTai) return const Center(child: CircularProgressIndicator());
    if (_loi != null) return ErrorState(thongDiep: _loi!, onThuLai: _tai);
    if (_ds.isEmpty) {
      return const EmptyState(icon: Icons.storefront_outlined, thongDiep: 'Bạn chưa theo dõi nhà cung cấp nào.');
    }
    return RefreshIndicator(
      onRefresh: _tai,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        itemCount: _ds.length,
        itemBuilder: (context, i) {
          final ncc = _ds[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10), child: NetworkImageView(url: ncc.anhCoSoUrl, width: 56, height: 56)),
              title: Text(ncc.ten, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${ncc.tenVung} · ${ncc.soSanPham} sản phẩm'),
              trailing: TextButton(
                key: Key('boTheoDoi${ncc.id}'),
                onPressed: () => _bo(i),
                child: const Text('Bỏ theo dõi'),
              ),
              onTap: () async {
                await Navigator.push(
                    context, MaterialPageRoute<void>(builder: (_) => SuppliersScreen(nhaCungCapId: ncc.id)));
                if (mounted) await _tai();
              },
            ),
          );
        },
      ),
    );
  }
}
