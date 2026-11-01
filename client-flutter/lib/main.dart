import 'package:flutter/material.dart';

import 'screens/khung_chinh.dart';

void main() {
  runApp(const OcopClientApp());
}

/// App Client của nhóm gugugaga: khách duyệt sản phẩm OCOP, mua hàng, truy xuất nguồn gốc theo lô;
/// nhà cung cấp gửi hồ sơ và sản phẩm chờ duyệt. Khung chính tự khôi phục phiên đăng nhập.
class OcopClientApp extends StatelessWidget {
  const OcopClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OCOP Gugugaga',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B6B3A)),
        useMaterial3: true,
      ),
      home: const KhungChinh(),
    );
  }
}
