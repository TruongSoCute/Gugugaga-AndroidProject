import 'dart:async';

import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/phien_dang_nhap.dart';
import '../data/tai_khoan_repository.dart';
import '../models/nguoi_dung.dart';
import 'dang_nhap_screen.dart';
import 'don_hang_screen.dart';
import 'gio_hang_screen.dart';
import 'ho_so_ncc_screen.dart';
import 'san_pham_cua_toi_screen.dart';
import 'san_pham_screen.dart';
import 'tai_khoan_screen.dart';
import 'tra_cuu_screen.dart';
import 'yeu_cau_dang_nhap.dart';

/// Khung ứng dụng: Scaffold + NavigationBar (yêu cầu C.2 #5).
///
/// - Khách (và người chưa đăng nhập): Sản phẩm, Truy xuất, Giỏ hàng, Đơn hàng, Tài khoản.
///   Xem sản phẩm và truy xuất không cần đăng nhập.
/// - Nhà cung cấp: Hồ sơ, Sản phẩm của tôi, Truy xuất, Tài khoản (không có giỏ/đơn).
///
/// Khung nghe [PhienDangNhap]: đổi tài khoản thì dựng lại bộ tab; nhận 401 (hết phiên) thì
/// đóng các màn hình đang mở và đưa về màn hình đăng nhập.
class KhungChinh extends StatefulWidget {
  const KhungChinh({super.key, this.taiKhoanRepository});

  final TaiKhoanRepository? taiKhoanRepository;

  @override
  State<KhungChinh> createState() => _KhungChinhState();
}

class _KhungChinhState extends State<KhungChinh> {
  late final TaiKhoanRepository _repo = widget.taiKhoanRepository ?? TaiKhoanRepository(ApiClient.macDinh);
  StreamSubscription<NguoiDung?>? _ngheThayDoi;
  StreamSubscription<void>? _ngheHetPhien;

  bool _daKhoiPhuc = false;
  int _tab = 0;
  NguoiDung? _nguoiDung;

  /// Đếm số lần chọn tab giỏ/đơn: đổi key để tải lại dữ liệu mới mỗi lần mở tab.
  int _lanMoGio = 0;
  int _lanMoDon = 0;

  @override
  void initState() {
    super.initState();
    _ngheThayDoi = PhienDangNhap.thayDoi.listen((nd) {
      if (!mounted) return;
      setState(() {
        if (nd?.id != _nguoiDung?.id || nd?.vaiTro != _nguoiDung?.vaiTro) _tab = 0;
        _nguoiDung = nd;
      });
    });
    _ngheHetPhien = PhienDangNhap.hetPhien.listen((_) => _veDangNhap());
    _khoiPhuc();
  }

  Future<void> _khoiPhuc() async {
    final nd = await _repo.khoiPhucPhien(); // đọc token đã lưu, không cần mạng
    if (!mounted) return;
    setState(() {
      _nguoiDung = nd;
      _daKhoiPhuc = true;
    });
    unawaited(_repo.kiemTraPhien()); // hỏi GET /auth/toi xem token còn hạn
  }

  void _veDangNhap() {
    if (!mounted) return;
    final nav = Navigator.of(context);
    nav.popUntil((r) => r.isFirst);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.')));
    nav.push(MaterialPageRoute<NguoiDung>(
        builder: (_) => const DangNhapScreen(lyDo: 'Phiên đăng nhập đã hết hạn.')));
  }

  @override
  void dispose() {
    _ngheThayDoi?.cancel();
    _ngheHetPhien?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_daKhoiPhuc) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final laNcc = _nguoiDung?.laNhaCungCap ?? false;
    final tabs = laNcc ? _tabNhaCungCap() : _tabKhach();
    final tab = _tab.clamp(0, tabs.length - 1);
    return Scaffold(
      body: KeyedSubtree(
        // Đổi tài khoản thì dựng lại toàn bộ tab (giỏ/đơn của người trước không còn).
        key: ValueKey('${_nguoiDung?.id}-${_nguoiDung?.vaiTro}'),
        child: IndexedStack(index: tab, children: [for (final t in tabs) t.manHinh]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() {
          _tab = i;
          if (tabs[i].ma == 'gio') _lanMoGio++;
          if (tabs[i].ma == 'don') _lanMoDon++;
        }),
        destinations: [for (final t in tabs) t.dich],
      ),
    );
  }

  List<_Tab> _tabKhach() {
    final daDangNhap = _nguoiDung != null;
    return [
      const _Tab('sp', SanPhamScreen(),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Sản phẩm')),
      const _Tab('tc', TraCuuScreen(), NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Truy xuất')),
      _Tab(
        'gio',
        daDangNhap
            ? GioHangScreen(key: ValueKey('gio$_lanMoGio'))
            : const CanDangNhap(icon: Icons.shopping_cart_outlined, thongDiep: 'Đăng nhập để xem giỏ hàng.'),
        const NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined), selectedIcon: Icon(Icons.shopping_cart), label: 'Giỏ hàng'),
      ),
      _Tab(
        'don',
        daDangNhap
            ? DonHangScreen(key: ValueKey('don$_lanMoDon'))
            : const CanDangNhap(icon: Icons.receipt_long_outlined, thongDiep: 'Đăng nhập để theo dõi đơn hàng.'),
        const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Đơn hàng'),
      ),
      const _Tab('tk', TaiKhoanScreen(),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Tài khoản')),
    ];
  }

  List<_Tab> _tabNhaCungCap() => const [
        _Tab('hs', HoSoNccScreen(),
            NavigationDestination(icon: Icon(Icons.store_outlined), selectedIcon: Icon(Icons.store), label: 'Hồ sơ')),
        _Tab('spct', SanPhamCuaToiScreen(),
            NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Sản phẩm')),
        _Tab('tc', TraCuuScreen(), NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Truy xuất')),
        _Tab('tk', TaiKhoanScreen(),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Tài khoản')),
      ];
}

class _Tab {
  const _Tab(this.ma, this.manHinh, this.dich);

  final String ma;
  final Widget manHinh;
  final NavigationDestination dich;
}
