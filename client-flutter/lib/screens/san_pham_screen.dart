import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/san_pham_repository.dart';
import '../models/san_pham.dart';
import '../models/vung.dart';
import '../utils/dinh_dang.dart';
import '../widgets/anh_mang.dart';
import '../widgets/trang_thai_loi.dart';

/// Màn hình 1: duyệt sản phẩm OCOP đã được duyệt, lọc theo vùng và hạng sao
/// (chức năng bắt buộc của Client). Danh sách dùng ListView.builder tải từ API (C.2 #3)
/// và đủ 3 trạng thái: đang tải / có dữ liệu / lỗi (C.2 #7).
class SanPhamScreen extends StatefulWidget {
  const SanPhamScreen({super.key, this.repository});

  /// Cho phép truyền repository giả khi kiểm thử.
  final SanPhamRepository? repository;

  @override
  State<SanPhamScreen> createState() => _SanPhamScreenState();
}

class _SanPhamScreenState extends State<SanPhamScreen> {
  late final SanPhamRepository _repo = widget.repository ?? SanPhamRepository(ApiClient());

  List<Vung> _vung = const [];
  int? _vungId;
  int? _hangSao;

  bool _dangTai = true;
  String? _loi;
  TrangSanPham? _ketQua;

  @override
  void initState() {
    super.initState();
    _taiVung();
    _taiSanPham();
  }

  Future<void> _taiVung() async {
    try {
      final ds = await _repo.dsVung();
      if (!mounted) return; // kiểm tra mounted sau await (C.2 #9)
      setState(() => _vung = ds);
    } on ApiException {
      // Bộ lọc vùng là phụ; lỗi mạng đã hiện ở danh sách sản phẩm.
    }
  }

  Future<void> _taiSanPham() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    try {
      final kq = await _repo.dsSanPham(vungId: _vungId, hangSao: _hangSao);
      if (!mounted) return;
      setState(() {
        _ketQua = kq;
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
    return Scaffold(
      appBar: AppBar(title: const Text('Đặc sản OCOP')),
      body: Column(
        children: [
          _boLoc(),
          const Divider(height: 1),
          Expanded(child: _noiDung()),
        ],
      ),
    );
  }

  Widget _boLoc() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<int?>(
            initialValue: _vungId,
            decoration: const InputDecoration(labelText: 'Vùng nguyên liệu', isDense: true),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Tất cả vùng')),
              for (final v in _vung) DropdownMenuItem<int?>(value: v.id, child: Text(v.ten)),
            ],
            onChanged: (id) {
              setState(() => _vungId = id);
              _taiSanPham();
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final sao in const <int?>[null, 3, 4, 5])
                ChoiceChip(
                  label: Text(sao == null ? 'Mọi hạng' : '$sao sao'),
                  selected: _hangSao == sao,
                  onSelected: (_) {
                    setState(() => _hangSao = sao);
                    _taiSanPham();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _noiDung() {
    if (_dangTai) return const Center(child: CircularProgressIndicator());
    if (_loi != null) return TrangThaiLoi(thongDiep: _loi!, onThuLai: _taiSanPham);
    final ds = _ketQua?.duLieu ?? const <SanPham>[];
    if (ds.isEmpty) {
      return const Center(child: Text('Không có sản phẩm phù hợp bộ lọc.'));
    }
    return RefreshIndicator(
      onRefresh: _taiSanPham,
      child: ListView.builder(
        itemCount: ds.length,
        itemBuilder: (context, i) => _DongSanPham(sp: ds[i]),
      ),
    );
  }
}

class _DongSanPham extends StatelessWidget {
  const _DongSanPham({required this.sp});

  final SanPham sp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnhMang(url: sp.anhUrl, width: 96, height: 96),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sp.ten, style: theme.textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('${sp.tenNhaCungCap} · ${sp.tenVung}',
                      style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(DinhDang.tien(sp.gia),
                          style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
                      const Spacer(),
                      if (sp.hangSao != null) ...[
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        Text(' ${sp.hangSao} sao OCOP', style: theme.textTheme.bodySmall),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
