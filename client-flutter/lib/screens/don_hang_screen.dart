
import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/don_hang_repository.dart';
import '../models/don_hang.dart';
import '../utils/dinh_dang.dart';
import '../widgets/anh_mang.dart';
import '../widgets/chip_trang_thai.dart';
import '../widgets/trang_thai_loi.dart';
import '../widgets/trang_trong.dart';
import 'chi_tiet_don_screen.dart';

/// Đơn hàng của tôi (GET /don-hang?trangThai=): ListView.builder, lọc theo trạng thái.
/// Mở chi tiết và chờ kết quả: nếu đơn đổi trạng thái (hủy, đã nhận, đánh giá) thì tải lại.
class DonHangScreen extends StatefulWidget {
  const DonHangScreen({super.key, this.repository});

  final DonHangRepository? repository;

  @override
  State<DonHangScreen> createState() => _DonHangScreenState();
}

class _DonHangScreenState extends State<DonHangScreen> {
  late final DonHangRepository _repo =
      widget.repository ?? DonHangRepository(ApiClient.macDinh);

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
      MaterialPageRoute(
        builder: (_) => ChiTietDonScreen(
          donHangId: d.id,
          repository: widget.repository,
        ),
      ),
    );
    if (!mounted) return;
    if (daDoi == true) await _tai();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn hàng của tôi'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 58,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              children: [
                for (final tt in <String?>[null, ...TrangThaiDon.tatCa])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        tt == null ? 'Tất cả' : TrangThaiDon.ten(tt),
                      ),
                      selected: _trangThai == tt,
                      showCheckmark: false,
                      selectedColor: colors.primaryContainer,
                      backgroundColor: colors.surface,
                      side: BorderSide(
                        color: _trangThai == tt
                            ? colors.primary
                            : colors.outlineVariant,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: _trangThai == tt
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: _trangThai == tt
                            ? colors.onPrimaryContainer
                            : colors.onSurfaceVariant,
                      ),
                      onSelected: (_) {
                        if (_trangThai == tt) return;
                        setState(() => _trangThai = tt);
                        _tai();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: colors.outlineVariant.withValues(alpha: 0.5),
          ),
          Expanded(child: _noiDung()),
        ],
      ),
    );
  }

  Widget _noiDung() {
    if (_dangTai) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_loi != null) {
      return TrangThaiLoi(
        thongDiep: _loi!,
        onThuLai: _tai,
      );
    }

    if (_ds.isEmpty) {
      return RefreshIndicator(
        onRefresh: _tai,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            TrangTrong(
              icon: Icons.receipt_long_outlined,
              thongDiep: 'Chưa có đơn hàng nào.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _tai,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        itemCount: _ds.length,
        itemBuilder: (context, i) {
          final d = _ds[i];
          final theme = Theme.of(context);
          final colors = theme.colorScheme;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            color: colors.surface,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
            child: InkWell(
              onTap: () => _moChiTiet(d),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Đơn #${d.id}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                        ChipTrangThai(
                          nhan: TrangThaiDon.ten(d.trangThai),
                          mau: ChipTrangThai.mauCua(d.trangThai),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: AnhMang(
                            url: d.anhSanPhamDau,
                            width: 76,
                            height: 76,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 76,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${d.tenSanPhamDau ?? ''}${d.soSanPham > 1 ? ' và ${d.soSanPham - 1} sản phẩm khác' : ''}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 13,
                                      color: colors.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        DinhDang.thoiDiem(d.taoLuc),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: colors.onSurfaceVariant,
                                        ),
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
                    const SizedBox(height: 12),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: colors.outlineVariant.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tổng thanh toán',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                DinhDang.tien(d.tongTien),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Xem chi tiết',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: colors.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
