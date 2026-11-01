import 'package:flutter/material.dart';

/// Nhãn trạng thái có màu (đơn hàng, duyệt, phản ánh).
class ChipTrangThai extends StatelessWidget {
  const ChipTrangThai({super.key, required this.nhan, required this.mau});

  final String nhan;
  final Color mau;

  /// Màu gợi ý theo mã trạng thái của backend.
  static Color mauCua(String ma) => switch (ma) {
        'CHO_XAC_NHAN' || 'CHO_DUYET' || 'MOI' => Colors.orange.shade700,
        'DA_XAC_NHAN' || 'DANG_GIAO' || 'DANG_XU_LY' => Colors.blue.shade700,
        'DA_GIAO' => Colors.teal.shade700,
        'DA_NHAN' || 'DA_DUYET' || 'DA_XU_LY' => Colors.green.shade700,
        'DA_HUY' || 'TU_CHOI' || 'BAC_BO' => Colors.red.shade700,
        _ => Colors.grey.shade700,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: mau.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: mau.withValues(alpha: 0.5)),
      ),
      child: Text(nhan, style: TextStyle(color: mau, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
