import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/api_client.dart';
import '../data/order_repository.dart';
import '../models/order.dart';
import '../utils/formatting.dart';
import '../widgets/network_image_view.dart';
import '../widgets/status_chip.dart';
import '../widgets/animations.dart';
import '../widgets/theme_widgets.dart';
import '../widgets/error_state.dart';
import '../widgets/empty_state.dart';
import 'order_details_screen.dart';

/// Đơn hàng của tôi (GET /don-hang?trangThai=): ListView.builder, lọc theo trạng thái.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, this.repository});

  final OrderRepository? repository;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late final OrderRepository _repo = widget.repository ?? OrderRepository(ApiClient.macDinh);

  String? _trangThai;
  bool _dangTai = true;
  String? _loi;
  List<OrderSummary> _ds = const [];

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
      final ds = await _repo.dsDonHang(trangThai: _trangThai);
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

  Future<void> _moChiTiet(OrderSummary d) async {
    final daDoi = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => OrderDetailsScreen(donHangId: d.id, repository: widget.repository)),
    );
    if (!mounted) return;
    if (daDoi == true) await _tai();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đơn hàng của tôi')),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                for (final tt in <String?>[null, ...OrderStatus.tatCa])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(tt == null ? 'Tất cả' : OrderStatus.ten(tt)),
                      selected: _trangThai == tt,
                      backgroundColor: OcopColors.nenThe,
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        setState(() => _trangThai = tt);
                        _tai();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: _noiDung()),
        ],
      ),
    );
  }

  Widget _noiDung() {
    if (_dangTai) {
      return const AnimatedStateTransition(khoa: 'tai', child: Center(child: CircularProgressIndicator()));
    }
    if (_loi != null) {
      return AnimatedStateTransition(khoa: 'loi', child: ErrorState(thongDiep: _loi!, onThuLai: _tai));
    }
    if (_ds.isEmpty) {
      return AnimatedStateTransition(
        khoa: 'trong-${_trangThai ?? 'all'}',
        child: RefreshIndicator(
          onRefresh: _tai,
          child: ListView(children: const [
            SizedBox(height: 100),
            EmptyState(icon: Icons.receipt_long_outlined, thongDiep: 'Chưa có đơn hàng nào.'),
          ]),
        ),
      );
    }
    return AnimatedStateTransition(
      khoa: 'ds-${_trangThai ?? 'all'}-${_ds.length}',
      child: RefreshIndicator(
        onRefresh: _tai,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          itemCount: _ds.length,
          itemBuilder: (context, i) {
            final d = _ds[i];
            final theme = Theme.of(context);
            return FadeIn(
              thuTu: i,
              child: PressFeedback(
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _moChiTiet(d),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: NetworkImageView(url: d.anhSanPhamDau, width: 80, height: 84),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('Đơn #${d.id}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                                    const Spacer(),
                                    StatusChip(nhan: OrderStatus.ten(d.trangThai), mau: StatusChip.mauCua(d.trangThai)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${d.tenSanPhamDau ?? ''}${d.soSanPham > 1 ? ' và ${d.soSanPham - 1} sản phẩm khác' : ''}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(Formatting.thoiDiem(d.taoLuc), style: theme.textTheme.bodySmall),
                                    const Spacer(),
                                    Text(
                                      Formatting.tien(d.tongTien),
                                      style: theme.textTheme.titleSmall?.copyWith(color: OcopColors.chuChinh, fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
