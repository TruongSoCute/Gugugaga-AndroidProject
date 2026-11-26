import 'package:flutter/material.dart';

import 'giao_dien.dart';

/// Khối "không có dữ liệu" tối giản, thoáng, không khung thừa.
class TrangTrong extends StatelessWidget {
  const TrangTrong({super.key, required this.icon, required this.thongDiep, this.nut});

  final IconData icon;
  final String thongDiep;
  final Widget? nut;

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
              decoration: const BoxDecoration(color: OcopMau.nenNhap, shape: BoxShape.circle),
              child: Icon(icon, size: 30, color: OcopMau.chuPhu),
            ),
            const SizedBox(height: 14),
            Text(
              thongDiep,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: OcopMau.chuPhu, height: 1.45),
            ),
            if (nut != null) ...[const SizedBox(height: 16), nut!],
          ],
        ),
      ),
    );
  }
}
