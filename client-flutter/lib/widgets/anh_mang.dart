import 'package:flutter/material.dart';

/// Ảnh tải từ URL, có loadingBuilder và errorBuilder (yêu cầu C.2 #8).
class AnhMang extends StatelessWidget {
  const AnhMang({super.key, required this.url, this.width, this.height});

  final String? url;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final mau = Theme.of(context).colorScheme.surfaceContainerHighest;
    final khungTrong = Container(
      width: width,
      height: height,
      color: mau,
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported_outlined),
    );
    if (url == null || url!.isEmpty) return khungTrong;
    return Image.network(
      url!,
      width: width,
      height: height,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, tienDo) {
        if (tienDo == null) return child;
        return Container(
          width: width,
          height: height,
          color: mau,
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
