import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/san_pham_repository.dart';
import '../models/san_pham.dart';
import '../models/vung.dart';
import '../utils/dinh_dang.dart';
import '../widgets/anh_mang.dart';
import '../widgets/trang_thai_loi.dart';
import 'chi_tiet_san_pham_screen.dart';

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
  String? _tuKhoa; //biến lưu từ khóa tìm kiếm
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
      final kq = await _repo.dsSanPham(vungId: _vungId, hangSao: _hangSao, tuKhoa: _tuKhoa);
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

  void _moBottomSheetChonVung() {
      String tuKhoaBottomSheet = '';

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateModal) {
              // Lọc danh sách vùng theo từ khóa gõ bên trong Bottom Sheet
              final vungHienThi = _vung.where((v) =>
                v.ten.toLowerCase().contains(tuKhoaBottomSheet.toLowerCase())
              ).toList();

              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 16,
                  right: 16,
                  top: 16,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề và nút đóng
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Chọn vùng nguyên liệu',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Ô tìm kiếm riêng cho danh sách vùng
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Tìm kiếm vùng nguyên liệu...',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setStateModal(() {
                            tuKhoaBottomSheet = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // Danh sách dạng dọc (vertical list) với Radio button
                      Expanded(
                        child: ListView(
                          children: [
                            RadioListTile<int?>(
                              title: const Text('Tất cả vùng'),
                              value: null,
                              groupValue: _vungId,
                              onChanged: (val) {
                                setStateModal(() {
                                  _vungId = val;
                                });
                              },
                            ),
                            for (final v in vungHienThi)
                              RadioListTile<int?>(
                                title: Text(v.ten),
                                value: v.id,
                                groupValue: _vungId,
                                onChanged: (val) {
                                  setStateModal(() {
                                    _vungId = val;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Nút "Áp dụng"
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.pop(context); // Đóng Bottom Sheet
                            setState(() {}); // Cập nhật lại UI
                            _taiSanPham(); // Gọi lại API
                          },
                          child: const Text('Áp dụng', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
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
  // Lấy tên vùng đang được chọn để hiển thị lên nút bấm mở rộng
      String tenVungHienTai = 'Tất cả vùng';
      if (_vungId != null) {
        final vungTimThay = _vung.where((v) => v.id == _vungId);
        if (vungTimThay.isNotEmpty) {
          tenVungHienTai = vungTimThay.first.ten;
        }
      }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
                      decoration: const InputDecoration(
                        labelText: 'Tìm kiếm sản phẩm, cơ sở...',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() => _tuKhoa = value);
                        _taiSanPham(); // Gọi lại API khi người dùng gõ tìm kiếm
                      },
                    ),
          const SizedBox(height: 8),
          InkWell(
                      onTap: _moBottomSheetChonVung,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Vùng nguyên liệu',
                          isDense: true,
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        child: Text(
                          tenVungHienTai,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
      child: InkWell(
        // Chạm để xem chi tiết: nhà cung cấp, chứng nhận, đánh giá; thêm vào giỏ.
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => ChiTietSanPhamScreen(sanPhamId: sp.id)),
        ),
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
      ),
    );
  }
}
