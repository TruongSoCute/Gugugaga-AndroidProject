import 'package:flutter/material.dart';

import '../data/phien_dang_nhap.dart';
import '../models/nguoi_dung.dart';
import '../widgets/giao_dien.dart';
import '../widgets/hop_thoai.dart';
import 'dang_nhap_screen.dart';

/// Thao tác của khách (giỏ, yêu thích, đánh giá, phản ánh…) cần đăng nhập.
Future<bool> canKhach(BuildContext context, {required String lyDo}) async {
  if (!PhienDangNhap.daDangNhap) {
    final nd = await Navigator.push<NguoiDung>(
      context,
      MaterialPageRoute(builder: (_) => DangNhapScreen(lyDo: lyDo)),
    );
    if (nd == null || !context.mounted) return false;
  }
  if (PhienDangNhap.laKhach) return true;
  if (context.mounted) thongBao(context, 'Chức năng này dành cho tài khoản khách mua hàng.');
  return false;
}

/// Khối nhắc đăng nhập tối giản đặt trực tiếp trên nền, bỏ khung Card thừa.
class CanDangNhap extends StatelessWidget {
  const CanDangNhap({super.key, required this.icon, required this.thongDiep});

  final IconData icon;
  final String thongDiep;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(color: OcopMau.nenThe, shape: BoxShape.circle),
              child: Icon(icon, size: 30, color: OcopMau.chuPhu),
            ),
            const SizedBox(height: 16),
            Text(
              thongDiep,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: OcopMau.chuPhu, height: 1.45),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.push<NguoiDung>(
                context,
                MaterialPageRoute(builder: (_) => DangNhapScreen(lyDo: thongDiep)),
              ),
              child: const Text('Đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}
