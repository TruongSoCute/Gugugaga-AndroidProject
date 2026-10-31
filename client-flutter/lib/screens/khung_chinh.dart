import 'package:flutter/material.dart';

import 'san_pham_screen.dart';
import 'tra_cuu_screen.dart';

/// Khung ứng dụng: Scaffold + NavigationBar (yêu cầu C.2 #5).
/// IndexedStack giữ nguyên trạng thái từng tab khi chuyển qua lại.
class KhungChinh extends StatefulWidget {
  const KhungChinh({super.key});

  @override
  State<KhungChinh> createState() => _KhungChinhState();
}

class _KhungChinhState extends State<KhungChinh> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [SanPhamScreen(), TraCuuScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Sản phẩm'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Truy xuất'),
        ],
      ),
    );
  }
}
