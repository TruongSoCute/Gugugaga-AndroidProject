import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/cua_toi_repository.dart';
import '../data/san_pham_repository.dart';
import '../data/tai_anh_repository.dart';
import '../models/chung_nhan.dart';
import '../models/nha_cung_cap.dart';
import '../models/vung.dart';
import '../utils/kiem_tra.dart';
import '../widgets/anh_mang.dart';
import '../widgets/hop_thoai.dart';
import '../widgets/trang_thai_loi.dart';
import 'chon_anh.dart';

/// Form tạo (POST) hoặc sửa (PUT) hồ sơ nhà cung cấp: tên, người đại diện, điện thoại, địa chỉ,
/// vùng (GET /vung-nguyen-lieu), ảnh cơ sở (tải ảnh hoặc nhập URL), danh sách chứng nhận.
/// Gửi xong hồ sơ về CHO_DUYET; pop trả hồ sơ mới.
class HoSoNccFormScreen extends StatefulWidget {
  const HoSoNccFormScreen({super.key, this.hoSo, this.repository, this.sanPhamRepository, this.taiAnhRepository});

  /// null = tạo mới.
  final HoSoNhaCungCap? hoSo;
  final CuaToiRepository? repository;
  final SanPhamRepository? sanPhamRepository;
  final TaiAnhRepository? taiAnhRepository;

  @override
  State<HoSoNccFormScreen> createState() => _HoSoNccFormScreenState();
}

/// Bộ ô nhập của một chứng nhận.
class _OChungNhan {
  _OChungNhan([ChungNhan? cn])
      : loai = TextEditingController(text: cn?.loai ?? 'OCOP'),
        soHieu = TextEditingController(text: cn?.soHieu ?? ''),
        ngayCap = TextEditingController(text: cn?.ngayCap ?? ''),
        ngayHetHan = TextEditingController(text: cn?.ngayHetHan ?? ''),
        anhUrl = cn?.anhUrl;

  final TextEditingController loai;
  final TextEditingController soHieu;
  final TextEditingController ngayCap;
  final TextEditingController ngayHetHan;
  final String? anhUrl;

  ChungNhan get giaTri => ChungNhan(
        loai: loai.text.trim(),
        soHieu: soHieu.text.trim(),
        ngayCap: ngayCap.text.trim(),
        ngayHetHan: ngayHetHan.text.trim().isEmpty ? null : ngayHetHan.text.trim(),
        anhUrl: anhUrl,
        conHieuLuc: true,
      );

  void dispose() {
    loai.dispose();
    soHieu.dispose();
    ngayCap.dispose();
    ngayHetHan.dispose();
  }
}

class _HoSoNccFormScreenState extends State<HoSoNccFormScreen> {
  late final CuaToiRepository _repo = widget.repository ?? CuaToiRepository(ApiClient.macDinh);
  late final SanPhamRepository _spRepo = widget.sanPhamRepository ?? SanPhamRepository(ApiClient.macDinh);
  late final TaiAnhRepository _anhRepo = widget.taiAnhRepository ?? TaiAnhRepository(ApiClient.macDinh);

  final _formKey = GlobalKey<FormState>();
  late final _ten = TextEditingController(text: widget.hoSo?.ten ?? '');
  late final _daiDien = TextEditingController(text: widget.hoSo?.nguoiDaiDien ?? '');
  late final _sdt = TextEditingController(text: widget.hoSo?.soDienThoai ?? '');
  late final _diaChi = TextEditingController(text: widget.hoSo?.diaChi ?? '');
  late final _anhCoSo = TextEditingController(text: widget.hoSo?.anhCoSoUrl ?? '');
  late final List<_OChungNhan> _chungNhan = widget.hoSo == null || widget.hoSo!.chungNhan.isEmpty
      ? [_OChungNhan()]
      : [for (final cn in widget.hoSo!.chungNhan) _OChungNhan(cn)];
  late int? _vungId = widget.hoSo?.vungId;

  List<Vung> _dsVung = const [];
  bool _dangTaiVung = true;
  String? _loiVung;
  bool _dangTaiAnh = false;
  bool _dangGui = false;

  @override
  void initState() {
    super.initState();
    _taiVung();
  }

  @override
  void dispose() {
    for (final c in [_ten, _daiDien, _sdt, _diaChi, _anhCoSo]) {
      c.dispose();
    }
    for (final o in _chungNhan) {
      o.dispose();
    }
    super.dispose();
  }

  Future<void> _taiVung() async {
    setState(() {
      _dangTaiVung = true;
      _loiVung = null;
    });
    try {
      final ds = await _spRepo.dsVung();
      if (!mounted) return;
      setState(() {
        _dsVung = ds;
        _dangTaiVung = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loiVung = e.thongDiep;
        _dangTaiVung = false;
      });
    }
  }

  Future<void> _taiAnhCoSo() async {
    setState(() => _dangTaiAnh = true);
    final anh = await chonVaTaiAnh(context, repository: _anhRepo, mucDich: 'nha-cung-cap');
    if (!mounted) return;
    setState(() {
      _dangTaiAnh = false;
      if (anh != null) _anhCoSo.text = anh.url;
    });
  }

  Future<void> _chonNgay(TextEditingController o) async {
    final hienTai = DateTime.tryParse(o.text) ?? DateTime.now();
    final ngay = await showDatePicker(
      context: context,
      initialDate: hienTai,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted || ngay == null) return;
    String hai(int n) => n.toString().padLeft(2, '0');
    setState(() => o.text = '${ngay.year}-${hai(ngay.month)}-${hai(ngay.day)}');
  }

  Future<void> _gui() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _dangGui = true);
    try {
      final hs = await _repo.luuHoSo(
        taoMoi: widget.hoSo == null,
        ten: _ten.text,
        nguoiDaiDien: _daiDien.text,
        soDienThoai: _sdt.text,
        diaChi: _diaChi.text,
        vungId: _vungId!,
        anhCoSoUrl: _anhCoSo.text,
        chungNhan: [for (final o in _chungNhan) o.giaTri],
      );
      if (!mounted) return;
      Navigator.pop(context, hs);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _dangGui = false);
      thongBao(context, e.thongDiepDayDu);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.hoSo == null ? 'Tạo hồ sơ' : 'Sửa hồ sơ')),
      body: _dangTaiVung
          ? const Center(child: CircularProgressIndicator())
          : _loiVung != null
              ? TrangThaiLoi(thongDiep: _loiVung!, onThuLai: _taiVung)
              : _form(),
    );
  }

  Widget _form() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('oTenCoSo'),
              controller: _ten,
              decoration: const InputDecoration(labelText: 'Tên cơ sở / HTX', border: OutlineInputBorder()),
              validator: (v) => KiemTra.batBuoc(v, 'tên cơ sở') ?? KiemTra.doDaiToiDa(v, 200),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('oDaiDien'),
              controller: _daiDien,
              decoration: const InputDecoration(labelText: 'Người đại diện', border: OutlineInputBorder()),
              validator: (v) => KiemTra.batBuoc(v, 'người đại diện') ?? KiemTra.doDaiToiDa(v, 120),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('oSdtCoSo'),
              controller: _sdt,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()),
              validator: KiemTra.soDienThoai,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('oDiaChiCoSo'),
              controller: _diaChi,
              decoration: const InputDecoration(labelText: 'Địa chỉ cơ sở', border: OutlineInputBorder()),
              validator: (v) => KiemTra.batBuoc(v, 'địa chỉ') ?? KiemTra.doDaiToiDa(v, 500),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              key: const Key('oVung'),
              initialValue: _dsVung.any((v) => v.id == _vungId) ? _vungId : null,
              decoration: const InputDecoration(labelText: 'Vùng nguyên liệu', border: OutlineInputBorder()),
              items: [for (final v in _dsVung) DropdownMenuItem(value: v.id, child: Text(v.ten))],
              onChanged: (v) => setState(() => _vungId = v),
              validator: (v) => v == null ? 'Vui lòng chọn vùng' : null,
            ),
            const SizedBox(height: 16),
            Text('Ảnh cơ sở sản xuất', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            if (_anhCoSo.text.trim().isNotEmpty && KiemTra.urlTuyChon(_anhCoSo.text) == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AnhMang(url: _anhCoSo.text.trim(), height: 140, width: double.infinity),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _anhCoSo,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Đường dẫn ảnh',
                      helperText: 'Tải ảnh lên hoặc dán URL https://…',
                      border: OutlineInputBorder(),
                    ),
                    validator: KiemTra.urlTuyChon,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Tải ảnh lên',
                  onPressed: _dangTaiAnh ? null : _taiAnhCoSo,
                  icon: _dangTaiAnh
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.upload),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Text('Giấy chứng nhận', style: theme.textTheme.titleSmall)),
                TextButton.icon(
                  onPressed: _chungNhan.length >= 10 ? null : () => setState(() => _chungNhan.add(_OChungNhan())),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm'),
                ),
              ],
            ),
            Text('Cần ít nhất một chứng nhận OCOP để được duyệt.', style: theme.textTheme.bodySmall),
            for (var i = 0; i < _chungNhan.length; i++) _oChungNhan(i),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('nutGuiHoSo'),
              onPressed: _dangGui || _dangTaiAnh ? null : _gui,
              child: _dangGui
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Gửi hồ sơ chờ duyệt'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _oChungNhan(int i) {
    final o = _chungNhan[i];
    String? kiemTraNgay(String? v, {required bool batBuoc}) {
      if (v == null || v.trim().isEmpty) return batBuoc ? 'Chọn ngày' : null;
      return KiemTra.laNgay(v.trim()) ? null : 'Ngày dạng YYYY-MM-DD';
    }

    return Card(
      key: ObjectKey(o),
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: o.loai,
                    decoration: const InputDecoration(labelText: 'Loại (OCOP, ATTP…)', isDense: true),
                    validator: (v) => KiemTra.batBuoc(v, 'loại') ?? KiemTra.doDaiToiDa(v, 60),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: o.soHieu,
                    decoration: const InputDecoration(labelText: 'Số hiệu', isDense: true),
                    validator: (v) => KiemTra.batBuoc(v, 'số hiệu') ?? KiemTra.doDaiToiDa(v, 80),
                  ),
                ),
                IconButton(
                  tooltip: 'Bỏ chứng nhận này',
                  onPressed: () {
                    setState(() => _chungNhan.removeAt(i));
                    // Hủy controller sau khung hình, khi ô nhập cũ đã gỡ khỏi cây widget.
                    WidgetsBinding.instance.addPostFrameCallback((_) => o.dispose());
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: o.ngayCap,
                    readOnly: true,
                    onTap: () => _chonNgay(o.ngayCap),
                    decoration: const InputDecoration(labelText: 'Ngày cấp', isDense: true),
                    validator: (v) => kiemTraNgay(v, batBuoc: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: o.ngayHetHan,
                    readOnly: true,
                    onTap: () => _chonNgay(o.ngayHetHan),
                    decoration: const InputDecoration(labelText: 'Ngày hết hạn (nếu có)', isDense: true),
                    validator: (v) {
                      final loi = kiemTraNgay(v, batBuoc: false);
                      if (loi != null || v == null || v.trim().isEmpty) return loi;
                      // So sánh chuỗi YYYY-MM-DD đúng bằng so sánh ngày.
                      return v.trim().compareTo(o.ngayCap.text.trim()) <= 0 ? 'Phải sau ngày cấp' : null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
