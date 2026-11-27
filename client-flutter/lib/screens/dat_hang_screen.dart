import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/don_hang_repository.dart';
import '../data/phien_dang_nhap.dart';
import '../models/don_hang.dart';
import '../utils/dinh_dang.dart';
import '../utils/kiem_tra.dart';
import '../widgets/hop_thoai.dart';
import '../widgets/trang_thai_loi.dart';

/// Đặt hàng toàn bộ giỏ: chọn hình thức giao (GET /don-hang/hinh-thuc-giao), nhập người nhận.
/// Form + validator chặn gửi khi sai. Thành công thì `Navigator.pop(context, donHang)` trả đơn mới
/// về giỏ hàng. Giá, phí giao, tổng tiền do backend tính; app chỉ hiển thị ước tính.
class DatHangScreen extends StatefulWidget {
  const DatHangScreen({super.key, required this.tamTinh, this.repository});

  final int tamTinh;
  final DonHangRepository? repository;

  @override
  State<DatHangScreen> createState() => _DatHangScreenState();
}

class _DatHangScreenState extends State<DatHangScreen> {
  late final DonHangRepository _repo = widget.repository ?? DonHangRepository(ApiClient.macDinh);
  final _formKey = GlobalKey<FormState>();
  late final _ten = TextEditingController(text: PhienDangNhap.hienTai?.hoTen ?? '');
  late final _sdt = TextEditingController(text: PhienDangNhap.hienTai?.soDienThoai ?? '');
  final _diaChi = TextEditingController();
  final _ghiChu = TextEditingController();

  bool _dangTai = true;
  String? _loi;
  List<HinhThucGiao> _dsHinhThuc = const [];
  String? _hinhThuc;
  bool _dangGui = false;

  @override
  void initState() {
    super.initState();
    _taiHinhThuc();
  }

  @override
  void dispose() {
    for (final c in [_ten, _sdt, _diaChi, _ghiChu]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _taiHinhThuc() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    try {
      final ds = await _repo.dsHinhThucGiao();
      if (!mounted) return;
      setState(() {
        _dsHinhThuc = ds;
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

  HinhThucGiao? get _daChon {
    for (final h in _dsHinhThuc) {
      if (h.ma == _hinhThuc) return h;
    }
    return null;
  }

  bool get _laNhanTaiDiemBan {
    final ma = (_daChon?.ma ?? _hinhThuc ?? '').toLowerCase();
    final ten = (_daChon?.ten ?? '').toLowerCase();
    return ma.contains('diem_ban') ||
        ma.contains('tai_cho') ||
        ma.contains('pickup') ||
        ten.contains('điểm bán') ||
        ten.contains('nhận tại');
  }

  void _doiHinhThuc(String? v) {
    setState(() {
      _hinhThuc = v;
      if (_laNhanTaiDiemBan && _diaChi.text.trim().isEmpty) {
        _diaChi.text = 'Nhận tại điểm bán';
      } else if (!_laNhanTaiDiemBan && _diaChi.text.trim() == 'Nhận tại điểm bán') {
        _diaChi.clear();
      }
    });
  }

  Future<void> _gui() async {
    if (!_formKey.currentState!.validate()) return; // chặn gửi khi form sai
    setState(() => _dangGui = true);
    try {
      final diaChiGui = _laNhanTaiDiemBan && _diaChi.text.trim().isEmpty
          ? 'Nhận tại điểm bán'
          : _diaChi.text.trim();
      final don = await _repo.datHang(
        hinhThucGiao: _hinhThuc!,
        tenNguoiNhan: _ten.text.trim(),
        sdtNguoiNhan: _sdt.text.trim(),
        diaChiGiao: diaChiGui,
        ghiChu: _ghiChu.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, don); // trả đơn mới cho màn hình giỏ hàng
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _dangGui = false);
      thongBao(context, e.thongDiepDayDu);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đặt hàng')),
      body: _noiDung(),
    );
  }

  Widget _noiDung() {
    if (_dangTai) return const Center(child: CircularProgressIndicator());
    if (_loi != null) return TrangThaiLoi(thongDiep: _loi!, onThuLai: _taiHinhThuc);
    final theme = Theme.of(context);
    final phi = _daChon?.phiGiao ?? 0;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Hình thức giao', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    key: const Key('oHinhThucGiao'),
                    initialValue: _hinhThuc,
                    decoration: const InputDecoration(
                      hintText: 'Chọn hình thức giao',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      for (final h in _dsHinhThuc)
                        DropdownMenuItem(
                          value: h.ma,
                          child: Text('${h.ten} · ${DinhDang.tien(h.phiGiao)}'),
                        ),
                    ],
                    onChanged: _doiHinhThuc,
                    validator: (v) => v == null ? 'Vui lòng chọn hình thức giao' : null,
                  ),
                  const SizedBox(height: 14),
                  const Text('Tên người nhận', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextFormField(
                    key: const Key('oTenNguoiNhan'),
                    controller: _ten,
                    decoration: const InputDecoration(
                      hintText: 'Nhập họ và tên người nhận',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) => KiemTra.batBuoc(v, 'tên người nhận') ?? KiemTra.doDaiToiDa(v, 120),
                  ),
                  const SizedBox(height: 14),
                  const Text('Số điện thoại người nhận', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextFormField(
                    key: const Key('oSdtNguoiNhan'),
                    controller: _sdt,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'Nhập số điện thoại liên hệ',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: KiemTra.soDienThoai,
                  ),
                  const SizedBox(height: 14),
                  const Text('Địa chỉ giao', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextFormField(
                    key: const Key('oDiaChi'),
                    controller: _diaChi,
                    maxLines: _laNhanTaiDiemBan ? 1 : 2,
                    decoration: InputDecoration(
                      hintText: _laNhanTaiDiemBan
                          ? 'Nhận tại điểm bán của cơ sở'
                          : 'Nhập địa chỉ nhận hàng chi tiết',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) => KiemTra.batBuoc(v, 'địa chỉ giao') ?? KiemTra.doDaiToiDa(v, 500),
                  ),
                  const SizedBox(height: 14),
                  const Text('Ghi chú (không bắt buộc)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _ghiChu,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Ví dụ: giao giờ hành chính, gọi trước khi giao...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) => KiemTra.doDaiToiDa(v, 1000),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _dongTien('Tạm tính', widget.tamTinh),
                          _dongTien('Phí giao', phi),
                          const Divider(height: 16),
                          _dongTien('Tổng (ước tính)', widget.tamTinh + phi, dam: true),
                          const SizedBox(height: 6),
                          Text(
                            'Tổng thanh toán cuối cùng được hệ thống xác nhận khi tạo đơn.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(top: BorderSide(color: theme.dividerColor, width: 0.8)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: FilledButton(
                key: const Key('nutXacNhanDat'),
                onPressed: _dangGui ? null : _gui,
                child: _dangGui
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('Xác nhận đặt hàng · ${DinhDang.tien(widget.tamTinh + phi)}'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dongTien(String nhan, int tien, {bool dam = false}) {
    final style = dam ? Theme.of(context).textTheme.titleMedium : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [Text(nhan, style: style), const Spacer(), Text(DinhDang.tien(tien), style: style)]),
    );
  }
}