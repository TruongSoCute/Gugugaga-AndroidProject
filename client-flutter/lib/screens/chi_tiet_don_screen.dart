import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/don_hang_repository.dart';
import '../models/don_hang.dart';
import '../utils/dinh_dang.dart';
import '../widgets/anh_mang.dart';
import '../widgets/chip_trang_thai.dart';
import '../widgets/hop_thoai.dart';
import '../widgets/trang_thai_loi.dart';
import 'danh_gia_screen.dart';
import 'hanh_trinh_screen.dart';

/// Chi tiết đơn (GET /don-hang/:id): các dòng kèm mã lô (chạm để xem hành trình của đúng lô
/// trong đơn), lịch sử trạng thái. Khách được:
/// - Hủy đơn khi còn CHO_XAC_NHAN (có xác nhận);
/// - Xác nhận "Đã nhận hàng" khi đơn DA_GIAO;
/// - Đánh giá từng sản phẩm chưa đánh giá khi đơn DA_NHAN.
/// Khi rời màn hình, pop trả `true` nếu đơn đã đổi để danh sách tải lại.
class ChiTietDonScreen extends StatefulWidget {
  const ChiTietDonScreen({super.key, required this.donHangId, this.repository});

  final int donHangId;
  final DonHangRepository? repository;

  @override
  State<ChiTietDonScreen> createState() => _ChiTietDonScreenState();
}

class _ChiTietDonScreenState extends State<ChiTietDonScreen> {
  late final DonHangRepository _repo = widget.repository ?? DonHangRepository(ApiClient.macDinh);

  bool _dangTai = true;
  ApiException? _loi;
  DonHang? _don;
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
    final huy = trangThai == TrangThaiDon.daHuy;
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

  Future<void> _danhGia(DongDon d) async {
    final daGui = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DanhGiaScreen(donHangId: widget.donHangId, sanPhamId: d.sanPhamId, tenSanPham: d.tenSanPham),
      ),
    );
    if (!mounted || daGui != true) return;
    _daDoi = true;
    thongBao(context, 'Đã gửi đánh giá. Cảm ơn bạn!');
    await _tai();
  }

  void _xemLo(String ma) => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => HanhTrinhScreen(maTruyXuat: ma)),
      );

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (daPop, _) {
        if (!daPop) Navigator.pop(context, _daDoi); // trả kết quả cho danh sách đơn
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: don.duocHuy
            ? OutlinedButton.icon(
                key: const Key('nutHuyDon'),
                onPressed: _dangGui ? null : () => _doiTrangThai(TrangThaiDon.daHuy),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Hủy đơn'),
              )
            : FilledButton.icon(
                key: const Key('nutDaNhan'),
                onPressed: _dangGui ? null : () => _doiTrangThai(TrangThaiDon.daNhan),
                icon: const Icon(Icons.inventory_outlined),
                label: const Text('Đã nhận hàng'),
              ),
      ),
    );
  }

  Widget _noiDung() {
    if (_dangTai) return const Center(child: CircularProgressIndicator());
    final loi = _loi;
    if (loi != null) {
      return TrangThaiLoi(
          thongDiep: loi.maHttp == 404 ? 'Không tìm thấy đơn hàng.' : loi.thongDiep, onThuLai: _tai);
    }
    final don = _don!;
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: _tai,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ListTile(
            title: Text('Đặt lúc ${DinhDang.thoiDiem(don.taoLuc)}'),
            trailing: ChipTrangThai(nhan: TrangThaiDon.ten(don.trangThai), mau: ChipTrangThai.mauCua(don.trangThai)),
          ),
          ListTile(
            leading: const Icon(Icons.local_shipping_outlined),
            title: Text('${don.tenNguoiNhan} · ${don.sdtNguoiNhan}'),
            subtitle: Text(don.diaChiGiao + (don.ghiChu == null ? '' : '\nGhi chú: ${don.ghiChu}')),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text('Sản phẩm', style: theme.textTheme.titleMedium),
          ),
          for (final d in don.chiTiet) _dongSanPham(don, d),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _dongTien('Tiền hàng', don.tienHang),
                _dongTien('Phí giao', don.phiGiao),
                const Divider(),
                _dongTien('Tổng cộng', don.tongTien, dam: true),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text('Lịch sử trạng thái', style: theme.textTheme.titleMedium),
          ),
          for (final ls in don.lichSu)
            ListTile(
              dense: true,
              leading: Icon(Icons.circle, size: 12, color: ChipTrangThai.mauCua(ls.trangThai)),
              title: Text(TrangThaiDon.ten(ls.trangThai)),
              subtitle: Text([
                DinhDang.thoiDiem(ls.thoiDiem),
                if (ls.nguoiThucHien != null) ls.nguoiThucHien!,
                if (ls.ghiChu != null) ls.ghiChu!,
              ].join(' · ')),
            ),
        ],
      ),
    );
  }

  Widget _dongSanPham(DonHang don, DongDon d) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                    borderRadius: BorderRadius.circular(8), child: AnhMang(url: d.anhUrl, width: 56, height: 56)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.tenSanPham, style: theme.textTheme.titleSmall),
                      Text('${d.soLuong} ${d.donViTinh} × ${DinhDang.tien(d.donGia)} = ${DinhDang.tien(d.thanhTien)}'),
                    ],
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: [
                if (d.maTruyXuat != null)
                  // Mã lô thật đã giao cho khách: chạm để xem hành trình đúng lô đó.
                  ActionChip(
                    avatar: const Icon(Icons.qr_code_2, size: 18),
                    label: Text('Lô ${d.maTruyXuat}${d.vungNguyenLieu == null ? '' : ' · ${d.vungNguyenLieu}'}'),
                    onPressed: () => _xemLo(d.maTruyXuat!),
                  ),
                if (don.duocDanhGia)
                  d.daDanhGia
                      ? const Chip(avatar: Icon(Icons.check, size: 18), label: Text('Đã đánh giá'))
                      : ActionChip(
                          key: Key('danhGia${d.sanPhamId}'),
                          avatar: const Icon(Icons.rate_review_outlined, size: 18),
                          label: const Text('Đánh giá'),
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
    final style = dam ? Theme.of(context).textTheme.titleMedium : null;
    return Row(children: [Text(nhan, style: style), const Spacer(), Text(DinhDang.tien(tien), style: style)]);
  }
}
