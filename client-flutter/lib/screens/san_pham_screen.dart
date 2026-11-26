import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/api_client.dart';
import '../data/san_pham_repository.dart';
import '../models/san_pham.dart';
import '../models/vung.dart';
import '../utils/dinh_dang.dart';
import '../widgets/anh_mang.dart';
import '../widgets/chuyen_dong.dart';
import '../widgets/giao_dien.dart';
import '../widgets/trang_thai_loi.dart';
import '../widgets/trang_trong.dart';
import 'ban_do_vung_screen.dart';
import 'chi_tiet_san_pham_screen.dart';

/// Màn hình 1: duyệt sản phẩm OCOP đã được duyệt, lọc theo vùng và hạng sao.
/// Thiết kế tối giản chuẩn Mobbin / 21st: không viền, thoáng rộng, chỉ hiện đúng thông tin cần thiết.
class SanPhamScreen extends StatefulWidget {
  const SanPhamScreen({super.key, this.repository});

  final SanPhamRepository? repository;

  @override
  State<SanPhamScreen> createState() => _SanPhamScreenState();
}

class _SanPhamScreenState extends State<SanPhamScreen> {
  late final SanPhamRepository _repo = widget.repository ?? SanPhamRepository(ApiClient());

  static const _thoiGianChoGo = Duration(milliseconds: 400);

  List<Vung> _vung = const [];
  int? _vungId;
  int? _hangSao;
  String? _tuKhoa;
  Timer? _henGioTim;
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
      if (!mounted) return;
      setState(() => _vung = ds);
    } on ApiException {
      // Bộ lọc vùng là phụ.
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

  Future<void> _moBottomSheetChonVung() async {
    var tuKhoaVung = '';
    var vungDangChon = _vungId;

    final daApDung = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setStateSheet) {
            final tim = tuKhoaVung.toLowerCase();
            final vungHienThi = _vung.where((v) => v.ten.toLowerCase().contains(tim)).toList();

            Widget dongVung(int? id, String ten) {
              final dangChon = vungDangChon == id;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setStateSheet(() => vungDangChon = id),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: dangChon ? OcopMau.xanhNhat : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Radio<int?>(value: id),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          ten,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: dangChon ? FontWeight.w700 : FontWeight.w500,
                            color: dangChon ? OcopMau.xanhOcop : OcopMau.chuChinh,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 4,
              ),
              child: SizedBox(
                height: MediaQuery.of(sheetContext).size.height * 0.62,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Chọn vùng nguyên liệu', style: Theme.of(sheetContext).textTheme.titleLarge),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(sheetContext, false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Tìm vùng nguyên liệu...',
                        prefixIcon: Icon(Icons.search_rounded),
                        isDense: true,
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
                      child: FilledButton(
                        onPressed: () => Navigator.pop(sheetContext, true),
                        child: const Text('Áp dụng'),
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
        builder: (_) => BanDoVungScreen(dsVung: _vung, vungIdChonSan: _vungId, choPhepLoc: true),
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
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                key: const Key('nutBanDoVung'),
                tooltip: 'Bản đồ vùng nguyên liệu',
                style: IconButton.styleFrom(backgroundColor: OcopMau.nenThe, foregroundColor: OcopMau.chuChinh),
                icon: const Icon(Icons.map_outlined, size: 20),
                onPressed: _moBanDoVung,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _boLoc(),
          Expanded(child: _noiDung()),
        ],
      ),
    );
  }

  Widget _boLoc() {
    final daChonVung = _vungId != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const Key('oTimSanPham'),
            decoration: InputDecoration(
              hintText: 'Tìm đặc sản...',
              prefixIcon: const Icon(Icons.search_rounded, color: OcopMau.chuPhu, size: 20),
              isDense: true,
              filled: true,
              fillColor: OcopMau.nenThe,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: OcopMau.xanhOcop, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            textInputAction: TextInputAction.search,
            onChanged: _khiGoTuKhoa,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                InkWell(
                  key: const Key('nutChonVung'),
                  borderRadius: BorderRadius.circular(999),
                  onTap: _moBottomSheetChonVung,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: daChonVung ? OcopMau.chuChinh : OcopMau.nenThe,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: daChonVung ? Colors.white : OcopMau.chuPhu,
                        ),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 136),
                          child: Text(
                            _tenVung(_vungId),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: daChonVung ? Colors.white : OcopMau.chuChinh,
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: daChonVung ? Colors.white : OcopMau.chuPhu,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                for (final sao in const <int?>[null, 3, 4, 5])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(
                        sao == null ? 'Mọi hạng' : '$sao sao',
                        softWrap: false,
                        overflow: TextOverflow.visible,
                      ),
                      selected: _hangSao == sao,
                      backgroundColor: OcopMau.nenThe,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        setState(() => _hangSao = sao);
                        _taiSanPham();
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _noiDung() {
    if (_dangTai) {
      return const ChuyenTrangThaiMuot(khoa: 'tai', child: Center(child: CircularProgressIndicator()));
    }
    if (_loi != null) {
      return ChuyenTrangThaiMuot(
        khoa: 'loi',
        child: TrangThaiLoi(thongDiep: _loi!, onThuLai: _taiSanPham),
      );
    }
    final ds = _ketQua?.duLieu ?? const <SanPham>[];
    if (ds.isEmpty) {
      return const ChuyenTrangThaiMuot(
        khoa: 'trong',
        child: TrangTrong(icon: Icons.search_off_rounded, thongDiep: 'Không có sản phẩm phù hợp bộ lọc.'),
      );
    }
    return ChuyenTrangThaiMuot(
      khoa: 'ds-${_vungId ?? 'all'}-${_hangSao ?? 'all'}-${ds.length}',
      child: RefreshIndicator(
        onRefresh: _taiSanPham,
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.72,
          ),
          itemCount: ds.length,
          itemBuilder: (context, i) => HienLenMuot(thuTu: i, child: _TheSanPham(sp: ds[i])),
        ),
      ),
    );
  }
}

class _TheSanPham extends StatelessWidget {
  const _TheSanPham({required this.sp});

  final SanPham sp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NhanNhe(
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => ChiTietSanPhamScreen(sanPhamId: sp.id)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 12,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'anh-sp-${sp.id}',
                      child: AnhMang(url: sp.anhUrl, width: double.infinity, height: double.infinity),
                    ),
                    if (sp.hangSao != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xE6FFFFFF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 13, color: OcopMau.vangOcop),
                              const SizedBox(width: 2),
                              Text(
                                '${sp.hangSao}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: OcopMau.chuChinh,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 9,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sp.ten,
                        style: theme.textTheme.titleSmall?.copyWith(fontSize: 13.5, height: 1.25),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 12, color: OcopMau.chuPhu),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              sp.tenVung,
                              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: Text(
                              DinhDang.tien(sp.gia),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontSize: 14.5,
                                color: OcopMau.chuChinh,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (sp.donViTinh.isNotEmpty)
                            Text(
                              '/${sp.donViTinh}',
                              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
