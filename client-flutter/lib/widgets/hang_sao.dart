import 'package:flutter/material.dart';

/// Hiện số sao (1–5) bằng biểu tượng.
class HangSao extends StatelessWidget {
  const HangSao({super.key, required this.soSao, this.coChu, this.kichThuoc = 16});

  final int soSao;
  final String? coChu;
  final double kichThuoc;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(i <= soSao ? Icons.star : Icons.star_border, size: kichThuoc, color: Colors.amber.shade700),
        if (coChu != null) Padding(padding: const EdgeInsets.only(left: 4), child: Text(coChu!)),
      ],
    );
  }
}
