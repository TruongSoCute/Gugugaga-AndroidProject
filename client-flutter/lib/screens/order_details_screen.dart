import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/order_repository.dart';
import '../models/order.dart';
import '../utils/formatting.dart';
import '../widgets/network_image_view.dart';
import '../widgets/status_chip.dart';
import '../widgets/theme_widgets.dart';
import '../widgets/dialogs.dart';
import '../widgets/error_state.dart';
import 'review_screen.dart';
import 'batch_journey_screen.dart';

/// Chi tiết đơn (GET /don-hang/:id): các dòng kèm mã lô, lịch sử trạng thái.
class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key, required this.donHangId, this.repository});

  final int donHangId;
  final OrderRepository? repository;

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late final OrderRepository _repo = widget.repository ?? OrderRepository(ApiClient.macDinh);

  bool _dangTai = true;
  ApiException? _loi;
  Order? _don;
  bool _dangGui = false;
  bool _daDoi = false;

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
      final don = await _repo.chiTietDon(widget.donHangId);
      if (!mounted) return;
      setState(() {
        _don = don;
        _dangTai = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loi = e;
        _dangTai = false;
      });
    }
  }

  Future<void> _doiTrangThai(String trangThai) async {
    final huy = trangThai == OrderStatus.daHuy;
    final dongY = await xacNhan(
      context,
      tieuDe: huy ? 'Hủy đơn hàng' : 'Xác nhận đã nhận hàng',
      noiDung: huy
          ? 'Hủy đơn #${widget.donHangId}? Hàng sẽ được hoàn lại kho.'
          : 'Bạn đã nhận đủ hàng của đơn #${widget.donHangId}? Sau đó bạn có thể đánh giá sản phẩm.',
      nutDongY: huy ? 'Hủy đơn' : 'Đã nhận',
      nguyHiem: huy,
    );
    if (!dongY || !mounted) return;
    setState(() => _dangGui = true);
    try {
      final don = await _repo.doiTrangThai(widget.donHangId, trangThai,
          ghiChu: huy ? 'Khách hủy trên app' : 'Khách xác nhận đã nhận hàng');
      if (!mounted) return;
      setState(() {
        _don = don;
        _dangGui = false;
        _daDoi = true;
      });
      thongBao(context, huy ? 'Đã hủy đơn.' : 'Cảm ơn bạn! Hãy đánh giá sản phẩm đã mua.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _dangGui = false);
      thongBao(context, e.thongDiepDayDu);
    }
  }

  Future<void> _danhGia(OrderItem d) async {
    final daGui = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewScreen(donHangId: widget.donHangId, sanPhamId: d.sanPhamId, tenSanPham: d.tenSanPham),
      ),
    );
    if (!mounted || daGui != true) return;
    _daDoi = true;
    thongBao(context, 'Đã gửi đánh giá. Cảm ơn bạn!');
    await _tai();
  }

  void _xemLo(String ma) => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => BatchJourneyScreen(maTruyXuat: ma)),
      );

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (daPop, _) {
        if (!daPop) Navigator.pop(context, _daDoi);
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Đơn #${widget.donHangId}')),
        body: _noiDung(),
        bottomNavigationBar: _thanhNut(),
      ),
    );
  }

  Widget? _thanhNut() {
    final don = _don;
    if (don == null || _dangTai) return null;
    if (!don.duocHuy && !don.duocXacNhanNhan) return null;
    return Container(
      color: OcopColors.nenThe,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: don.duocHuy
              ? OutlinedButton.icon(
                  key: const Key('nutHuyDon'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: OcopColors.nenDoLoi,
                    foregroundColor: OcopColors.doLoi,
                  ),
                  onPressed: _dangGui ? null : () => _doiTrangThai(OrderStatus.daHuy),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Hủy đơn'),
                )
              : FilledButton.icon(
                  key: const Key('nutDaNhan'),
                  onPressed: _dangGui ? null : () => _doiTrangThai(OrderStatus.daNhan),
                  icon: const Icon(Icons.inventory_outlined),
                  label: const Text('Đã nhận hàng'),
                ),
        ),
      ),
    );
  }

  Widget _noiDung() {
    if (_dangTai) return const Center(child: CircularProgressIndicator());
    final loi = _loi;
    if (loi != null) {
      return ErrorState(
          thongDiep: loi.maHttp == 404 ? 'Không tìm thấy đơn hàng.' : loi.thongDiep, onThuLai: _tai);
    }
    final don = _don!;
    return RefreshIndicator(
      onRefresh: _tai,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Card(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                ListTile(
                  title: Text('Đặt lúc ${Formatting.thoiDiem(don.taoLuc)}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: StatusChip(nhan: OrderStatus.ten(don.trangThai), mau: StatusChip.mauCua(don.trangThai)),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.local_shipping_outlined, color: OcopColors.chuChinh),
                  title: Text('${don.tenNguoiNhan} · ${don.sdtNguoiNhan}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(don.diaChiGiao + (don.ghiChu == null ? '' : '\nGhi chú: ${don.ghiChu}')),
                ),
              ],
            ),
          ),
          const OcopSectionTitle('Sản phẩm'),
          for (final d in don.chiTiet) _dongSanPham(don, d),
          Card(
            margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _dongTien('Tiền hàng', don.tienHang),
                  const SizedBox(height: 6),
                  _dongTien('Phí giao', don.phiGiao),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider()),
                  _dongTien('Tổng cộng', don.tongTien, dam: true),
                ],
              ),
            ),
          ),
          const OcopSectionTitle('Lịch sử trạng thái'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (final ls in don.lichSu)
                  ListTile(
                    dense: true,
                    leading: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: StatusChip.mauCua(ls.trangThai), shape: BoxShape.circle),
                    ),
                    title: Text(OrderStatus.ten(ls.trangThai), style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text([
                      Formatting.thoiDiem(ls.thoiDiem),
                      if (ls.nguoiThucHien != null) ls.nguoiThucHien!,
                      if (ls.ghiChu != null) ls.ghiChu!,
                    ].join(' · ')),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dongSanPham(Order don, OrderItem d) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                    borderRadius: BorderRadius.circular(10), child: NetworkImageView(url: d.anhUrl, width: 60, height: 60)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.tenSanPham, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        '${d.soLuong} ${d.donViTinh} × ${Formatting.tien(d.donGia)} = ${Formatting.tien(d.thanhTien)}',
                        style: theme.textTheme.bodySmall?.copyWith(color: OcopColors.chuChinh, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (d.maTruyXuat != null)
                  ActionChip(
                    backgroundColor: OcopColors.xanhNhat,
                    avatar: const Icon(Icons.qr_code_2, size: 16, color: OcopColors.xanhOcop),
                    label: Text(
                      'Lô ${d.maTruyXuat}${d.vungNguyenLieu == null ? '' : ' · ${d.vungNguyenLieu}'}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: OcopColors.xanhOcop),
                    ),
                    onPressed: () => _xemLo(d.maTruyXuat!),
                  ),
                if (don.duocDanhGia)
                  d.daDanhGia
                      ? const Chip(
                          backgroundColor: OcopColors.nenNhap,
                          avatar: Icon(Icons.check_rounded, size: 16, color: OcopColors.xanhOcop),
                          label: Text('Đã đánh giá'),
                        )
                      : ActionChip(
                          key: Key('danhGia${d.sanPhamId}'),
                          backgroundColor: OcopColors.vangNhat,
                          avatar: const Icon(Icons.rate_review_outlined, size: 16, color: OcopColors.vangOcop),
                          label: const Text('Đánh giá',
                              style: TextStyle(color: OcopColors.vangChu, fontWeight: FontWeight.w700)),
                          onPressed: () => _danhGia(d),
                        ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dongTien(String nhan, int tien, {bool dam = false}) {
    final style = dam
        ? Theme.of(context).textTheme.titleMedium?.copyWith(color: OcopColors.xanhOcop, fontWeight: FontWeight.w800)
        : Theme.of(context).textTheme.bodyMedium;
    return Row(children: [Text(nhan, style: style), const Spacer(), Text(Formatting.tien(tien), style: style)]);
  }
}
