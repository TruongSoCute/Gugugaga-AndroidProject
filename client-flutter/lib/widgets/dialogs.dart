import 'package:flutter/material.dart';

/// Hộp thoại xác nhận trước thao tác xóa/hủy/đăng xuất (yêu cầu C.2 #6).
/// Trả true khi người dùng đồng ý.
Future<bool> xacNhan(
  BuildContext context, {
  required String tieuDe,
  required String noiDung,
  String nutDongY = 'Đồng ý',
  bool nguyHiem = false,
}) async {
  final kq = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(tieuDe),
      content: Text(noiDung),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
        FilledButton(
          style: nguyHiem ? FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error) : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(nutDongY),
        ),
      ],
    ),
  );
  return kq ?? false;
}

/// SnackBar ngắn gọn (ẩn cái đang hiện để không xếp hàng chờ).
void thongBao(BuildContext context, String noiDung, {SnackBarAction? action}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(noiDung), action: action));
}
