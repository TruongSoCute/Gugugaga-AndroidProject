import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/tuong_tac_repository.dart';
import '../models/san_pham.dart';
import '../utils/dinh_dang.dart';
import '../widgets/anh_mang.dart';
import '../widgets/hop_thoai.dart';
import '../widgets/trang_thai_loi.dart';
import '../widgets/trang_trong.dart';
import 'chi_tiet_san_pham_screen.dart';

/// Sản phẩm yêu thích (GET /yeu-thich). Bỏ yêu thích có SnackBar "Hoàn tác" (PUT lại).
class YeuThichScreen extends StatefulWidget {
  const YeuThichScreen({super.key, this.repository});

  final TuongTacRepository? repository;

  @override
  State<YeuThichScreen> createState() => _YeuThichScreenState();
}

class _YeuThichScreenState extends State<YeuThichScreen> {
  late final TuongTacRepository _repo = widget.repository ?? TuongTacRepository(ApiClient.macDinh);

  bool _dangTai = true;
  String? _loi;
  List<SanPhamTomTat> _ds = [];

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
      final ds = await _repo.dsYeuThich();
      if (!mounted) return;
      setState(() {
        _ds = ds;
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

  Future<void> _bo(int viTri) async {
    final sp = _ds[viTri];
    try {
      await _repo.boYeuThich(sp.id);
      if (!mounted) return;
      setState(() => _ds.removeAt(viTri));
      thongBao(
        context,
        'Đã bỏ "${sp.ten}" khỏi yêu thích.',
        action: SnackBarAction(label: 'Hoàn tác', onPressed: () => _hoanTac(sp, viTri)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      thongBao(context, e.thongDiepDayDu);
    }
  }

  Future<void> _hoanTac(SanPhamTomTat sp, int viTri) async {
    try {
      await _repo.yeuThich(sp.id);
      if (!mounted) return;
      setState(() => _ds.insert(viTri.clamp(0, _ds.length), sp));
    } on ApiException catch (e) {
      if (!mounted) return;
      thongBao(context, 'Không hoàn tác được: ${e.thongDiepDayDu}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Sản phẩm yêu thích')), body: _noiDung());
  }

  Widget _noiDung() {
    if (_dangTai) return const Center(child: CircularProgressIndicator());
    if (_loi != null) return TrangThaiLoi(thongDiep: _loi!, onThuLai: _tai);
    if (_ds.isEmpty) {
      return const TrangTrong(icon: Icons.favorite_border, thongDiep: 'Chưa có sản phẩm yêu thích.');
    }
    return RefreshIndicator(
      onRefresh: _tai,
      child: ListView.builder(
        itemCount: _ds.length,
        itemBuilder: (context, i) {
          final sp = _ds[i];
          return ListTile(
            leading: ClipRRect(
                borderRadius: BorderRadius.circular(8), child: AnhMang(url: sp.anhUrl, width: 56, height: 56)),
            title: Text(sp.ten),
            subtitle: Text('${DinhDang.tien(sp.gia)} / ${sp.donViTinh}\n${sp.tenNhaCungCap ?? ''}'),
            isThreeLine: true,
            trailing: IconButton(
              key: Key('boYeuThich${sp.id}'),
              tooltip: 'Bỏ yêu thích',
              icon: const Icon(Icons.favorite, color: Colors.red),
              onPressed: () => _bo(i),
            ),
            onTap: () async {
              await Navigator.push(
                  context, MaterialPageRoute<void>(builder: (_) => ChiTietSanPhamScreen(sanPhamId: sp.id)));
              if (mounted) await _tai(); // có thể đã bỏ yêu thích trong trang chi tiết
            },
          );
        },
      ),
    );
  }
}
