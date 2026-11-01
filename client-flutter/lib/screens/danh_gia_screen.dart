import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/danh_gia_repository.dart';
import '../data/tai_anh_repository.dart';
import '../utils/kiem_tra.dart';
import '../widgets/hop_thoai.dart';
import 'chon_anh.dart';

/// Đánh giá một sản phẩm trong đơn đã nhận: số sao (bắt buộc), nội dung, tối đa 5 ảnh thật
/// chụp/chọn bằng image_picker. Mỗi ảnh tải lên ngay khi chọn (POST /tai-len/anh), rồi gửi
/// POST /danh-gia kèm các URL. Thành công thì pop trả `true`.
class DanhGiaScreen extends StatefulWidget {
  const DanhGiaScreen({
    super.key,
    required this.donHangId,
    required this.sanPhamId,
    required this.tenSanPham,
    this.repository,
    this.taiAnhRepository,
  });

  final int donHangId;
  final int sanPhamId;
  final String tenSanPham;
  final DanhGiaRepository? repository;
  final TaiAnhRepository? taiAnhRepository;

  @override
  State<DanhGiaScreen> createState() => _DanhGiaScreenState();
}

class _DanhGiaScreenState extends State<DanhGiaScreen> {
  static const _soAnhToiDa = 5;

  late final DanhGiaRepository _repo = widget.repository ?? DanhGiaRepository(ApiClient.macDinh);
  late final TaiAnhRepository _anhRepo = widget.taiAnhRepository ?? TaiAnhRepository(ApiClient.macDinh);
  final _formKey = GlobalKey<FormState>();
  final _noiDung = TextEditingController();
  final List<AnhDaTai> _anh = [];
  bool _khoAnhChuaSan = false;
  bool _dangTaiAnh = false;
  bool _dangGui = false;
  int? _soSao;

  @override
  void dispose() {
    _noiDung.dispose();
    super.dispose();
  }

  Future<void> _themAnh() async {
    setState(() => _dangTaiAnh = true);
    final anh = await chonVaTaiAnh(
      context,
      repository: _anhRepo,
      mucDich: 'danh-gia',
      khiChuaCauHinh: () => _khoAnhChuaSan = true,
    );
    if (!mounted) return;
    setState(() {
      _dangTaiAnh = false;
      if (anh != null) _anh.add(anh);
    });
  }

  Future<void> _gui() async {
    if (!_formKey.currentState!.validate()) return; // chưa chọn sao thì không gửi
    setState(() => _dangGui = true);
    try {
      await _repo.guiDanhGia(
        donHangId: widget.donHangId,
        sanPhamId: widget.sanPhamId,
        soSao: _soSao!,
        noiDung: _noiDung.text,
        anhUrls: [for (final a in _anh) a.url],
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
      appBar: AppBar(title: const Text('Đánh giá sản phẩm')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.tenSanPham, style: theme.textTheme.titleMedium),
              Text('Đơn #${widget.donHangId}', style: theme.textTheme.bodySmall),
              const SizedBox(height: 12),
              // FormField riêng cho số sao để dùng chung cơ chế validator của Form.
              FormField<int>(
                validator: (_) => _soSao == null ? 'Vui lòng chọn số sao' : null,
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        for (var i = 1; i <= 5; i++)
                          IconButton(
                            key: Key('sao$i'),
                            tooltip: '$i sao',
                            iconSize: 36,
                            onPressed: () {
                              setState(() => _soSao = i);
                              field.didChange(i);
                            },
                            icon: Icon((_soSao ?? 0) >= i ? Icons.star : Icons.star_border,
                                color: Colors.amber.shade700),
                          ),
                      ],
                    ),
                    if (field.hasError)
                      Text(field.errorText!, style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('oNoiDungDanhGia'),
                controller: _noiDung,
                maxLines: 4,
                maxLength: 2000,
                decoration: const InputDecoration(
                    labelText: 'Cảm nhận của bạn (không bắt buộc)', border: OutlineInputBorder()),
                validator: (v) => KiemTra.doDaiToiDa(v, 2000),
              ),
              const SizedBox(height: 8),
              Text('Ảnh thật của sản phẩm (${_anh.length}/$_soAnhToiDa)', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              if (_khoAnhChuaSan)
                Card(
                  color: theme.colorScheme.errorContainer,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Máy chủ chưa cấu hình lưu ảnh (mã CHUA_CAU_HINH_LUU_ANH). '
                        'Bạn vẫn gửi được đánh giá không kèm ảnh.'),
                  ),
                ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _anh.length; i++)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(_anh[i].bytes, width: 88, height: 88, fit: BoxFit.cover),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton.filledTonal(
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Bỏ ảnh',
                            onPressed: () => setState(() => _anh.removeAt(i)),
                            icon: const Icon(Icons.close, size: 16),
                          ),
                        ),
                      ],
                    ),
                  if (_anh.length < _soAnhToiDa && !_khoAnhChuaSan)
                    SizedBox(
                      width: 88,
                      height: 88,
                      child: OutlinedButton(
                        onPressed: _dangTaiAnh || _dangGui ? null : _themAnh,
                        child: _dangTaiAnh
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.add_a_photo_outlined),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('nutGuiDanhGia'),
                onPressed: _dangGui || _dangTaiAnh ? null : _gui,
                child: _dangGui
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_anh.isEmpty ? 'Gửi đánh giá' : 'Gửi đánh giá kèm ${_anh.length} ảnh'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
