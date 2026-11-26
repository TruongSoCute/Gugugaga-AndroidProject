import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/don_hang_repository.dart';
import '../models/don_hang.dart';
import '../models/gio_hang.dart';
import '../utils/dinh_dang.dart';
import '../widgets/anh_mang.dart';
import '../widgets/chuyen_dong.dart';
import '../widgets/giao_dien.dart';
import '../widgets/hop_thoai.dart';
import '../widgets/trang_thai_loi.dart';
import '../widgets/trang_trong.dart';
import 'chi_tiet_don_screen.dart';
import 'dat_hang_screen.dart';

/// Giỏ hàng của khách (GET /gio-hang). Sửa số lượng bằng PUT, xóa dòng có hộp thoại xác nhận
/// và SnackBar "Hoàn tác" (Hoàn tác = PUT lại số lượng cũ) — yêu cầu C.2 #6.
class GioHangScreen extends StatefulWidget {
  const GioHangScreen({super.key, this.repository});

  final DonHangRepository? repository;

  @override
  State<GioHangScreen> createState() => _GioHangScreenState();
}

class _GioHangScreenState extends State<GioHangScreen> {
  late final DonHangRepository _repo = widget.repository ?? DonHangRepository(ApiClient.macDinh);

  bool _dangTai = true;
  String? _loi;
  GioHang? _gio;
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

  Future<void> _doiSoLuong(DongGio d, int soLuong) async {
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

  Future<void> _xoa(DongGio d) async {
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

  Future<void> _hoanTac(DongGio d) async {
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
    final don = await Navigator.push<DonHang>(
      context,
      MaterialPageRoute(builder: (_) => DatHangScreen(tamTinh: gio.tamTinh, repository: widget.repository)),
    );
    if (!mounted || don == null) return;
    thongBao(context, 'Đặt hàng thành công: đơn #${don.id}, tổng ${DinhDang.tien(don.tongTien)}.');
    await _tai();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => ChiTietDonScreen(donHangId: don.id, repository: widget.repository)),
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
              color: OcopMau.nenThe,
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
                            SoChayMuot(
                              giaTri: gio.tamTinh,
                              text: DinhDang.tien(gio.tamTinh),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(color: OcopMau.chuChinh, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      NhanNhe(
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
    if (_loi != null) return TrangThaiLoi(thongDiep: _loi!, onThuLai: _tai);
    final ds = _gio?.duLieu ?? const <DongGio>[];
    if (ds.isEmpty) {
      return RefreshIndicator(
        onRefresh: _tai,
        child: ListView(children: const [
          SizedBox(height: 100),
          TrangTrong(icon: Icons.shopping_cart_outlined, thongDiep: 'Giỏ hàng trống. Hãy chọn vài đặc sản OCOP!'),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _tai,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        itemCount: ds.length,
        itemBuilder: (context, i) => _DongGioHang(
          dong: ds[i],
          batTat: !_dangCapNhat,
          onDoiSoLuong: (sl) => _doiSoLuong(ds[i], sl),
          onXoa: () => _xoa(ds[i]),
        ),
      ),
    );
  }
}

class _DongGioHang extends StatelessWidget {
  const _DongGioHang({required this.dong, required this.batTat, required this.onDoiSoLuong, required this.onXoa});

  final DongGio dong;
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
              child: AnhMang(url: dong.anhUrl, width: 88, height: 96),
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
                        icon: const Icon(Icons.delete_outline_rounded, size: 20, color: OcopMau.chuPhu),
                      ),
                    ],
                  ),
                  Text('${DinhDang.tien(dong.gia)} / ${dong.donViTinh}', style: theme.textTheme.bodySmall),
                  if (canhBao != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(canhBao, style: theme.textTheme.bodySmall?.copyWith(color: OcopMau.doLoi)),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: OcopMau.nenNhap,
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
                        DinhDang.tien(dong.thanhTien),
                        style: theme.textTheme.titleSmall?.copyWith(color: OcopMau.xanhOcop, fontWeight: FontWeight.w800),
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
