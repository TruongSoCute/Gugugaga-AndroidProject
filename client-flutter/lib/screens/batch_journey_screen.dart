import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/auth_session.dart';
import '../data/traceability_repository.dart';
import '../models/batch_journey.dart';
import '../models/sourcing_region.dart';
import '../utils/formatting.dart';
import '../widgets/network_image_view.dart';
import '../widgets/animations.dart';
import '../widgets/theme_widgets.dart';
import '../widgets/dialogs.dart';
import '../widgets/error_state.dart';
import 'region_map_screen.dart';
import 'issue_report_screen.dart';
import 'require_login.dart';

/// Hành trình của ĐÚNG lô có mã này (điểm nhấn kỹ thuật của đề 5).
class BatchJourneyScreen extends StatefulWidget {
  const BatchJourneyScreen({super.key, required this.maTruyXuat, this.repository});

  final String maTruyXuat;
  final TraceabilityRepository? repository;

  @override
  State<BatchJourneyScreen> createState() => _BatchJourneyScreenState();
}

class _BatchJourneyScreenState extends State<BatchJourneyScreen> {
  late final TraceabilityRepository _repo = widget.repository ?? TraceabilityRepository(ApiClient());

  bool _dangTai = true;
  ApiException? _loi;
  BatchJourney? _lo;

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
      final lo = await _repo.layHanhTrinh(widget.maTruyXuat);
      if (!mounted) return;
      setState(() {
        _lo = lo;
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

  Future<void> _phanAnh() async {
    final lo = _lo!;
    if (!await canKhach(context, lyDo: 'Đăng nhập để báo hàng nghi giả hoặc sai mô tả.')) return;
    if (!mounted) return;
    final daGui = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => IssueReportScreen(sanPhamId: lo.sanPhamId, tenSanPham: lo.tenSanPham, maTruyXuat: lo.maTruyXuat),
      ),
    );
    if (!mounted) return;
    if (daGui == true) thongBao(context, 'Đã gửi phản ánh cho lô ${lo.maTruyXuat}.');
  }

  @override
  Widget build(BuildContext context) {
    final coLo = _lo != null && !_dangTai && _loi == null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hành trình lô hàng'),
        actions: [
          if (coLo && !AuthSession.laNhaCungCap && _lo!.sanPhamId > 0)
            TextButton.icon(
              key: const Key('nutPhanAnhLo'),
              onPressed: _phanAnh,
              icon: const Icon(Icons.flag_outlined, size: 18),
              label: const Text('Phản ánh'),
            ),
        ],
      ),
      body: _noiDung(),
    );
  }

  Widget _noiDung() {
    if (_dangTai) {
      return const AnimatedStateTransition(khoa: 'tai', child: Center(child: CircularProgressIndicator()));
    }
    final loi = _loi;
    if (loi != null) {
      if (loi.maHttp == 404) {
        return AnimatedStateTransition(
          khoa: '404',
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: FadeIn(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(color: OcopColors.vangNhat, shape: BoxShape.circle),
                      child: const Icon(Icons.gpp_maybe_rounded, size: 32, color: OcopColors.vangOcop),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Không xác minh được nguồn gốc của mã này.\n'
                      'Hãy kiểm tra lại mã trên bao bì; nếu mã vẫn không đúng, sản phẩm có thể không chính hãng.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: OcopColors.chuPhu, height: 1.45),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      return AnimatedStateTransition(khoa: 'loi', child: ErrorState(thongDiep: loi.thongDiep, onThuLai: _tai));
    }
    final lo = _lo!;
    return AnimatedStateTransition(
      khoa: 'lo-${lo.maTruyXuat}',
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 28),
        itemCount: lo.cacBuoc.length + 1,
        itemBuilder: (context, i) => i == 0
            ? FadeIn(thuTu: 0, child: _BatchInfo(lo: lo))
            : FadeIn(thuTu: i, child: _StepRow(buoc: lo.cacBuoc[i - 1], cuoi: i == lo.cacBuoc.length)),
      ),
    );
  }
}

class _BatchInfo extends StatelessWidget {
  const _BatchInfo({required this.lo});

  final BatchJourney lo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: NetworkImageView(url: lo.anhHienTruongUrl ?? lo.anhSanPhamUrl, height: 200, width: double.infinity),
          ),
        ),
        Card(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: OcopColors.xanhNhat, borderRadius: BorderRadius.circular(999)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, size: 14, color: OcopColors.xanhOcop),
                      SizedBox(width: 5),
                      Text(
                        'Đã xác thực OCOP',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: OcopColors.xanhOcop),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(lo.tenSanPham, style: theme.textTheme.titleLarge),
                if (lo.hangSao != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${'★' * lo.hangSao!} OCOP ${lo.hangSao} sao',
                      style: theme.textTheme.bodySmall?.copyWith(color: OcopColors.vangChu, fontWeight: FontWeight.w600),
                    ),
                  ),
                const SizedBox(height: 14),
                _InfoRow(nhan: 'Mã lô', giaTri: lo.maTruyXuat, mono: true),
                _InfoRow(nhan: 'Ngày sản xuất', giaTri: Formatting.ngay(lo.ngaySanXuat)),
                _InfoRow(nhan: 'Hạn sử dụng', giaTri: Formatting.ngay(lo.hanSuDung)),
                _InfoRow(nhan: 'Vùng nguyên liệu', giaTri: lo.vungNguyenLieu),
                if (lo.vungViDo != null && lo.vungKinhDo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: OutlinedButton.icon(
                      key: const Key('nutXemBanDoVung'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RegionMapScreen(
                            dsVung: [
                              SourcingRegion(
                                id: lo.vungId ?? 0,
                                ten: lo.vungNguyenLieu,
                                moTa: lo.vungMoTa,
                                viDo: lo.vungViDo,
                                kinhDo: lo.vungKinhDo,
                              ),
                            ],
                            vungIdChonSan: lo.vungId ?? 0,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('Xem vùng nguyên liệu trên bản đồ'),
                    ),
                  ),
                _InfoRow(nhan: 'Người sản xuất', giaTri: lo.nguoiSanXuat),
                _InfoRow(nhan: 'Nhà cung cấp', giaTri: lo.tenNhaCungCap),
                _InfoRow(nhan: 'Địa chỉ', giaTri: lo.diaChiNhaCungCap),
                if (lo.chungNhan.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final cn in lo.chungNhan)
                        Chip(
                          backgroundColor: cn.conHieuLuc ? OcopColors.xanhNhat : OcopColors.nenDoLoi,
                          avatar: Icon(
                            cn.conHieuLuc ? Icons.verified_rounded : Icons.error_outline_rounded,
                            size: 15,
                            color: cn.conHieuLuc ? OcopColors.xanhOcop : OcopColors.doLoi,
                          ),
                          label: Text(
                            '${cn.loai} ${cn.soHieu}${cn.conHieuLuc ? '' : ' (hết hạn)'}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cn.conHieuLuc ? OcopColors.xanhOcop : OcopColors.doLoi,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        OcopSectionTitle('Hành trình (${lo.cacBuoc.length} bước)'),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.nhan, required this.giaTri, this.mono = false});

  final String nhan;
  final String giaTri;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(nhan, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              giaTri,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFamily: mono ? 'monospace' : null,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.buoc, required this.cuoi});

  final TraceabilityStep buoc;
  final bool cuoi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(color: OcopColors.chuChinh, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(
                      '${buoc.thuTu}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (!cuoi)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: const Color(0xFFE2E5EA),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(buoc.tenBuoc, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(Formatting.thoiDiem(buoc.thoiDiem), style: theme.textTheme.bodySmall),
                      if (buoc.moTa != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(buoc.moTa!, style: theme.textTheme.bodyMedium?.copyWith(height: 1.45)),
                        ),
                      if (buoc.anhUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: NetworkImageView(url: buoc.anhUrl, height: 148, width: double.infinity),
                          ),
                        ),
                    ],
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
