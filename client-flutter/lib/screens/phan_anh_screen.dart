import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/phan_anh_repository.dart';
import '../data/tai_anh_repository.dart';
import '../data/truy_xuat_repository.dart';
import '../models/phan_anh.dart';
import '../utils/kiem_tra.dart';
import '../widgets/hop_thoai.dart';
import 'chon_anh.dart';

/// Báo hàng nghi giả / sai mô tả (POST /bao-cao-vi-pham). Mở từ hành trình lô (có sẵn mã lô)
/// hoặc từ chi tiết sản phẩm. Ảnh tùy chọn. Thành công thì pop trả `true`.
class PhanAnhScreen extends StatefulWidget {
  const PhanAnhScreen({
    super.key,
    required this.sanPhamId,
    required this.tenSanPham,
    this.maTruyXuat,
    this.repository,
    this.taiAnhRepository,
  });

  final int sanPhamId;
  final String tenSanPham;
  final String? maTruyXuat;
  final PhanAnhRepository? repository;
  final TaiAnhRepository? taiAnhRepository;

  @override
  State<PhanAnhScreen> createState() => _PhanAnhScreenState();
}

class _PhanAnhScreenState extends State<PhanAnhScreen> {
  late final PhanAnhRepository _repo = widget.repository ?? PhanAnhRepository(ApiClient.macDinh);
  late final TaiAnhRepository _anhRepo = widget.taiAnhRepository ?? TaiAnhRepository(ApiClient.macDinh);
  final _formKey = GlobalKey<FormState>();
  final _noiDung = TextEditingController();
  late final _ma = TextEditingController(text: widget.maTruyXuat ?? '');
  String? _loai;
  AnhDaTai? _anh;
  bool _khoAnhChuaSan = false;
  bool _dangTaiAnh = false;
  bool _dangGui = false;

  @override
  void dispose() {
    _noiDung.dispose();
    _ma.dispose();
    super.dispose();
  }

  Future<void> _chonAnh() async {
    setState(() => _dangTaiAnh = true);
    final anh = await chonVaTaiAnh(context,
        repository: _anhRepo, mucDich: 'phan-anh', khiChuaCauHinh: () => _khoAnhChuaSan = true);
    if (!mounted) return;
    setState(() {
      _dangTaiAnh = false;
      if (anh != null) _anh = anh;
    });
  }

  Future<void> _gui() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _dangGui = true);
    try {
      await _repo.guiPhanAnh(
        sanPhamId: widget.sanPhamId,
        loai: _loai!,
        noiDung: _noiDung.text,
        maTruyXuat: _ma.text.trim().isEmpty ? null : TruyXuatRepository.tachMa(_ma.text),
        anhUrl: _anh?.url,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _dangGui = false);
      thongBao(context, e.thongDiepDayDu);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Phản ánh sản phẩm')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.tenSanPham, style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const Key('oLoaiPhanAnh'),
                initialValue: _loai,
                decoration: const InputDecoration(labelText: 'Loại phản ánh', border: OutlineInputBorder()),
                items: [
                  for (final l in LoaiPhanAnh.tatCa) DropdownMenuItem(value: l, child: Text(LoaiPhanAnh.ten(l))),
                ],
                onChanged: (v) => setState(() => _loai = v),
                validator: (v) => v == null ? 'Vui lòng chọn loại phản ánh' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('oMaLoPhanAnh'),
                controller: _ma,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Mã lô trên bao bì (không bắt buộc)',
                  helperText: 'Có mã lô thì quản trị biết chính xác lô hàng bị phản ánh',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty || TruyXuatRepository.tachMa(v) != null)
                    ? null
                    : 'Mã gồm 20 ký tự 0–9, A–F',
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('oNoiDungPhanAnh'),
                controller: _noiDung,
                maxLines: 5,
                maxLength: 2000,
                decoration: const InputDecoration(
                  labelText: 'Mô tả vấn đề',
                  hintText: 'Ví dụ: bao bì khác ảnh, mã QR không khớp sản phẩm…',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final loi = KiemTra.batBuoc(v, 'nội dung phản ánh') ?? KiemTra.doDaiToiDa(v, 2000);
                  if (loi != null) return loi;
                  return v!.trim().length < 10 ? 'Mô tả cụ thể hơn (ít nhất 10 ký tự)' : null;
                },
              ),
              Text('Ảnh minh chứng (không bắt buộc)', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              if (_khoAnhChuaSan)
                const Text('Máy chủ chưa cấu hình lưu ảnh; bạn vẫn gửi được phản ánh không kèm ảnh.'),
              Row(
                children: [
                  if (_anh != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(_anh!.bytes, width: 88, height: 88, fit: BoxFit.cover),
                      ),
                    ),
                  if (!_khoAnhChuaSan)
                    OutlinedButton.icon(
                      onPressed: _dangTaiAnh || _dangGui ? null : _chonAnh,
                      icon: _dangTaiAnh
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.add_a_photo_outlined),
                      label: Text(_anh == null ? 'Thêm ảnh' : 'Đổi ảnh'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('nutGuiPhanAnh'),
                onPressed: _dangGui || _dangTaiAnh ? null : _gui,
                child: _dangGui
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Gửi phản ánh'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
