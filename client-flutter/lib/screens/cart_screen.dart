import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/order_repository.dart';
import '../models/order.dart';
import '../models/cart.dart';
import '../utils/formatting.dart';
import '../widgets/network_image_view.dart';
import '../widgets/animations.dart';
import '../widgets/theme_widgets.dart';
import '../widgets/dialogs.dart';
import '../widgets/error_state.dart';
import '../widgets/empty_state.dart';
import 'order_details_screen.dart';
import 'checkout_screen.dart';

/// Giỏ hàng của khách (GET /gio-hang). Sửa số lượng bằng PUT, xóa dòng có hộp thoại xác nhận
/// và SnackBar "Hoàn tác" (Hoàn tác = PUT lại số lượng cũ) — yêu cầu C.2 #6.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key, this.repository});

  final OrderRepository? repository;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final OrderRepository _repo = widget.repository ?? OrderRepository(ApiClient.macDinh);

  bool _dangTai = true;
  String? _loi;
  Cart? _gio;
  bool _dangCapNhat = false;

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
      final gio = await _repo.gioHang();
      if (!mounted) return;
      setState(() {
        _gio = gio;
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

  Future<void> _doiSoLuong(CartItem d, int soLuong) async {
    if (soLuong < 1 || soLuong > 999) return;
    setState(() => _dangCapNhat = true);
    try {
      final gio = await _repo.datSoLuong(d.sanPhamId, soLuong);
      if (!mounted) return;
      setState(() {
        _gio = gio;
        _dangCapNhat = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _dangCapNhat = false);
      thongBao(context, e.thongDiepDayDu);
    }
  }

  Future<void> _xoa(CartItem d) async {
    final dongY = await xacNhan(context,
        tieuDe: 'Xóa khỏi giỏ', noiDung: 'Xóa "${d.ten}" khỏi giỏ hàng?', nutDongY: 'Xóa', nguyHiem: true);
    if (!dongY || !mounted) return;
    setState(() => _dangCapNhat = true);
    try {
      final gio = await _repo.xoaKhoiGio(d.sanPhamId);
      if (!mounted) return;
      setState(() {
        _gio = gio;
        _dangCapNhat = false;
      });
      thongBao(
        context,
        'Đã xóa "${d.ten}".',
        action: SnackBarAction(label: 'Hoàn tác', onPressed: () => _hoanTac(d)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _dangCapNhat = false);
      thongBao(context, e.thongDiepDayDu);
    }
  }

  Future<void> _hoanTac(CartItem d) async {
    try {
      final gio = await _repo.datSoLuong(d.sanPhamId, d.soLuong);
      if (!mounted) return;
      setState(() => _gio = gio);
    } on ApiException catch (e) {
      if (!mounted) return;
      thongBao(context, 'Không hoàn tác được: ${e.thongDiepDayDu}');
    }
  }

  Future<void> _datHang() async {
    final gio = _gio!;
    final don = await Navigator.push<Order>(
      context,
      MaterialPageRoute(builder: (_) => CheckoutScreen(tamTinh: gio.tamTinh, repository: widget.repository)),
    );
    if (!mounted || don == null) return;
    thongBao(context, 'Đặt hàng thành công: đơn #${don.id}, tổng ${Formatting.tien(don.tongTien)}.');
    await _tai();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => OrderDetailsScreen(donHangId: don.id, repository: widget.repository)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gio = _gio;
    final coTheDat = gio != null && !gio.trong && gio.tamTinh > 0 && !_dangTai;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ hàng'),
        bottom: _dangCapNhat
            ? const PreferredSize(preferredSize: Size.fromHeight(3), child: LinearProgressIndicator())
            : null,
      ),
      body: _noiDung(),
      bottomNavigationBar: coTheDat
          ? Container(
              color: OcopColors.nenThe,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tạm tính', style: Theme.of(context).textTheme.bodySmall),
                            AnimatedNumber(
                              giaTri: gio.tamTinh,
                              text: Formatting.tien(gio.tamTinh),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(color: OcopColors.chuChinh, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      PressFeedback(
                        rungNhe: true,
                        child: FilledButton(
                          key: const Key('nutDatHang'),
                          onPressed: _dangCapNhat ? null : _datHang,
                          child: const Text('Đặt hàng'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _noiDung() {
    if (_dangTai) return const Center(child: CircularProgressIndicator());
    if (_loi != null) return ErrorState(thongDiep: _loi!, onThuLai: _tai);
    final ds = _gio?.duLieu ?? const <CartItem>[];
    if (ds.isEmpty) {
      return RefreshIndicator(
        onRefresh: _tai,
        child: ListView(children: const [
          SizedBox(height: 100),
          EmptyState(icon: Icons.shopping_cart_outlined, thongDiep: 'Giỏ hàng trống. Hãy chọn vài đặc sản OCOP!'),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _tai,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        itemCount: ds.length,
        itemBuilder: (context, i) => _CartItemRow(
          dong: ds[i],
          batTat: !_dangCapNhat,
          onDoiSoLuong: (sl) => _doiSoLuong(ds[i], sl),
          onXoa: () => _xoa(ds[i]),
        ),
      ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({required this.dong, required this.batTat, required this.onDoiSoLuong, required this.onXoa});

  final CartItem dong;
  final bool batTat;
  final ValueChanged<int> onDoiSoLuong;
  final VoidCallback onXoa;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canhBao = !dong.dangBan
        ? 'Sản phẩm đã ngừng bán'
        : (dong.conHang < dong.soLuong ? 'Chỉ còn ${dong.conHang} ${dong.donViTinh}' : null);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: NetworkImageView(url: dong.anhUrl, width: 88, height: 96),
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
                        child: Text(dong.ten, style: theme.textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                      IconButton(
                        key: Key('xoa${dong.sanPhamId}'),
                        tooltip: 'Xóa khỏi giỏ',
                        visualDensity: VisualDensity.compact,
                        onPressed: batTat ? onXoa : null,
                        icon: const Icon(Icons.delete_outline_rounded, size: 20, color: OcopColors.chuPhu),
                      ),
                    ],
                  ),
                  Text('${Formatting.tien(dong.gia)} / ${dong.donViTinh}', style: theme.textTheme.bodySmall),
                  if (canhBao != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(canhBao, style: theme.textTheme.bodySmall?.copyWith(color: OcopColors.doLoi)),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: OcopColors.nenNhap,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Giảm',
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              padding: EdgeInsets.zero,
                              onPressed: batTat && dong.soLuong > 1 ? () => onDoiSoLuong(dong.soLuong - 1) : null,
                              icon: const Icon(Icons.remove_rounded, size: 16),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text('${dong.soLuong}', style: const TextStyle(fontWeight: FontWeight.w700)),
                            ),
                            IconButton(
                              tooltip: 'Tăng',
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              padding: EdgeInsets.zero,
                              onPressed: batTat && dong.soLuong < 999 ? () => onDoiSoLuong(dong.soLuong + 1) : null,
                              icon: const Icon(Icons.add_rounded, size: 16),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        Formatting.tien(dong.thanhTien),
                        style: theme.textTheme.titleSmall?.copyWith(color: OcopColors.xanhOcop, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
