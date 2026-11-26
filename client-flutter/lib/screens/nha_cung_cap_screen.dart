import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/phien_dang_nhap.dart';
import '../data/san_pham_repository.dart';
import '../data/tuong_tac_repository.dart';
import '../models/nha_cung_cap.dart';
import '../utils/dinh_dang.dart';
import '../widgets/anh_mang.dart';
import '../widgets/giao_dien.dart';
import '../widgets/hop_thoai.dart';
import '../widgets/trang_thai_loi.dart';
import 'chi_tiet_san_pham_screen.dart';
import 'yeu_cau_dang_nhap.dart';

/// Trang nhà cung cấp (GET /nha-cung-cap/:id): ảnh cơ sở, chứng nhận, sản phẩm đã duyệt và nút Theo dõi.
class NhaCungCapScreen extends StatefulWidget {
  const NhaCungCapScreen({super.key, required this.nhaCungCapId, this.sanPhamRepository, this.tuongTacRepository});

  final int nhaCungCapId;
  final SanPhamRepository? sanPhamRepository;
  final TuongTacRepository? tuongTacRepository;

  @override
  State<NhaCungCapScreen> createState() => _NhaCungCapScreenState();
}

class _NhaCungCapScreenState extends State<NhaCungCapScreen> {
  late final SanPhamRepository _spRepo = widget.sanPhamRepository ?? SanPhamRepository(ApiClient.macDinh);
  late final TuongTacRepository _ttRepo = widget.tuongTacRepository ?? TuongTacRepository(ApiClient.macDinh);

  bool _dangTai = true;
  ApiException? _loi;
  NhaCungCap? _ncc;
  bool _theoDoi = false;
  bool _dangDoi = false;

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
      final ncc = await _spRepo.nhaCungCap(widget.nhaCungCapId);
      if (!mounted) return;
      setState(() {
        _ncc = ncc;
        _dangTai = false;
      });
      await _taiTheoDoi();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loi = e;
        _dangTai = false;
      });
    }
  }

  Future<void> _taiTheoDoi() async {
    if (!PhienDangNhap.laKhach) return;
    try {
      final ds = await _ttRepo.dsTheoDoi();
      if (!mounted) return;
      setState(() => _theoDoi = ds.any((n) => n.id == widget.nhaCungCapId));
    } on ApiException {
      // bỏ qua
    }
  }

  Future<void> _doiTheoDoi() async {
    if (!await canKhach(context, lyDo: 'Đăng nhập để theo dõi nhà cung cấp.')) return;
    if (!mounted) return;
    setState(() => _dangDoi = true);
    final moi = !_theoDoi;
    try {
      if (moi) {
        await _ttRepo.theoDoi(widget.nhaCungCapId);
      } else {
        await _ttRepo.boTheoDoi(widget.nhaCungCapId);
      }
      final ncc = await _spRepo.nhaCungCap(widget.nhaCungCapId);
      if (!mounted) return;
      setState(() {
        _theoDoi = moi;
        _ncc = ncc;
        _dangDoi = false;
      });
      thongBao(context, moi ? 'Đã theo dõi ${ncc.ten}.' : 'Đã bỏ theo dõi.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _dangDoi = false);
      thongBao(context, e.thongDiepDayDu);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nhà cung cấp')),
      body: _noiDung(),
    );
  }

  Widget _noiDung() {
    if (_dangTai) return const Center(child: CircularProgressIndicator());
    final loi = _loi;
    if (loi != null) {
      return TrangThaiLoi(
        thongDiep: loi.maHttp == 404 ? 'Nhà cung cấp không tồn tại hoặc chưa được duyệt.' : loi.thongDiep,
        onThuLai: _tai,
      );
    }
    final ncc = _ncc!;
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: ncc.sanPham.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) return _dauTrang(ncc);
        final sp = ncc.sanPham[i - 1];
        return Card(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            leading: ClipRRect(
                borderRadius: BorderRadius.circular(10), child: AnhMang(url: sp.anhUrl, width: 58, height: 58)),
            title: Text(sp.ten, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${DinhDang.tien(sp.gia)} / ${sp.donViTinh}${sp.hangSao == null ? '' : ' · ${sp.hangSao} sao OCOP'}',
              style: const TextStyle(color: OcopMau.xanhOcop, fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: OcopMau.chuPhu),
            onTap: () => Navigator.push(
                context, MaterialPageRoute<void>(builder: (_) => ChiTietSanPhamScreen(sanPhamId: sp.id))),
          ),
        );
      },
    );
  }

  Widget _dauTrang(NhaCungCap ncc) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnhMang(url: ncc.anhCoSoUrl, height: 196, width: double.infinity),
        Card(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ncc.ten, style: theme.textTheme.titleLarge),
                const SizedBox(height: 6),
                Text('${ncc.tenVung} · ${ncc.diaChi}', style: theme.textTheme.bodyMedium),
                if (ncc.nguoiDaiDien != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Đại diện: ${ncc.nguoiDaiDien}', style: theme.textTheme.bodySmall),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: OcopMau.nenNhap,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${ncc.soNguoiTheoDoi} người theo dõi',
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Spacer(),
                    if (!PhienDangNhap.laNhaCungCap)
                      _theoDoi
                          ? OutlinedButton.icon(
                              key: const Key('nutTheoDoi'),
                              onPressed: _dangDoi ? null : _doiTheoDoi,
                              icon: const Icon(Icons.check_rounded, size: 18),
                              label: const Text('Đang theo dõi'),
                            )
                          : FilledButton.icon(
                              key: const Key('nutTheoDoi'),
                              onPressed: _dangDoi ? null : _doiTheoDoi,
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Theo dõi'),
                            ),
                  ],
                ),
                if (ncc.chungNhan.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DsChungNhan(chungNhan: ncc.chungNhan),
                ],
              ],
            ),
          ),
        ),
        TieuDeMucOcop('Sản phẩm (${ncc.sanPham.length})'),
      ],
    );
  }
}
