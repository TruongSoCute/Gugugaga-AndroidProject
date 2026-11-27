import 'package:flutter/material.dart';

import 'giao_dien.dart';

/// Ảnh tải từ URL, có loadingBuilder và errorBuilder (yêu cầu C.2 #8).
class AnhMang extends StatelessWidget {
  const AnhMang({super.key, required this.url, this.width, this.height});

  final String? url;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final khungTrong = Container(
      width: width,
      height: height,
      color: OcopMau.nenNhap,
      alignment: Alignment.center,
      child: Icon(Icons.eco_outlined, color: OcopMau.chuPhu.withValues(alpha: 0.35), size: 28),
    );
    if (url == null || url!.isEmpty) return khungTrong;
    return Image.network(
      url!,
      width: width,
      height: height,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, daTaiSan) {
        if (daTaiSan) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          child: child,
        );
      },
      loadingBuilder: (context, child, tienDo) {
        if (tienDo == null) return child;
        return Container(
          width: width,
          height: height,
          color: OcopMau.nenNhap,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stack) => khungTrong,
    );
  }
}
