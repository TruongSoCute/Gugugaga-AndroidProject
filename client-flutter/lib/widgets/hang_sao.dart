import 'package:flutter/material.dart';

import 'giao_dien.dart';

/// Hiện số sao (1–5) bằng biểu tượng sao tròn màu vàng hổ phách OCOP.
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
          Icon(
            i <= soSao ? Icons.star_rounded : Icons.star_outline_rounded,
            size: kichThuoc,
            color: i <= soSao ? OcopMau.vangOcop : const Color(0xFFCBD5CB),
          ),
        if (coChu != null)
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Text(
              coChu!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: OcopMau.vangChu,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
      ],
    );
  }
}
