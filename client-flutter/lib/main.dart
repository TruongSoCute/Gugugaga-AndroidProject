import 'package:flutter/material.dart';

import 'screens/khung_chinh.dart';

void main() {
  runApp(const OcopClientApp());
}

/// App Client của nhóm gugugaga: khách duyệt sản phẩm OCOP và truy xuất nguồn gốc theo lô.
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
