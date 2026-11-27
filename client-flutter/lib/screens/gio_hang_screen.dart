
import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/don_hang_repository.dart';
import '../models/don_hang.dart';
import '../models/gio_hang.dart';
import '../utils/dinh_dang.dart';
import '../widgets/anh_mang.dart';
import '../widgets/hop_thoai.dart';
import '../widgets/trang_thai_loi.dart';
import '../widgets/trang_trong.dart';
import 'chi_tiet_don_screen.dart';
import 'dat_hang_screen.dart';

/// Giỏ hàng của khách (GET /gio-hang). Sửa số lượng bằng PUT, xóa dòng có hộp thoại xác nhận
/// và SnackBar "Hoàn tác" (Hoàn tác = PUT lại số lượng cũ) — yêu cầu C.2 #6.
/// Đặt hàng mở DatHangScreen và CHỜ KẾT QUẢ là đơn vừa tạo (Navigator trả kết quả).
class GioHangScreen extends StatefulWidget {
  const GioHangScreen({super.key, this.repository});

  final DonHangRepository? repository;

  @override
  State<GioHangScreen> createState() => _GioHangScreenState();
}

class _GioHangScreenState extends State<GioHangScreen> {
  late final DonHangRepository _repo =
      widget.repository ?? DonHangRepository(ApiClient.macDinh);

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
    final dongY = await xacNhan(
      context,
      tieuDe: 'Xóa khỏi giỏ',
      noiDung: 'Xóa "${d.ten}" khỏi giỏ hàng?',
      nutDongY: 'Xóa',
      nguyHiem: true,
    );
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
        action: SnackBarAction(
          label: 'Hoàn tác',
          onPressed: () => _hoanTac(d),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _dangCapNhat = false);
      thongBao(context, e.thongDiepDayDu);
    }
  }

  /// Hoàn tác xóa: đặt lại đúng số lượng cũ.
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
      MaterialPageRoute(
        builder: (_) => DatHangScreen(
          tamTinh: gio.tamTinh,
          repository: widget.repository,
        ),
      ),
    );
    if (!mounted || don == null) return;
    thongBao(
      context,
      'Đặt hàng thành công: đơn #${don.id}, tổng ${DinhDang.tien(don.tongTien)}.',
    );
    await _tai();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChiTietDonScreen(
          donHangId: don.id,
          repository: widget.repository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gio = _gio;
    final theme = Theme.of(context);
    final mauNen = theme.colorScheme.surface;
    final coTheDat = gio != null &&
        !gio.trong &&
        gio.tamTinh > 0 &&
        !_dangTai;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text(
          'Giỏ hàng',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        bottom: _dangCapNhat
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: _noiDung(),
      bottomNavigationBar: coTheDat
          ? Material(
              color: mauNen,
              elevation: 12,
              child: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tạm tính',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DinhDang.tien(gio.tamTinh),
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 50,
                        child: FilledButton.icon(
                          key: const Key('nutDatHang'),
                          onPressed:
                              _dangCapNhat ? null : _datHang,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.shopping_bag_outlined),
                          label: const Text(
                            'Đặt hàng',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
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
    if (_dangTai) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loi != null) {
      return TrangThaiLoi(
        thongDiep: _loi!,
        onThuLai: _tai,
      );
    }

    final ds = _gio?.duLieu ?? const <DongGio>[];

    if (ds.isEmpty) {
      return RefreshIndicator(
        onRefresh: _tai,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            TrangTrong(
              icon: Icons.shopping_cart_outlined,
              thongDiep: 'Giỏ hàng trống. Hãy chọn vài đặc sản OCOP!',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _tai,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 20),
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
  const _DongGioHang({
    required this.dong,
    required this.batTat,
    required this.onDoiSoLuong,
    required this.onXoa,
  });

  final DongGio dong;
  final bool batTat;
  final ValueChanged<int> onDoiSoLuong;
  final VoidCallback onXoa;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mauNen = theme.colorScheme.surface;
    final mauChu = theme.colorScheme.onSurface;

    final canhBao = !dong.dangBan
        ? 'Sản phẩm đã ngừng bán'
        : (dong.conHang < dong.soLuong
            ? 'Chỉ còn ${dong.conHang} ${dong.donViTinh}'
            : null);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      color: mauNen,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AnhMang(
                url: dong.anhUrl,
                width: 104,
                height: 112,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 112,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            dong.ten,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                              color: mauChu,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(
                          width: 34,
                          height: 34,
                          child: IconButton(
                            key: Key('xoa${dong.sanPhamId}'),
                            tooltip: 'Xóa khỏi giỏ',
                            onPressed: batTat ? onXoa : null,
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${DinhDang.tien(dong.gia)} / ${dong.donViTinh}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (canhBao != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        canhBao,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        _NutSoLuong(
                          icon: Icons.remove,
                          tooltip: 'Giảm',
                          batTat: batTat && dong.soLuong > 1,
                          onPressed: () =>
                              onDoiSoLuong(dong.soLuong - 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '${dong.soLuong}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _NutSoLuong(
                          icon: Icons.add,
                          tooltip: 'Tăng',
                          batTat: batTat && dong.soLuong < 999,
                          onPressed: () =>
                              onDoiSoLuong(dong.soLuong + 1),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            DinhDang.tien(dong.thanhTien),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutSoLuong extends StatelessWidget {
  const _NutSoLuong({
    required this.icon,
    required this.tooltip,
    required this.batTat,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool batTat;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton(
        tooltip: tooltip,
        onPressed: batTat ? onPressed : null,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: theme.colorScheme.primaryContainer
              .withValues(alpha: batTat ? 0.65 : 0.25),
          foregroundColor: theme.colorScheme.primary,
          disabledForegroundColor:
              theme.colorScheme.onSurface.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(icon, size: 19),
      ),
    );
  }
}
