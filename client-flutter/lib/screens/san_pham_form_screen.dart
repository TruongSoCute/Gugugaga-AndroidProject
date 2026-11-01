import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/cua_toi_repository.dart';
import '../data/tai_anh_repository.dart';
import '../models/san_pham.dart';
import '../utils/kiem_tra.dart';
import '../widgets/anh_mang.dart';
import '../widgets/hop_thoai.dart';
import 'chon_anh.dart';

/// Form thêm (POST /cua-toi/san-pham) hoặc sửa (PUT /cua-toi/san-pham/:id) sản phẩm.
/// Không có ô hạng sao hay trạng thái: quản trị viên chốt khi duyệt. Giá là số nguyên VND.
/// Thành công thì pop trả sản phẩm.
class SanPhamFormScreen extends StatefulWidget {
  const SanPhamFormScreen({super.key, this.sanPham, this.repository, this.taiAnhRepository});

  final SanPhamCuaToi? sanPham;
  final CuaToiRepository? repository;
  final TaiAnhRepository? taiAnhRepository;

  @override
  State<SanPhamFormScreen> createState() => _SanPhamFormScreenState();
}

class _SanPhamFormScreenState extends State<SanPhamFormScreen> {
  late final CuaToiRepository _repo = widget.repository ?? CuaToiRepository(ApiClient.macDinh);
  late final TaiAnhRepository _anhRepo = widget.taiAnhRepository ?? TaiAnhRepository(ApiClient.macDinh);

  final _formKey = GlobalKey<FormState>();
  late final _ten = TextEditingController(text: widget.sanPham?.ten ?? '');
  late final _gia = TextEditingController(text: widget.sanPham == null ? '' : '${widget.sanPham!.gia}');
  late final _donVi = TextEditingController(text: widget.sanPham?.donViTinh ?? '');
  late final _moTa = TextEditingController(text: widget.sanPham?.moTa ?? '');
  late final _anh = TextEditingController(text: widget.sanPham?.anhUrl ?? '');
  bool _dangTaiAnh = false;
  bool _dangGui = false;

  @override
  void dispose() {
    for (final c in [_ten, _gia, _donVi, _moTa, _anh]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _taiAnh() async {
    setState(() => _dangTaiAnh = true);
    final anh = await chonVaTaiAnh(context, repository: _anhRepo, mucDich: 'san-pham');
    if (!mounted) return;
    setState(() {
      _dangTaiAnh = false;
      if (anh != null) _anh.text = anh.url;
    });
  }

  Future<void> _gui() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _dangGui = true);
    try {
      final sp = await _repo.luuSanPham(
        id: widget.sanPham?.id,
        ten: _ten.text,
        gia: int.parse(_gia.text.trim()),
        donViTinh: _donVi.text,
        moTa: _moTa.text,
        anhUrl: _anh.text,
      );
      if (!mounted) return;
      Navigator.pop(context, sp);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _dangGui = false);
      thongBao(context, e.thongDiepDayDu);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sp = widget.sanPham;
    return Scaffold(
      appBar: AppBar(title: Text(sp == null ? 'Thêm sản phẩm' : 'Sửa sản phẩm')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (sp?.lyDoTuChoi != null)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('Lý do bị từ chối: ${sp!.lyDoTuChoi}'),
                  ),
                ),
              TextFormField(
                key: const Key('oTenSanPham'),
                controller: _ten,
                decoration: const InputDecoration(labelText: 'Tên sản phẩm', border: OutlineInputBorder()),
                validator: (v) => KiemTra.batBuoc(v, 'tên sản phẩm') ?? KiemTra.doDaiToiDa(v, 200),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      key: const Key('oGia'),
                      controller: _gia,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Giá bán (đồng)', suffixText: 'đ', border: OutlineInputBorder()),
                      validator: KiemTra.gia,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _donVi,
                      decoration: const InputDecoration(labelText: 'Đơn vị (gói, hũ…)', border: OutlineInputBorder()),
                      validator: (v) => KiemTra.doDaiToiDa(v, 40),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _moTa,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder()),
                validator: (v) => KiemTra.doDaiToiDa(v, 5000),
              ),
              const SizedBox(height: 12),
              if (_anh.text.trim().isNotEmpty && KiemTra.urlTuyChon(_anh.text) == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AnhMang(url: _anh.text.trim(), height: 160, width: double.infinity),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _anh,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Ảnh sản phẩm',
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
                    onPressed: _dangTaiAnh ? null : _taiAnh,
                    icon: _dangTaiAnh
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.upload),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Hạng sao OCOP do quản trị viên chốt khi duyệt.', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              FilledButton(
                key: const Key('nutLuuSanPham'),
                onPressed: _dangGui || _dangTaiAnh ? null : _gui,
                child: _dangGui
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Gửi chờ duyệt'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
