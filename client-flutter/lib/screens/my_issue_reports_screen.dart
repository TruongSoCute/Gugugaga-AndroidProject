import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/issue_report_repository.dart';
import '../models/issue_report.dart';
import '../utils/formatting.dart';
import '../widgets/network_image_view.dart';
import '../widgets/status_chip.dart';
import '../widgets/theme_widgets.dart';
import '../widgets/error_state.dart';
import '../widgets/empty_state.dart';

/// Phản ánh của tôi (GET /bao-cao-vi-pham): trạng thái và kết quả xử lý của quản trị.
class MyIssueReportsScreen extends StatefulWidget {
  const MyIssueReportsScreen({super.key, this.repository});

  final IssueReportRepository? repository;

  @override
  State<MyIssueReportsScreen> createState() => _MyIssueReportsScreenState();
}

class _MyIssueReportsScreenState extends State<MyIssueReportsScreen> {
  late final IssueReportRepository _repo = widget.repository ?? IssueReportRepository(ApiClient.macDinh);

  bool _dangTai = true;
  String? _loi;
  List<IssueReport> _ds = const [];

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
      final ds = await _repo.dsCuaToi();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Phản ánh của tôi')), body: _noiDung());
  }

  Widget _noiDung() {
    if (_dangTai) return const Center(child: CircularProgressIndicator());
    if (_loi != null) return ErrorState(thongDiep: _loi!, onThuLai: _tai);
    if (_ds.isEmpty) {
      return const EmptyState(
        icon: Icons.report_outlined,
        thongDiep: 'Bạn chưa gửi phản ánh nào.\nGặp hàng nghi giả? Mở hành trình lô hoặc chi tiết sản phẩm và chọn "Phản ánh".',
      );
    }
    return RefreshIndicator(
      onRefresh: _tai,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        itemCount: _ds.length,
        itemBuilder: (context, i) {
          final p = _ds[i];
          final theme = Theme.of(context);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: NetworkImageView(url: p.anhUrl ?? p.anhSanPham, width: 50, height: 50),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.tenSanPham, style: theme.textTheme.titleSmall),
                            Text('${IssueReportType.ten(p.loai)} · ${Formatting.thoiDiem(p.taoLuc)}',
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      StatusChip(nhan: IssueReportStatus.ten(p.trangThai), mau: StatusChip.mauCua(p.trangThai)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(p.noiDung),
                  if (p.maTruyXuat != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: OcopColors.xanhNhat,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Lô: ${p.maTruyXuat}',
                            style: const TextStyle(fontSize: 12, color: OcopColors.xanhOcop, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  if (p.ketQuaXuLy != null) ...[
                    const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider()),
                    Text('Kết quả xử lý', style: theme.textTheme.labelLarge?.copyWith(color: OcopColors.xanhOcop)),
                    const SizedBox(height: 2),
                    Text(p.ketQuaXuLy!),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
