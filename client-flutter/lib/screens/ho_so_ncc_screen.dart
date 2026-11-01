import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/cua_toi_repository.dart';
import '../models/nha_cung_cap.dart';
import '../models/san_pham.dart';
import '../utils/dinh_dang.dart';
import '../widgets/anh_mang.dart';
import '../widgets/chip_trang_thai.dart';
import '../widgets/hop_thoai.dart';
import '../widgets/trang_thai_loi.dart';
import '../widgets/trang_trong.dart';
import 'ho_so_ncc_form_screen.dart';

/// Hồ sơ của nhà cung cấp đang đăng nhập (GET /cua-toi/nha-cung-cap): trạng thái duyệt, lý do
/// từ chối, chứng nhận. Chưa có hồ sơ (404 CHUA_CO_HO_SO) thì mời tạo. Hồ sơ đã duyệt thì khóa sửa
/// (backend cũng trả 409 HO_SO_DA_DUYET). Form tạo/sửa trả hồ sơ mới qua Navigator.pop.
class HoSoNccScreen extends StatefulWidget {
  const HoSoNccScreen({super.key, this.repository});

  final CuaToiRepository? repository;

  @override
  State<HoSoNccScreen> createState() => _HoSoNccScreenState();
}

class _HoSoNccScreenState extends State<HoSoNccScreen> {
  late final CuaToiRepository _repo = widget.repository ?? CuaToiRepository(ApiClient.macDinh);

  bool _dangTai = true;
  String? _loi;
  HoSoNhaCungCap? _hoSo;

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
    final hs = await Navigator.push<HoSoNhaCungCap>(
      context,
      MaterialPageRoute(builder: (_) => HoSoNccFormScreen(hoSo: _hoSo, repository: widget.repository)),
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
              icon: Icon(hs == null ? Icons.add : Icons.edit),
              label: Text(hs == null ? 'Tạo hồ sơ' : 'Sửa và gửi lại'),
            )
          : null,
    );
  }

  Widget _noiDung() {
    if (_dangTai) return const Center(child: CircularProgressIndicator());
    if (_loi != null) return TrangThaiLoi(thongDiep: _loi!, onThuLai: _tai);
    final hs = _hoSo;
    if (hs == null) {
      return const TrangTrong(
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
          AnhMang(url: hs.anhCoSoUrl, height: 180, width: double.infinity),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(hs.ten, style: theme.textTheme.titleLarge)),
                    ChipTrangThai(
                        nhan: TrangThaiDuyet.ten(hs.trangThaiDuyet), mau: ChipTrangThai.mauCua(hs.trangThaiDuyet)),
                  ],
                ),
                const SizedBox(height: 8),
                if (hs.trangThaiDuyet == TrangThaiDuyet.tuChoi && hs.lyDoTuChoi != null)
                  Card(
                    color: theme.colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('Lý do từ chối: ${hs.lyDoTuChoi}\nSửa hồ sơ rồi gửi lại để được duyệt.'),
                    ),
                  ),
                if (hs.trangThaiDuyet == TrangThaiDuyet.choDuyet)
                  const Text('Hồ sơ đang chờ quản trị viên duyệt.'),
                if (hs.trangThaiDuyet == TrangThaiDuyet.daDuyet)
                  Text('Đã duyệt${hs.duyetLuc == null ? '' : ' lúc ${DinhDang.thoiDiem(hs.duyetLuc!)}'}. '
                      'Hồ sơ đã duyệt không sửa được trên app; liên hệ quản trị nếu cần thay đổi.'),
                const SizedBox(height: 12),
                Text('Người đại diện: ${hs.nguoiDaiDien}'),
                Text('Điện thoại: ${hs.soDienThoai}'),
                Text('Địa chỉ: ${hs.diaChi}'),
                Text('Vùng nguyên liệu: ${hs.tenVung}'),
                const SizedBox(height: 16),
                Text('Giấy chứng nhận (${hs.chungNhan.length})', style: theme.textTheme.titleMedium),
              ],
            ),
          ),
          for (final cn in hs.chungNhan)
            ListTile(
              leading: Icon(cn.conHieuLuc ? Icons.verified : Icons.error_outline,
                  color: cn.conHieuLuc ? Colors.green : Colors.red),
              title: Text('${cn.loai} · ${cn.soHieu}'),
              subtitle: Text('Cấp ${cn.ngayCap == null ? '?' : DinhDang.ngay(cn.ngayCap!)}'
                  '${cn.ngayHetHan == null ? '' : ' · hết hạn ${DinhDang.ngay(cn.ngayHetHan!)}'}'),
            ),
        ],
      ),
    );
  }
}
