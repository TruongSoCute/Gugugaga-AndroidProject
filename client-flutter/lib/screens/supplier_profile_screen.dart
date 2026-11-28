import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/my_supplier_repository.dart';
import '../models/supplier.dart';
import '../models/product.dart';
import '../utils/formatting.dart';
import '../widgets/network_image_view.dart';
import '../widgets/status_chip.dart';
import '../widgets/theme_widgets.dart';
import '../widgets/dialogs.dart';
import '../widgets/error_state.dart';
import '../widgets/empty_state.dart';
import 'supplier_profile_form_screen.dart';

/// Hồ sơ của nhà cung cấp đang đăng nhập (GET /cua-toi/nha-cung-cap).
class SupplierProfileScreen extends StatefulWidget {
  const SupplierProfileScreen({super.key, this.repository});

  final MySupplierRepository? repository;

  @override
  State<SupplierProfileScreen> createState() => _SupplierProfileScreenState();
}

class _SupplierProfileScreenState extends State<SupplierProfileScreen> {
  late final MySupplierRepository _repo = widget.repository ?? MySupplierRepository(ApiClient.macDinh);

  bool _dangTai = true;
  String? _loi;
  SupplierProfile? _hoSo;

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
      final hs = await _repo.hoSo();
      if (!mounted) return;
      setState(() {
        _hoSo = hs;
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

  Future<void> _moForm() async {
    final hs = await Navigator.push<SupplierProfile>(
      context,
      MaterialPageRoute(builder: (_) => SupplierProfileFormScreen(hoSo: _hoSo, repository: widget.repository)),
    );
    if (!mounted || hs == null) return;
    setState(() => _hoSo = hs);
    thongBao(context, 'Đã gửi hồ sơ. Vui lòng chờ quản trị viên duyệt.');
  }

  @override
  Widget build(BuildContext context) {
    final hs = _hoSo;
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ nhà cung cấp')),
      body: _noiDung(),
      floatingActionButton: !_dangTai && _loi == null && (hs == null || hs.duocSua)
          ? FloatingActionButton.extended(
              key: const Key('nutSuaHoSo'),
              onPressed: _moForm,
              icon: Icon(hs == null ? Icons.add_rounded : Icons.edit_outlined),
              label: Text(hs == null ? 'Tạo hồ sơ' : 'Sửa và gửi lại'),
            )
          : null,
    );
  }

  Widget _noiDung() {
    if (_dangTai) return const Center(child: CircularProgressIndicator());
    if (_loi != null) return ErrorState(thongDiep: _loi!, onThuLai: _tai);
    final hs = _hoSo;
    if (hs == null) {
      return const EmptyState(
        icon: Icons.store_outlined,
        thongDiep: 'Bạn chưa gửi hồ sơ cơ sở sản xuất.\n'
            'Tạo hồ sơ kèm giấy chứng nhận OCOP và ảnh cơ sở để quản trị viên duyệt, '
            'sau đó mới thêm được sản phẩm.',
      );
    }
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: _tai,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          NetworkImageView(url: hs.anhCoSoUrl, height: 196, width: double.infinity),
          Card(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(hs.ten, style: theme.textTheme.titleLarge)),
                      const SizedBox(width: 8),
                      StatusChip(
                          nhan: ApprovalStatus.ten(hs.trangThaiDuyet), mau: StatusChip.mauCua(hs.trangThaiDuyet)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (hs.trangThaiDuyet == ApprovalStatus.tuChoi && hs.lyDoTuChoi != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: OcopColors.nenDoLoi,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Lý do từ chối: ${hs.lyDoTuChoi}\nSửa hồ sơ rồi gửi lại để được duyệt.',
                        style: const TextStyle(color: OcopColors.doLoi),
                      ),
                    ),
                  if (hs.trangThaiDuyet == ApprovalStatus.choDuyet)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: OcopColors.vangNhat,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Hồ sơ đang chờ quản trị viên duyệt.', style: TextStyle(color: OcopColors.vangChu)),
                    ),
                  if (hs.trangThaiDuyet == ApprovalStatus.daDuyet)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: OcopColors.xanhNhat,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Đã duyệt${hs.duyetLuc == null ? '' : ' lúc ${Formatting.thoiDiem(hs.duyetLuc!)}'}. '
                        'Hồ sơ đã duyệt không sửa được trên app; liên hệ quản trị nếu cần thay đổi.',
                        style: const TextStyle(color: OcopColors.xanhOcop),
                      ),
                    ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                  Text('Người đại diện: ${hs.nguoiDaiDien}'),
                  const SizedBox(height: 4),
                  Text('Điện thoại: ${hs.soDienThoai}'),
                  const SizedBox(height: 4),
                  Text('Địa chỉ: ${hs.diaChi}'),
                  const SizedBox(height: 4),
                  Text('Vùng nguyên liệu: ${hs.tenVung}',
                      style: const TextStyle(color: OcopColors.xanhOcop, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          OcopSectionTitle('Giấy chứng nhận (${hs.chungNhan.length})'),
          for (final cn in hs.chungNhan)
            Card(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cn.conHieuLuc ? OcopColors.xanhNhat : OcopColors.nenDoLoi,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    cn.conHieuLuc ? Icons.verified_rounded : Icons.error_outline_rounded,
                    color: cn.conHieuLuc ? OcopColors.xanhOcop : OcopColors.doLoi,
                  ),
                ),
                title: Text('${cn.loai} · ${cn.soHieu}', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Cấp ${cn.ngayCap == null ? '?' : Formatting.ngay(cn.ngayCap!)}'
                    '${cn.ngayHetHan == null ? '' : ' · hết hạn ${Formatting.ngay(cn.ngayHetHan!)}'}'),
              ),
            ),
        ],
      ),
    );
  }
}
