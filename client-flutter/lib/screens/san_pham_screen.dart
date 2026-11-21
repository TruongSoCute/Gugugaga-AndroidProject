import 'dart:async';

import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/san_pham_repository.dart';
import '../models/san_pham.dart';
import '../models/vung.dart';
import '../utils/dinh_dang.dart';
import '../widgets/anh_mang.dart';
import '../widgets/trang_thai_loi.dart';
import 'ban_do_vung_screen.dart';
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

  /// Chờ người dùng ngừng gõ một lúc rồi mới gọi API, tránh gửi một yêu cầu cho mỗi ký tự.
  static const _thoiGianChoGo = Duration(milliseconds: 400);

  List<Vung> _vung = const [];
  int? _vungId;
  int? _hangSao;
  String? _tuKhoa;
  Timer? _henGioTim;

  /// Số thứ tự lần tải gần nhất. Phản hồi của lần tải cũ về muộn sẽ bị bỏ qua,
  /// để kết quả của từ khóa cũ không ghi đè kết quả của từ khóa mới.
  int _lanTai = 0;

  bool _dangTai = true;
  String? _loi;
  TrangSanPham? _ketQua;

  @override
  void initState() {
    super.initState();
    _taiVung();
    _taiSanPham();
  }

  @override
  void dispose() {
    _henGioTim?.cancel();
    super.dispose();
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
    final lan = ++_lanTai;
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    try {
      final kq = await _repo.dsSanPham(vungId: _vungId, hangSao: _hangSao, tuKhoa: _tuKhoa);
      if (!mounted || lan != _lanTai) return;
      setState(() {
        _ketQua = kq;
        _dangTai = false;
      });
    } on ApiException catch (e) {
      if (!mounted || lan != _lanTai) return;
      setState(() {
        _loi = e.thongDiep;
        _dangTai = false;
      });
    }
  }

  void _khiGoTuKhoa(String value) {
    _tuKhoa = value;
    _henGioTim?.cancel();
    _henGioTim = Timer(_thoiGianChoGo, _taiSanPham);
  }

  String _tenVung(int? id) {
    for (final v in _vung) {
      if (v.id == id) return v.ten;
    }
    return 'Tất cả vùng';
  }

  /// Bottom Sheet chọn vùng có ô tìm riêng, hợp với danh sách vùng dài.
  /// Lựa chọn chỉ được áp dụng khi bấm "Áp dụng"; đóng sheet thì giữ nguyên bộ lọc cũ.
  Future<void> _moBottomSheetChonVung() async {
    var tuKhoaVung = '';
    var vungDangChon = _vungId;

    final daApDung = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setStateSheet) {
            final tim = tuKhoaVung.toLowerCase();
            final vungHienThi = _vung.where((v) => v.ten.toLowerCase().contains(tim)).toList();

            Widget dongVung(int? id, String ten) => InkWell(
                  onTap: () => setStateSheet(() => vungDangChon = id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    child: Row(
                      children: [
                        Radio<int?>(value: id),
                        const SizedBox(width: 8),
                        Expanded(child: Text(ten, style: const TextStyle(fontSize: 16))),
                      ],
                    ),
                  ),
                );

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SizedBox(
                height: MediaQuery.of(sheetContext).size.height * 0.6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Chọn vùng nguyên liệu',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(sheetContext, false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Tìm vùng nguyên liệu...',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => setStateSheet(() => tuKhoaVung = value),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: RadioGroup<int?>(
                        groupValue: vungDangChon,
                        onChanged: (id) => setStateSheet(() => vungDangChon = id),
                        child: ListView(
                          children: [
                            dongVung(null, 'Tất cả vùng'),
                            for (final v in vungHienThi) dongVung(v.id, v.ten),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(sheetContext, true),
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

    if (!mounted || daApDung != true || vungDangChon == _vungId) return;
    setState(() => _vungId = vungDangChon);
    _taiSanPham();
  }

  Future<void> _moBanDoVung() async {
    final chon = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => BanDoVungScreen(
          dsVung: _vung,
          vungIdChonSan: _vungId,
          choPhepLoc: true,
        ),
      ),
    );
    if (!mounted || chon == null || chon == _vungId) return;
    setState(() => _vungId = chon);
    _taiSanPham();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặc sản OCOP'),
        actions: [
          if (_vung.any((v) => v.coToaDo))
            IconButton(
              key: const Key('nutBanDoVung'),
              tooltip: 'Bản đồ vùng nguyên liệu',
              icon: const Icon(Icons.map_outlined),
              onPressed: _moBanDoVung,
            ),
        ],
      ),
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
          // Backend tìm theo tên sản phẩm (GET /san-pham?tuKhoa=, ILIKE trên sp.ten).
          TextField(
            key: const Key('oTimSanPham'),
            decoration: const InputDecoration(
              labelText: 'Tìm theo tên sản phẩm',
              prefixIcon: Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.search,
            onChanged: _khiGoTuKhoa,
          ),
          const SizedBox(height: 8),
          InkWell(
            key: const Key('nutChonVung'),
            onTap: _moBottomSheetChonVung,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Vùng nguyên liệu',
                isDense: true,
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
              child: Text(_tenVung(_vungId), overflow: TextOverflow.ellipsis),
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
