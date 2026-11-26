import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/api_client.dart';
import '../data/don_hang_repository.dart';
import '../models/don_hang.dart';
import '../utils/dinh_dang.dart';
import '../widgets/anh_mang.dart';
import '../widgets/chip_trang_thai.dart';
import '../widgets/chuyen_dong.dart';
import '../widgets/giao_dien.dart';
import '../widgets/trang_thai_loi.dart';
import '../widgets/trang_trong.dart';
import 'chi_tiet_don_screen.dart';

/// Đơn hàng của tôi (GET /don-hang?trangThai=): ListView.builder, lọc theo trạng thái.
class DonHangScreen extends StatefulWidget {
  const DonHangScreen({super.key, this.repository});

  final DonHangRepository? repository;

  @override
  State<DonHangScreen> createState() => _DonHangScreenState();
}

class _DonHangScreenState extends State<DonHangScreen> {
  late final DonHangRepository _repo = widget.repository ?? DonHangRepository(ApiClient.macDinh);

  String? _trangThai;
  bool _dangTai = true;
  String? _loi;
  List<DonHangTomTat> _ds = const [];

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

  Future<void> _moChiTiet(DonHangTomTat d) async {
    final daDoi = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ChiTietDonScreen(donHangId: d.id, repository: widget.repository)),
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
                for (final tt in <String?>[null, ...TrangThaiDon.tatCa])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(tt == null ? 'Tất cả' : TrangThaiDon.ten(tt)),
                      selected: _trangThai == tt,
                      backgroundColor: OcopMau.nenThe,
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
      return const ChuyenTrangThaiMuot(khoa: 'tai', child: Center(child: CircularProgressIndicator()));
    }
    if (_loi != null) {
      return ChuyenTrangThaiMuot(khoa: 'loi', child: TrangThaiLoi(thongDiep: _loi!, onThuLai: _tai));
    }
    if (_ds.isEmpty) {
      return ChuyenTrangThaiMuot(
        khoa: 'trong-${_trangThai ?? 'all'}',
        child: RefreshIndicator(
          onRefresh: _tai,
          child: ListView(children: const [
            SizedBox(height: 100),
            TrangTrong(icon: Icons.receipt_long_outlined, thongDiep: 'Chưa có đơn hàng nào.'),
          ]),
        ),
      );
    }
    return ChuyenTrangThaiMuot(
      khoa: 'ds-${_trangThai ?? 'all'}-${_ds.length}',
      child: RefreshIndicator(
        onRefresh: _tai,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          itemCount: _ds.length,
          itemBuilder: (context, i) {
            final d = _ds[i];
            final theme = Theme.of(context);
            return HienLenMuot(
              thuTu: i,
              child: NhanNhe(
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
                            child: AnhMang(url: d.anhSanPhamDau, width: 80, height: 84),
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
                                    ChipTrangThai(nhan: TrangThaiDon.ten(d.trangThai), mau: ChipTrangThai.mauCua(d.trangThai)),
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
                                    Text(DinhDang.thoiDiem(d.taoLuc), style: theme.textTheme.bodySmall),
                                    const Spacer(),
                                    Text(
                                      DinhDang.tien(d.tongTien),
                                      style: theme.textTheme.titleSmall?.copyWith(color: OcopMau.chuChinh, fontWeight: FontWeight.w800),
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
