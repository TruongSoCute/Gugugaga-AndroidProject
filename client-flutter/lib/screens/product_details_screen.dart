import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/api_client.dart';
import '../data/order_repository.dart';
import '../data/auth_session.dart';
import '../data/product_repository.dart';
import '../data/customer_interactions_repository.dart';
import '../models/certificate.dart';
import '../models/review.dart';
import '../models/product.dart';
import '../utils/formatting.dart';
import '../widgets/network_image_view.dart';
import '../widgets/animations.dart';
import '../widgets/theme_widgets.dart';
import '../widgets/star_rating.dart';
import '../widgets/dialogs.dart';
import '../widgets/error_state.dart';
import 'cart_screen.dart';
import 'suppliers_screen.dart';
import 'issue_report_screen.dart';
import 'require_login.dart';

/// Chi tiết sản phẩm (GET /san-pham/:id) và đánh giá kèm ảnh (GET /danh-gia?sanPhamId=).
class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({
    super.key,
    required this.sanPhamId,
    this.sanPhamRepository,
    this.donHangRepository,
    this.tuongTacRepository,
  });

  final int sanPhamId;
  final ProductRepository? sanPhamRepository;
  final OrderRepository? donHangRepository;
  final CustomerInteractionsRepository? tuongTacRepository;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late final ProductRepository _spRepo = widget.sanPhamRepository ?? ProductRepository(ApiClient.macDinh);
  late final OrderRepository _donRepo = widget.donHangRepository ?? OrderRepository(ApiClient.macDinh);
  late final CustomerInteractionsRepository _ttRepo = widget.tuongTacRepository ?? CustomerInteractionsRepository(ApiClient.macDinh);

  bool _dangTai = true;
  ApiException? _loi;
  ProductDetails? _ct;
  ReviewPage? _danhGia;
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

  Future<void> _taiYeuThich() async {
    if (!AuthSession.laKhach) return;
    try {
      final ds = await _ttRepo.dsYeuThich();
      if (!mounted) return;
      setState(() => _yeuThich = ds.any((sp) => sp.id == widget.sanPhamId));
    } on ApiException {
      // Bỏ qua.
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
          onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const CartScreen())),
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
      MaterialPageRoute(builder: (_) => IssueReportScreen(sanPhamId: sp.id, tenSanPham: sp.ten)),
    );
    if (!mounted) return;
    if (daGui == true) thongBao(context, 'Đã gửi phản ánh. Quản trị viên sẽ xem xét.');
  }

  @override
  Widget build(BuildContext context) {
    final laNcc = AuthSession.laNhaCungCap;
    final coDuLieu = _ct != null && !_dangTai;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết'),
        actions: [
          if (coDuLieu && !laNcc) ...[
            IconButton(
              key: const Key('nutYeuThich'),
              tooltip: _yeuThich ? 'Bỏ yêu thích' : 'Yêu thích',
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: Icon(
                  _yeuThich ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  key: ValueKey<bool>(_yeuThich),
                  color: _yeuThich ? OcopColors.doLoi : null,
                ),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                _doiYeuThich();
              },
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
    return Container(
      color: OcopColors.nenThe,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(color: OcopColors.nenNhap, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Giảm',
                      visualDensity: VisualDensity.compact,
                      onPressed: _soLuong > 1
                          ? () {
                              HapticFeedback.selectionClick();
                              setState(() => _soLuong--);
                            }
                          : null,
                      icon: const Icon(Icons.remove_rounded, size: 18),
                    ),
                    SizedBox(
                      width: 28,
                      child: AnimatedNumber(
                        giaTri: _soLuong,
                        text: '$_soLuong',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tăng',
                      visualDensity: VisualDensity.compact,
                      onPressed: _soLuong < 999
                          ? () {
                              HapticFeedback.selectionClick();
                              setState(() => _soLuong++);
                            }
                          : null,
                      icon: const Icon(Icons.add_rounded, size: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PressFeedback(
                  rungNhe: true,
                  child: FilledButton(
                    key: const Key('nutThemVaoGio'),
                    onPressed: _dangThem ? null : _themVaoGio,
                    child: _dangThem
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Thêm vào giỏ'),
                  ),
                ),
              ),
            ],
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
        thongDiep: loi.maHttp == 404 ? 'Sản phẩm không tồn tại hoặc đã ngừng bán.' : loi.thongDiep,
        onThuLai: _tai,
      );
    }
    final ct = _ct!;
    final dsDanhGia = _danhGia?.duLieu ?? ct.danhGiaGanDay;
    return RefreshIndicator(
      onRefresh: _tai,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: dsDanhGia.length + 1,
        itemBuilder: (context, i) => i == 0
            ? _ProductInfo(ct: ct, danhGia: _danhGia)
            : _ReviewRow(dg: dsDanhGia[i - 1]),
      ),
    );
  }
}

class _ProductInfo extends StatelessWidget {
  const _ProductInfo({required this.ct, required this.danhGia});

  final ProductDetails ct;
  final ReviewPage? danhGia;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sp = ct.sanPham;
    final soDanhGia = danhGia?.soDanhGia ?? sp.soDanhGia;
    final diem = danhGia?.diemTrungBinh ?? sp.diemTrungBinh;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Hero(
            tag: 'anh-sp-${sp.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: NetworkImageView(url: sp.anhUrl, height: 248, width: double.infinity),
            ),
          ),
        ),
        FadeIn(
          thuTu: 1,
          child: Card(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sp.ten, style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      Formatting.tien(sp.gia),
                      style: theme.textTheme.headlineSmall?.copyWith(color: OcopColors.chuChinh, fontWeight: FontWeight.w800),
                    ),
                    if (sp.donViTinh.isNotEmpty)
                      Text(' / ${sp.donViTinh}', style: theme.textTheme.bodyMedium?.copyWith(color: OcopColors.chuPhu)),
                    const Spacer(),
                    if (sp.hangSao != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: OcopColors.vangNhat,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 15, color: OcopColors.vangOcop),
                            const SizedBox(width: 3),
                            Text(
                              '${sp.hangSao} sao',
                              style: const TextStyle(
                                color: OcopColors.vangChu,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (sp.moTa != null && sp.moTa!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(sp.moTa!, style: theme.textTheme.bodyMedium?.copyWith(color: OcopColors.chuPhu, height: 1.45)),
                ],
              ],
            ),
          ),
        ),
        ),
        FadeIn(
          thuTu: 2,
          child: Card(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.fromLTRB(14, 6, 12, 6),
                leading: ct.anhCoSoUrl != null && ct.anhCoSoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          color: OcopColors.nenNhap,
                          child: NetworkImageView(url: ct.anhCoSoUrl, width: 48, height: 48),
                        ),
                      )
                    : Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: OcopColors.xanhNhat,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.storefront_rounded, color: OcopColors.xanhOcop, size: 22),
                      ),
                title: Text(sp.tenNhaCungCap, style: theme.textTheme.titleSmall),
                subtitle: Text(
                  [sp.tenVung, ct.diaChiNhaCungCap].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: OcopColors.chuPhu),
                onTap: sp.nhaCungCapId == null
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(builder: (_) => SuppliersScreen(nhaCungCapId: sp.nhaCungCapId!)),
                        ),
              ),
              if (ct.chungNhan.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: CertificateList(chungNhan: ct.chungNhan),
                ),
            ],
          ),
        ),
        ),
        OcopSectionTitle(
          'Đánh giá ($soDanhGia)',
          phu: diem != null
              ? StarRating(soSao: diem.round(), coChu: diem.toStringAsFixed(1))
              : (soDanhGia == 0
                  ? Text('Chưa có đánh giá', style: theme.textTheme.bodySmall)
                  : null),
        ),
      ],
    );
  }
}

/// Các chứng nhận dạng tag gọn gàng xếp ngang nhiều thẻ trên 1 hàng; chạm để xem chi tiết.
class CertificateList extends StatelessWidget {
  const CertificateList({super.key, required this.chungNhan});

  final List<Certificate> chungNhan;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final cn in chungNhan)
          Material(
            color: cn.conHieuLuc ? OcopColors.xanhNhat : OcopColors.nenDoLoi,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('${cn.loai} · ${cn.soHieu}'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (cn.ngayCap != null) Text('Ngày cấp: ${Formatting.ngay(cn.ngayCap!)}'),
                      Text('Hết hạn: ${cn.ngayHetHan == null ? 'không ghi' : Formatting.ngay(cn.ngayHetHan!)}'),
                      Text(cn.conHieuLuc ? 'Còn hiệu lực' : 'Đã hết hiệu lực'),
                      if (cn.anhUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: NetworkImageView(url: cn.anhUrl, height: 240, width: double.infinity),
                          ),
                        ),
                    ],
                  ),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng'))],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cn.conHieuLuc ? Icons.verified_rounded : Icons.error_outline_rounded,
                      size: 14,
                      color: cn.conHieuLuc ? OcopColors.xanhOcop : OcopColors.doLoi,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${cn.loai} ${cn.soHieu}${cn.conHieuLuc ? '' : ' (hết hạn)'}',
                      style: TextStyle(
                        color: cn.conHieuLuc ? OcopColors.xanhOcop : OcopColors.doLoi,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.dg});

  final Review dg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chuDau = dg.tenNguoiDanhGia.isEmpty ? '?' : dg.tenNguoiDanhGia.characters.first.toUpperCase();
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: OcopColors.nenNhap,
                  foregroundColor: OcopColors.chuChinh,
                  child: Text(chuDau, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dg.tenNguoiDanhGia, style: theme.textTheme.titleSmall),
                      Text(Formatting.thoiDiem(dg.taoLuc), style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                StarRating(soSao: dg.soSao, kichThuoc: 14),
              ],
            ),
            if (dg.noiDung != null && dg.noiDung!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(dg.noiDung!, style: theme.textTheme.bodyMedium?.copyWith(height: 1.45)),
              ),
            if (dg.anh.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: dg.anh.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: NetworkImageView(url: dg.anh[i], width: 80, height: 80),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
