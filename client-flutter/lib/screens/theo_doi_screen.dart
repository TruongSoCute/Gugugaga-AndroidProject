import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/tuong_tac_repository.dart';
import '../models/nha_cung_cap.dart';
import '../widgets/anh_mang.dart';
import '../widgets/hop_thoai.dart';
import '../widgets/trang_thai_loi.dart';
import '../widgets/trang_trong.dart';
import 'nha_cung_cap_screen.dart';

/// Nhà cung cấp đang theo dõi (GET /theo-doi). Bỏ theo dõi có SnackBar "Hoàn tác".
class TheoDoiScreen extends StatefulWidget {
  const TheoDoiScreen({super.key, this.repository});

  final TuongTacRepository? repository;

  @override
  State<TheoDoiScreen> createState() => _TheoDoiScreenState();
}

class _TheoDoiScreenState extends State<TheoDoiScreen> {
  late final TuongTacRepository _repo = widget.repository ?? TuongTacRepository(ApiClient.macDinh);

  bool _dangTai = true;
  String? _loi;
  List<NhaCungCapTheoDoi> _ds = [];

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
      final ds = await _repo.dsTheoDoi();
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
    final ncc = _ds[viTri];
    try {
      await _repo.boTheoDoi(ncc.id);
      if (!mounted) return;
      setState(() => _ds.removeAt(viTri));
      thongBao(
        context,
        'Đã bỏ theo dõi ${ncc.ten}.',
        action: SnackBarAction(label: 'Hoàn tác', onPressed: () => _hoanTac(ncc, viTri)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      thongBao(context, e.thongDiepDayDu);
    }
  }

  Future<void> _hoanTac(NhaCungCapTheoDoi ncc, int viTri) async {
    try {
      await _repo.theoDoi(ncc.id);
      if (!mounted) return;
      setState(() => _ds.insert(viTri.clamp(0, _ds.length), ncc));
    } on ApiException catch (e) {
      if (!mounted) return;
      thongBao(context, 'Không hoàn tác được: ${e.thongDiepDayDu}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Nhà cung cấp đang theo dõi')), body: _noiDung());
  }

  Widget _noiDung() {
    if (_dangTai) return const Center(child: CircularProgressIndicator());
    if (_loi != null) return TrangThaiLoi(thongDiep: _loi!, onThuLai: _tai);
    if (_ds.isEmpty) {
      return const TrangTrong(icon: Icons.storefront_outlined, thongDiep: 'Bạn chưa theo dõi nhà cung cấp nào.');
    }
    return RefreshIndicator(
      onRefresh: _tai,
      child: ListView.builder(
        itemCount: _ds.length,
        itemBuilder: (context, i) {
          final ncc = _ds[i];
          return ListTile(
            leading: ClipRRect(
                borderRadius: BorderRadius.circular(8), child: AnhMang(url: ncc.anhCoSoUrl, width: 56, height: 56)),
            title: Text(ncc.ten),
            subtitle: Text('${ncc.tenVung} · ${ncc.soSanPham} sản phẩm'),
            trailing: TextButton(
              key: Key('boTheoDoi${ncc.id}'),
              onPressed: () => _bo(i),
              child: const Text('Bỏ theo dõi'),
            ),
            onTap: () async {
              await Navigator.push(
                  context, MaterialPageRoute<void>(builder: (_) => NhaCungCapScreen(nhaCungCapId: ncc.id)));
              if (mounted) await _tai();
            },
          );
        },
      ),
    );
  }
}
