import 'package:flutter/material.dart';

import 'giao_dien.dart';

/// Khối hiển thị lỗi tối giản kèm nút Thử lại (trạng thái "lỗi" — C.2 #7).
class TrangThaiLoi extends StatelessWidget {
  const TrangThaiLoi({super.key, required this.thongDiep, required this.onThuLai, this.icon});

  final String thongDiep;
  final VoidCallback onThuLai;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: OcopMau.nenDoLoi, shape: BoxShape.circle),
              child: Icon(icon ?? Icons.cloud_off_rounded, size: 30, color: OcopMau.doLoi),
            ),
            const SizedBox(height: 14),
            Text(
              thongDiep,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: OcopMau.chuPhu),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onThuLai,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
