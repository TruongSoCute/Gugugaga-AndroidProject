import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/don_hang_repository.dart';
import '../data/phien_dang_nhap.dart';
import '../data/san_pham_repository.dart';
import '../data/tuong_tac_repository.dart';
import '../models/chung_nhan.dart';
import '../models/danh_gia.dart';
import '../models/san_pham.dart';
import '../utils/dinh_dang.dart';
import '../widgets/anh_mang.dart';
import '../widgets/hang_sao.dart';
import '../widgets/hop_thoai.dart';
import '../widgets/trang_thai_loi.dart';
import 'gio_hang_screen.dart';
import 'nha_cung_cap_screen.dart';
import 'phan_anh_screen.dart';
import 'yeu_cau_dang_nhap.dart';

/// Chi tiết sản phẩm (GET /san-pham/:id) và đánh giá kèm ảnh (GET /danh-gia?sanPhamId=).
/// Xem không cần đăng nhập. Thêm vào giỏ, yêu thích, phản ánh thì cần đăng nhập khách:
/// app mở màn hình đăng nhập, nhận kết quả rồi làm tiếp.
class ChiTietSanPhamScreen extends StatefulWidget {
  const ChiTietSanPhamScreen({
    super.key,
    required this.sanPhamId,
    this.sanPhamRepository,
    this.donHangRepository,
    this.tuongTacRepository,
  });

  final int sanPhamId;
  final SanPhamRepository? sanPhamRepository;
  final DonHangRepository? donHangRepository;
  final TuongTacRepository? tuongTacRepository;

  @override
  State<ChiTietSanPhamScreen> createState() => _ChiTietSanPhamScreenState();
}

class _ChiTietSanPhamScreenState extends State<ChiTietSanPhamScreen> {
  late final SanPhamRepository _spRepo = widget.sanPhamRepository ?? SanPhamRepository(ApiClient.macDinh);
  late final DonHangRepository _donRepo = widget.donHangRepository ?? DonHangRepository(ApiClient.macDinh);
  late final TuongTacRepository _ttRepo = widget.tuongTacRepository ?? TuongTacRepository(ApiClient.macDinh);

  bool _dangTai = true;
  ApiException? _loi;
  ChiTietSanPham? _ct;
  TrangDanhGia? _danhGia;
  bool _yeuThich = false;
  int _soLuong = 1;
  bool _dangThem = false;

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
      final ct = await _spRepo.chiTiet(widget.sanPhamId);
      final dg = await _spRepo.dsDanhGia(widget.sanPhamId);
      if (!mounted) return;
      setState(() {
        _ct = ct;
        _danhGia = dg;
        _dangTai = false;
      });
      await _taiYeuThich();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loi = e;
        _dangTai = false;
      });
    }
  }

  /// Backend không trả cờ "đã yêu thích" trong chi tiết, nên khách đã đăng nhập đọc danh sách yêu thích.
  Future<void> _taiYeuThich() async {
    if (!PhienDangNhap.laKhach) return;
    try {
      final ds = await _ttRepo.dsYeuThich();
      if (!mounted) return;
      setState(() => _yeuThich = ds.any((sp) => sp.id == widget.sanPhamId));
    } on ApiException {
      // Không đọc được thì để nút ở trạng thái chưa yêu thích.
    }
  }

  Future<void> _doiYeuThich() async {
    if (!await canKhach(context, lyDo: 'Đăng nhập để lưu sản phẩm yêu thích.')) return;
    if (!mounted) return;
    final moi = !_yeuThich;
    try {
      if (moi) {
        await _ttRepo.yeuThich(widget.sanPhamId);
      } else {
        await _ttRepo.boYeuThich(widget.sanPhamId);
      }
      if (!mounted) return;
      setState(() => _yeuThich = moi);
      thongBao(context, moi ? 'Đã thêm vào yêu thích.' : 'Đã bỏ yêu thích.');
    } on ApiException catch (e) {
      if (!mounted) return;
      thongBao(context, e.thongDiepDayDu);
    }
  }

  Future<void> _themVaoGio() async {
    if (!await canKhach(context, lyDo: 'Đăng nhập để thêm sản phẩm vào giỏ.')) return;
    if (!mounted) return;
    setState(() => _dangThem = true);
    try {
      final gio = await _donRepo.themVaoGio(widget.sanPhamId, _soLuong);
      if (!mounted) return;
      setState(() => _dangThem = false);
      thongBao(
        context,
        'Đã thêm vào giỏ (trong giỏ: ${gio.soLuongCua(widget.sanPhamId)}).',
        action: SnackBarAction(
          label: 'Xem giỏ',
          onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const GioHangScreen())),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _dangThem = false);
      thongBao(context, e.thongDiepDayDu);
    }
  }

  Future<void> _phanAnh() async {
    final sp = _ct!.sanPham;
    if (!await canKhach(context, lyDo: 'Đăng nhập để gửi phản ánh.')) return;
    if (!mounted) return;
    final daGui = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PhanAnhScreen(sanPhamId: sp.id, tenSanPham: sp.ten)),
    );
    if (!mounted) return;
    if (daGui == true) thongBao(context, 'Đã gửi phản ánh. Quản trị viên sẽ xem xét.');
  }

  @override
  Widget build(BuildContext context) {
    final laNcc = PhienDangNhap.laNhaCungCap;
    final coDuLieu = _ct != null && !_dangTai;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết sản phẩm'),
        actions: [
          if (coDuLieu && !laNcc) ...[
            IconButton(
              key: const Key('nutYeuThich'),
              tooltip: _yeuThich ? 'Bỏ yêu thích' : 'Yêu thích',
              icon: Icon(_yeuThich ? Icons.favorite : Icons.favorite_border, color: _yeuThich ? Colors.red : null),
              onPressed: _doiYeuThich,
            ),
            IconButton(tooltip: 'Báo hàng giả / sai mô tả', icon: const Icon(Icons.flag_outlined), onPressed: _phanAnh),
          ],
        ],
      ),
      body: _noiDung(),
      bottomNavigationBar: coDuLieu && !laNcc ? _thanhMua() : null,
    );
  }

  Widget _thanhMua() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            IconButton.outlined(
              tooltip: 'Giảm',
              onPressed: _soLuong > 1 ? () => setState(() => _soLuong--) : null,
              icon: const Icon(Icons.remove),
            ),
            SizedBox(width: 40, child: Text('$_soLuong', textAlign: TextAlign.center)),
            IconButton.outlined(
              tooltip: 'Tăng',
              onPressed: _soLuong < 999 ? () => setState(() => _soLuong++) : null,
              icon: const Icon(Icons.add),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                key: const Key('nutThemVaoGio'),
                onPressed: _dangThem ? null : _themVaoGio,
                icon: _dangThem
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add_shopping_cart),
                label: const Text('Thêm vào giỏ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noiDung() {
    if (_dangTai) return const Center(child: CircularProgressIndicator());
    final loi = _loi;
    if (loi != null) {
      return TrangThaiLoi(
        thongDiep: loi.maHttp == 404 ? 'Sản phẩm không tồn tại hoặc đã ngừng bán.' : loi.thongDiep,
        onThuLai: _tai,
      );
    }
    final ct = _ct!;
    final dsDanhGia = _danhGia?.duLieu ?? ct.danhGiaGanDay;
    // Phần đầu (thông tin sản phẩm) + từng đánh giá: ListView.builder, phần tử 0 là phần đầu.
    return RefreshIndicator(
      onRefresh: _tai,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: dsDanhGia.length + 1,
        itemBuilder: (context, i) => i == 0
            ? _ThongTinSanPham(ct: ct, danhGia: _danhGia)
            : _DongDanhGia(dg: dsDanhGia[i - 1]),
      ),
    );
  }
}

class _ThongTinSanPham extends StatelessWidget {
  const _ThongTinSanPham({required this.ct, required this.danhGia});

  final ChiTietSanPham ct;
  final TrangDanhGia? danhGia;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sp = ct.sanPham;
    final soDanhGia = danhGia?.soDanhGia ?? sp.soDanhGia;
    final diem = danhGia?.diemTrungBinh ?? sp.diemTrungBinh;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnhMang(url: sp.anhUrl, height: 240, width: double.infinity),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sp.ten, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(DinhDang.tien(sp.gia) + (sp.donViTinh.isEmpty ? '' : ' / ${sp.donViTinh}'),
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
              const SizedBox(height: 4),
              if (sp.hangSao != null) HangSao(soSao: sp.hangSao!, coChu: 'OCOP ${sp.hangSao} sao'),
              if (sp.moTa != null && sp.moTa!.isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 12), child: Text(sp.moTa!)),
            ],
          ),
        ),
        const Divider(height: 1),
        ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AnhMang(url: ct.anhCoSoUrl, width: 56, height: 56),
          ),
          title: Text(sp.tenNhaCungCap),
          subtitle: Text([sp.tenVung, ct.diaChiNhaCungCap].whereType<String>().where((s) => s.isNotEmpty).join(' · ')),
          trailing: const Icon(Icons.chevron_right),
          onTap: sp.nhaCungCapId == null
              ? null
              : () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => NhaCungCapScreen(nhaCungCapId: sp.nhaCungCapId!)),
                  ),
        ),
        if (ct.chungNhan.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DsChungNhan(chungNhan: ct.chungNhan),
          ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              Text('Đánh giá ($soDanhGia)', style: theme.textTheme.titleMedium),
              const Spacer(),
              if (diem != null) HangSao(soSao: diem.round(), coChu: diem.toStringAsFixed(1)),
            ],
          ),
        ),
        if (soDanhGia == 0)
          const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Chưa có đánh giá.')),
      ],
    );
  }
}

/// Các chứng nhận dạng chip; chạm để xem ảnh giấy chứng nhận. Dùng lại ở trang nhà cung cấp.
class DsChungNhan extends StatelessWidget {
  const DsChungNhan({super.key, required this.chungNhan});

  final List<ChungNhan> chungNhan;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final cn in chungNhan)
          ActionChip(
            avatar: Icon(cn.conHieuLuc ? Icons.verified : Icons.error_outline,
                size: 18, color: cn.conHieuLuc ? Colors.green : Colors.red),
            label: Text('${cn.loai} ${cn.soHieu}${cn.conHieuLuc ? '' : ' (hết hạn)'}'),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('${cn.loai} · ${cn.soHieu}'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (cn.ngayCap != null) Text('Ngày cấp: ${DinhDang.ngay(cn.ngayCap!)}'),
                    Text('Hết hạn: ${cn.ngayHetHan == null ? 'không ghi' : DinhDang.ngay(cn.ngayHetHan!)}'),
                    Text(cn.conHieuLuc ? 'Còn hiệu lực' : 'Đã hết hiệu lực'),
                    if (cn.anhUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: AnhMang(url: cn.anhUrl, height: 260, width: double.infinity),
                      ),
                  ],
                ),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng'))],
              ),
            ),
          ),
      ],
    );
  }
}

class _DongDanhGia extends StatelessWidget {
  const _DongDanhGia({required this.dg});

  final DanhGia dg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(dg.tenNguoiDanhGia, style: theme.textTheme.titleSmall)),
              Text(DinhDang.thoiDiem(dg.taoLuc), style: theme.textTheme.bodySmall),
            ],
          ),
          HangSao(soSao: dg.soSao, kichThuoc: 14),
          if (dg.noiDung != null && dg.noiDung!.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 4), child: Text(dg.noiDung!)),
          if (dg.anh.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: dg.anh.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AnhMang(url: dg.anh[i], width: 80, height: 80),
                  ),
                ),
              ),
            ),
          const Divider(),
        ],
      ),
    );
  }
}
