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
      MaterialPageRoute(builder: (_) => DatHangScreen(tamTinh: gio.tamTinh, repository: widget.repository)),
    );
    if (!mounted || don == null) return;
    thongBao(context, 'Đặt hàng thành công: đơn #${don.id}, tổng ${DinhDang.tien(don.tongTien)}.');
    await _tai(); // backend đã xóa giỏ sau khi đặt
    if (!mounted) return;
    // Chuyển sang xem đơn vừa đặt.
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
            ? const PreferredSize(preferredSize: Size.fromHeight(4), child: LinearProgressIndicator())
            : null,
      ),
      body: _noiDung(),
      bottomNavigationBar: coTheDat
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tạm tính'),
                          Text(DinhDang.tien(gio.tamTinh), style: Theme.of(context).textTheme.titleLarge),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      key: const Key('nutDatHang'),
                      onPressed: _dangCapNhat ? null : _datHang,
                      icon: const Icon(Icons.payment),
                      label: const Text('Đặt hàng'),
                    ),
                  ],
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
          SizedBox(height: 120),
          TrangTrong(icon: Icons.shopping_cart_outlined, thongDiep: 'Giỏ hàng trống. Hãy chọn vài đặc sản OCOP!'),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _tai,
      child: ListView.builder(
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
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnhMang(url: dong.anhUrl, width: 88, height: 104),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dong.ten, style: theme.textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text('${DinhDang.tien(dong.gia)} / ${dong.donViTinh}', style: theme.textTheme.bodySmall),
                  if (canhBao != null)
                    Text(canhBao, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Giảm',
                        visualDensity: VisualDensity.compact,
                        onPressed: batTat && dong.soLuong > 1 ? () => onDoiSoLuong(dong.soLuong - 1) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('${dong.soLuong}'),
                      IconButton(
                        tooltip: 'Tăng',
                        visualDensity: VisualDensity.compact,
                        onPressed: batTat && dong.soLuong < 999 ? () => onDoiSoLuong(dong.soLuong + 1) : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                      const Spacer(),
                      Text(DinhDang.tien(dong.thanhTien), style: theme.textTheme.titleSmall),
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            key: Key('xoa${dong.sanPhamId}'),
            tooltip: 'Xóa khỏi giỏ',
            onPressed: batTat ? onXoa : null,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}
