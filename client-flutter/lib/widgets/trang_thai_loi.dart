import 'package:flutter/material.dart';

/// Khối hiển thị lỗi kèm nút Thử lại (trạng thái "lỗi" — C.2 #7).
class TrangThaiLoi extends StatelessWidget {
  const TrangThaiLoi({super.key, required this.thongDiep, required this.onThuLai, this.icon});

  final String thongDiep;
  final VoidCallback onThuLai;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon ?? Icons.cloud_off, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(thongDiep, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onThuLai, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
