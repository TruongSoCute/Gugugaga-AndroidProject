import 'package:flutter/material.dart';

/// Hằng màu và thành phần giao diện tối giản hiện đại (Mobbin / 21st style),
/// đồng bộ hoàn toàn với app Admin: nền trung tính sạch + 1 màu nhấn Xanh OCOP.
class OcopColors {
  OcopColors._();

  static const xanhOcop = Color(0xFF15803D);
  static const xanhNhat = Color(0xFFE7F6EC);
  static const vangOcop = Color(0xFFD97706);
  static const vangNhat = Color(0xFFFEF7E6);
  static const vangChu = Color(0xFF92400E);
  static const nenManHinh = Color(0xFFF6F7F9);
  static const nenThe = Color(0xFFFFFFFF);
  static const nenNhap = Color(0xFFF1F2F5);
  static const chuChinh = Color(0xFF111827);
  static const chuPhu = Color(0xFF6B7280);
  static const doLoi = Color(0xFFDC2626);
  static const nenDoLoi = Color(0xFFFEECEC);
}

/// Tiêu đề một mục tối giản, không thanh trang trí thừa.
class OcopSectionTitle extends StatelessWidget {
  const OcopSectionTitle(this.tieuDe, {super.key, this.phu});

  final String tieuDe;
  final Widget? phu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              tieuDe,
              style: theme.textTheme.titleSmall?.copyWith(color: OcopColors.chuPhu, fontWeight: FontWeight.w700),
            ),
          ),
          ?phu,
        ],
      ),
    );
  }
}
