import 'package:flutter/material.dart';

/// Nhãn trạng thái tối giản dạng pill không viền (đồng bộ với app Admin).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.nhan, required this.mau});

  final String nhan;
  final Color mau;

  /// Màu gợi ý theo mã trạng thái của backend.
  static Color mauCua(String ma) => switch (ma) {
        'CHO_XAC_NHAN' || 'CHO_DUYET' || 'MOI' => const Color(0xFFB45309),
        'DA_XAC_NHAN' || 'DANG_GIAO' || 'DANG_XU_LY' => const Color(0xFF2563EB),
        'DA_GIAO' => const Color(0xFF0F766E),
        'DA_NHAN' || 'DA_DUYET' || 'DA_XU_LY' => const Color(0xFF15803D),
        'DA_HUY' || 'TU_CHOI' || 'BAC_BO' => const Color(0xFFDC2626),
        _ => const Color(0xFF4B5563),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: mau.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        nhan,
        style: TextStyle(color: mau, fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}
