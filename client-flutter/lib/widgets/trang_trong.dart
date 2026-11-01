import 'package:flutter/material.dart';

/// Khối "không có dữ liệu" có biểu tượng, lời nhắn và nút tùy chọn.
class TrangTrong extends StatelessWidget {
  const TrangTrong({super.key, required this.icon, required this.thongDiep, this.nut});

  final IconData icon;
  final String thongDiep;
  final Widget? nut;

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
            if (nut != null) ...[const SizedBox(height: 12), nut!],
          ],
        ),
      ),
    );
  }
}
