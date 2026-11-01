import 'package:flutter/material.dart';

import '../data/phien_dang_nhap.dart';
import '../models/nguoi_dung.dart';
import '../widgets/hop_thoai.dart';
import 'dang_nhap_screen.dart';

/// Thao tác của khách (giỏ, yêu thích, đánh giá, phản ánh…) cần đăng nhập.
/// Chưa đăng nhập thì mở màn hình đăng nhập và CHỜ KẾT QUẢ (Navigator trả kết quả), rồi quay lại
/// làm tiếp. Trả true nếu đang là khách. Xem sản phẩm và truy xuất thì không cần gọi hàm này.
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

/// Khối nhắc đăng nhập cho tab cần tài khoản (giỏ hàng, đơn hàng) khi đang là khách vãng lai.
class CanDangNhap extends StatelessWidget {
  const CanDangNhap({super.key, required this.icon, required this.thongDiep});

  final IconData icon;
  final String thongDiep;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(thongDiep, textAlign: TextAlign.center),
            const SizedBox(height: 12),
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
