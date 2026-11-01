import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/phien_dang_nhap.dart';
import '../data/tai_khoan_repository.dart';
import '../models/nguoi_dung.dart';
import '../widgets/hop_thoai.dart';
import 'dang_ky_screen.dart';
import 'dang_nhap_screen.dart';
import 'phan_anh_cua_toi_screen.dart';
import 'theo_doi_screen.dart';
import 'yeu_thich_screen.dart';

/// Tài khoản: thông tin người dùng, lối vào Yêu thích / Đang theo dõi / Phản ánh (khách),
/// đăng xuất có hộp thoại xác nhận. Chưa đăng nhập thì hiện nút đăng nhập/đăng ký.
class TaiKhoanScreen extends StatelessWidget {
  const TaiKhoanScreen({super.key, this.repository});

  final TaiKhoanRepository? repository;

  Future<void> _dangXuat(BuildContext context) async {
    final dongY = await xacNhan(context,
        tieuDe: 'Đăng xuất', noiDung: 'Bạn muốn đăng xuất khỏi tài khoản này?', nutDongY: 'Đăng xuất');
    if (!dongY || !context.mounted) return;
    await (repository ?? TaiKhoanRepository(ApiClient.macDinh)).dangXuat();
    if (!context.mounted) return;
    thongBao(context, 'Đã đăng xuất.');
  }

  @override
  Widget build(BuildContext context) {
    final nd = PhienDangNhap.hienTai;
    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: nd == null ? _chuaDangNhap(context) : _daDangNhap(context, nd),
    );
  }

  Widget _chuaDangNhap(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.person_outline, size: 72, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            const Text(
              'Bạn đang xem với tư cách khách vãng lai. Xem sản phẩm và truy xuất nguồn gốc không cần đăng nhập.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.push<NguoiDung>(
                  context, MaterialPageRoute(builder: (_) => const DangNhapScreen())),
              child: const Text('Đăng nhập'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.push<NguoiDung>(
                  context, MaterialPageRoute(builder: (_) => const DangKyScreen())),
              child: const Text('Đăng ký tài khoản'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _daDangNhap(BuildContext context, NguoiDung nd) {
    final theme = Theme.of(context);
    void mo(Widget manHinh) => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => manHinh));
    return ListView(
      children: [
        ListTile(
          leading: CircleAvatar(
            radius: 24,
            child: Text(nd.hoTen.isEmpty ? '?' : nd.hoTen.characters.first.toUpperCase()),
          ),
          title: Text(nd.hoTen, style: theme.textTheme.titleMedium),
          subtitle: Text('${nd.email}\n${nd.tenVaiTro}${nd.soDienThoai == null ? '' : ' · ${nd.soDienThoai}'}'),
          isThreeLine: true,
        ),
        const Divider(),
        if (nd.laKhach) ...[
          ListTile(
            leading: const Icon(Icons.favorite_outline),
            title: const Text('Sản phẩm yêu thích'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => mo(const YeuThichScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: const Text('Nhà cung cấp đang theo dõi'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => mo(const TheoDoiScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.report_outlined),
            title: const Text('Phản ánh của tôi'),
            subtitle: const Text('Hàng nghi giả, sai mô tả và kết quả xử lý'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => mo(const PhanAnhCuaToiScreen()),
          ),
          const Divider(),
        ],
        if (nd.laNhaCungCap)
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Tài khoản nhà cung cấp'),
            subtitle: Text('Gửi hồ sơ cơ sở và sản phẩm để quản trị viên duyệt. '
                'Tạo lô và mã QR do quản trị viên thực hiện trên app Admin.'),
          ),
        ListTile(
          key: const Key('nutDangXuat'),
          leading: Icon(Icons.logout, color: theme.colorScheme.error),
          title: Text('Đăng xuất', style: TextStyle(color: theme.colorScheme.error)),
          onTap: () => _dangXuat(context),
        ),
      ],
    );
  }
}
