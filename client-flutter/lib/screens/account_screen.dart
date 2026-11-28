import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/auth_session.dart';
import '../data/account_repository.dart';
import '../models/user.dart';
import '../widgets/theme_widgets.dart';
import '../widgets/dialogs.dart';
import 'registration_screen.dart';
import 'login_screen.dart';
import 'my_issue_reports_screen.dart';
import 'followed_suppliers_screen.dart';
import 'favorite_products_screen.dart';

/// Tài khoản tối giản chuẩn Mobbin: không gradient nặng, icon đơn sắc, bỏ mô tả thừa.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key, this.repository});

  final AccountRepository? repository;

  Future<void> _dangXuat(BuildContext context) async {
    final dongY = await xacNhan(context,
        tieuDe: 'Đăng xuất', noiDung: 'Bạn muốn đăng xuất khỏi tài khoản này?', nutDongY: 'Đăng xuất');
    if (!dongY || !context.mounted) return;
    await (repository ?? AccountRepository(ApiClient.macDinh)).dangXuat();
    if (!context.mounted) return;
    thongBao(context, 'Đã đăng xuất.');
  }

  @override
  Widget build(BuildContext context) {
    final nd = AuthSession.hienTai;
    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: nd == null ? _chuaDangNhap(context) : _daDangNhap(context, nd),
    );
  }

  Widget _chuaDangNhap(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(color: OcopColors.nenThe, shape: BoxShape.circle),
                child: const Icon(Icons.person_outline_rounded, size: 32, color: OcopColors.chuPhu),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Tài khoản OCOP',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(backgroundColor: OcopColors.nenThe),
                    onPressed: () => Navigator.push<User>(
                        context, MaterialPageRoute(builder: (_) => const RegistrationScreen())),
                    child: const Text('Đăng ký'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.push<User>(
                        context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: const Text('Đăng nhập'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _daDangNhap(BuildContext context, User nd) {
    final theme = Theme.of(context);
    void mo(Widget manHinh) => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => manHinh));
    final chuDau = nd.hoTen.isEmpty ? '?' : nd.hoTen.characters.first.toUpperCase();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(color: OcopColors.xanhNhat, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    chuDau,
                    style: const TextStyle(color: OcopColors.xanhOcop, fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nd.hoTen, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(nd.email, style: theme.textTheme.bodySmall),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: OcopColors.xanhNhat, borderRadius: BorderRadius.circular(999)),
                        child: Text(
                          '${nd.tenVaiTro}${nd.soDienThoai == null ? '' : ' · ${nd.soDienThoai}'}',
                          style: const TextStyle(color: OcopColors.xanhOcop, fontSize: 11.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (nd.laKhach)
          Card(
            child: Column(
              children: [
                _dongMenu(Icons.favorite_outline_rounded, 'Sản phẩm yêu thích', () => mo(const FavoriteProductsScreen())),
                const Divider(indent: 54),
                _dongMenu(Icons.storefront_outlined, 'Nhà cung cấp đang theo dõi', () => mo(const FollowedSuppliersScreen())),
                const Divider(indent: 54),
                _dongMenu(Icons.flag_outlined, 'Phản ánh của tôi', () => mo(const MyIssueReportsScreen())),
              ],
            ),
          ),
        if (nd.laNhaCungCap)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Gửi hồ sơ cơ sở và sản phẩm để quản trị viên duyệt. '
                'Tạo lô và mã QR do quản trị viên thực hiện trên app Admin.',
                style: TextStyle(color: OcopColors.chuPhu, height: 1.45),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            key: const Key('nutDangXuat'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: const Icon(Icons.logout_rounded, color: OcopColors.doLoi, size: 22),
            title: const Text('Đăng xuất', style: TextStyle(color: OcopColors.doLoi, fontWeight: FontWeight.w700)),
            onTap: () => _dangXuat(context),
          ),
        ),
      ],
    );
  }

  Widget _dongMenu(IconData icon, String tieuDe, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(icon, color: OcopColors.chuChinh, size: 22),
      title: Text(tieuDe, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded, color: OcopColors.chuPhu, size: 20),
      onTap: onTap,
    );
  }
}
