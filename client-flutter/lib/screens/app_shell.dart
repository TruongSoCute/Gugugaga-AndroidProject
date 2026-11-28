import 'dart:async';

import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/auth_session.dart';
import '../data/account_repository.dart';
import '../models/user.dart';
import '../widgets/floating_navigation_bar.dart';
import 'login_screen.dart';
import 'orders_screen.dart';
import 'cart_screen.dart';
import 'supplier_profile_screen.dart';
import 'my_products_screen.dart';
import 'product_list_screen.dart';
import 'account_screen.dart';
import 'traceability_lookup_screen.dart';
import 'require_login.dart';

/// Khung ứng dụng: Scaffold + NavigationBar (yêu cầu C.2 #5).
///
/// - Khách (và người chưa đăng nhập): Sản phẩm, Truy xuất, Giỏ hàng, Đơn hàng, Tài khoản.
///   Xem sản phẩm và truy xuất không cần đăng nhập.
/// - Nhà cung cấp: Hồ sơ, Sản phẩm của tôi, Truy xuất, Tài khoản (không có giỏ/đơn).
///
/// Khung nghe [AuthSession]: đổi tài khoản thì dựng lại bộ tab; nhận 401 (hết phiên) thì
/// đóng các màn hình đang mở và đưa về màn hình đăng nhập.
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.taiKhoanRepository});

  final AccountRepository? taiKhoanRepository;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final AccountRepository _repo = widget.taiKhoanRepository ?? AccountRepository(ApiClient.macDinh);
  StreamSubscription<User?>? _ngheThayDoi;
  StreamSubscription<void>? _ngheHetPhien;

  bool _daKhoiPhuc = false;
  int _tab = 0;
  User? _nguoiDung;

  /// Đếm số lần chọn tab giỏ/đơn: đổi key để tải lại dữ liệu mới mỗi lần mở tab.
  int _lanMoGio = 0;
  int _lanMoDon = 0;

  @override
  void initState() {
    super.initState();
    _ngheThayDoi = AuthSession.thayDoi.listen((nd) {
      if (!mounted) return;
      setState(() {
        if (nd?.id != _nguoiDung?.id || nd?.vaiTro != _nguoiDung?.vaiTro) _tab = 0;
        _nguoiDung = nd;
      });
    });
    _ngheHetPhien = AuthSession.hetPhien.listen((_) => _veDangNhap());
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
    nav.push(MaterialPageRoute<User>(
        builder: (_) => const LoginScreen(lyDo: 'Phiên đăng nhập đã hết hạn.')));
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
        child: TweenAnimationBuilder<double>(
          key: ValueKey('tab-$tab'),
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          builder: (context, t, con) => Opacity(
            opacity: 0.85 + 0.15 * t,
            child: Transform.translate(offset: Offset(0, (1 - t) * 6), child: con),
          ),
          child: IndexedStack(index: tab, children: [for (final t in tabs) t.manHinh]),
        ),
      ),
      bottomNavigationBar: FloatingNavigationBar(
        selectedIndex: tab,
        onSelected: (i) => setState(() {
          _tab = i;
          if (tabs[i].ma == 'gio') _lanMoGio++;
          if (tabs[i].ma == 'don') _lanMoDon++;
        }),
        items: [for (final t in tabs) t.muc],
      ),
    );
  }

  List<_Tab> _tabKhach() {
    final daDangNhap = _nguoiDung != null;
    return [
      const _Tab(
        'sp',
        ProductListScreen(),
        FloatingNavigationItem(icon: Icons.storefront_outlined, selectedIcon: Icons.storefront_rounded, label: 'Sản phẩm'),
      ),
      const _Tab(
        'tc',
        TraceabilityLookupScreen(),
        FloatingNavigationItem(icon: Icons.qr_code_scanner_rounded, selectedIcon: Icons.qr_code_scanner_rounded, label: 'Truy xuất'),
      ),
      _Tab(
        'gio',
        daDangNhap
            ? CartScreen(key: ValueKey('gio$_lanMoGio'))
            : const CanDangNhap(icon: Icons.shopping_cart_outlined, thongDiep: 'Đăng nhập để xem giỏ hàng.'),
        const FloatingNavigationItem(icon: Icons.shopping_cart_outlined, selectedIcon: Icons.shopping_cart_rounded, label: 'Giỏ hàng'),
      ),
      _Tab(
        'don',
        daDangNhap
            ? OrdersScreen(key: ValueKey('don$_lanMoDon'))
            : const CanDangNhap(icon: Icons.receipt_long_outlined, thongDiep: 'Đăng nhập để theo dõi đơn hàng.'),
        const FloatingNavigationItem(icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long_rounded, label: 'Đơn hàng'),
      ),
      const _Tab(
        'tk',
        AccountScreen(),
        FloatingNavigationItem(icon: Icons.person_outline_rounded, selectedIcon: Icons.person_rounded, label: 'Tài khoản'),
      ),
    ];
  }

  List<_Tab> _tabNhaCungCap() => const [
        _Tab(
          'hs',
          SupplierProfileScreen(),
          FloatingNavigationItem(icon: Icons.store_outlined, selectedIcon: Icons.store_rounded, label: 'Hồ sơ'),
        ),
        _Tab(
          'spct',
          MyProductsScreen(),
          FloatingNavigationItem(icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2_rounded, label: 'Sản phẩm'),
        ),
        _Tab(
          'tc',
          TraceabilityLookupScreen(),
          FloatingNavigationItem(icon: Icons.qr_code_scanner_rounded, selectedIcon: Icons.qr_code_scanner_rounded, label: 'Truy xuất'),
        ),
        _Tab(
          'tk',
          AccountScreen(),
          FloatingNavigationItem(icon: Icons.person_outline_rounded, selectedIcon: Icons.person_rounded, label: 'Tài khoản'),
        ),
      ];
}

class _Tab {
  const _Tab(this.ma, this.manHinh, this.muc);

  final String ma;
  final Widget manHinh;
  final FloatingNavigationItem muc;
}
