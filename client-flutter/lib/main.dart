import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/khung_chinh.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const OcopClientApp());
}

/// App Client của nhóm gugugaga: khách duyệt sản phẩm OCOP, mua hàng, truy xuất nguồn gốc theo lô;
/// nhà cung cấp gửi hồ sơ và sản phẩm chờ duyệt. Khung chính tự khôi phục phiên đăng nhập.
class OcopClientApp extends StatelessWidget {
  const OcopClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OCOP Gugugaga',
      debugShowCheckedModeBanner: false,
      theme: _xayDungGiaoDienOcop(),
      home: const KhungChinh(),
    );
  }
}

/// Thiết kế tối giản hiện đại (Mobbin / 21st style), đồng bộ hoàn toàn với app Admin:
/// 90% bảng màu trung tính sạch (#F6F7F9, #FFFFFF, #111827, #6B7280) + 1 màu nhấn Xanh OCOP (#15803D),
/// bỏ toàn bộ viền thừa, phân tầng bằng sắc độ nền và khoảng trắng, chữ Be Vietnam Pro.
ThemeData _xayDungGiaoDienOcop() {
  const xanhOcop = Color(0xFF15803D);
  const xanhNhat = Color(0xFFE7F6EC);
  const xanhTrenNhat = Color(0xFF14532D);
  const nenManHinh = Color(0xFFF6F7F9);
  const nenThe = Color(0xFFFFFFFF);
  const nenNhap = Color(0xFFF1F2F5);
  const nenNhapDam = Color(0xFFE5E7EB);
  const chuChinh = Color(0xFF111827);
  const chuPhu = Color(0xFF6B7280);
  const doLoi = Color(0xFFDC2626);
  const nenDoLoi = Color(0xFFFEECEC);

  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: xanhOcop,
    onPrimary: Colors.white,
    primaryContainer: xanhNhat,
    onPrimaryContainer: xanhTrenNhat,
    secondary: Color(0xFF374151),
    onSecondary: Colors.white,
    secondaryContainer: nenNhap,
    onSecondaryContainer: chuChinh,
    tertiary: Color(0xFFD97706),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFFEF7E6),
    onTertiaryContainer: Color(0xFF92400E),
    error: doLoi,
    onError: Colors.white,
    errorContainer: nenDoLoi,
    onErrorContainer: Color(0xFF991B1B),
    surface: nenManHinh,
    onSurface: chuChinh,
    surfaceContainerLowest: nenThe,
    surfaceContainerLow: nenNhap,
    surfaceContainer: nenNhapDam,
    surfaceContainerHigh: Color(0xFFE2E5EA),
    surfaceContainerHighest: Color(0xFFD8DCE3),
    onSurfaceVariant: chuPhu,
    outline: Color(0xFFD1D5DB),
    outlineVariant: Color(0xFFECEEF2),
    shadow: Color(0x12000000),
    scrim: Colors.black54,
    inverseSurface: chuChinh,
    onInverseSurface: Color(0xFFF9FAFB),
    inversePrimary: Color(0xFF86EFAC),
  );

  final baseText = GoogleFonts.beVietnamProTextTheme(ThemeData.light(useMaterial3: true).textTheme);
  final textTheme = baseText.copyWith(
    headlineSmall: baseText.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: chuChinh, letterSpacing: -0.4),
    titleLarge: baseText.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: chuChinh, letterSpacing: -0.3),
    titleMedium: baseText.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: chuChinh, letterSpacing: -0.2),
    titleSmall: baseText.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: chuChinh),
    bodyLarge: baseText.bodyLarge?.copyWith(color: chuChinh),
    bodyMedium: baseText.bodyMedium?.copyWith(color: chuChinh),
    bodySmall: baseText.bodySmall?.copyWith(color: chuPhu),
    labelLarge: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w600),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: nenManHinh,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: nenManHinh,
      foregroundColor: chuChinh,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 21, fontWeight: FontWeight.w700, color: chuChinh),
    ),
    // Thẻ trắng KHÔNG VIỀN, KHÔNG BÓNG THỪA
    cardTheme: CardThemeData(
      color: nenThe,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    // Ô nhập nền xám mịn KHÔNG VIỀN khi chưa focus
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: nenNhap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: xanhOcop, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: doLoi, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: doLoi, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: textTheme.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    // Nút phụ nền xám nhẹ KHÔNG VIỀN CỨNG
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: nenNhap,
        foregroundColor: chuChinh,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: xanhOcop,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 50),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: xanhOcop,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    // Chip lọc KHÔNG VIỀN: xám nhạt -> đen mực chữ trắng khi chọn
    chipTheme: ChipThemeData(
      backgroundColor: nenNhap,
      selectedColor: chuChinh,
      secondarySelectedColor: chuChinh,
      showCheckmark: false,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: textTheme.labelMedium?.copyWith(color: chuPhu, fontWeight: FontWeight.w600),
      secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: nenThe,
      surfaceTintColor: Colors.transparent,
      indicatorColor: xanhNhat,
      elevation: 0,
      height: 68,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final active = states.contains(WidgetState.selected);
        return IconThemeData(color: active ? xanhOcop : chuPhu, size: 23);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final active = states.contains(WidgetState.selected);
        return textTheme.labelSmall?.copyWith(
          color: active ? xanhOcop : chuPhu,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        );
      }),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFECEEF2), thickness: 1, space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: chuChinh,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: nenThe,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: nenThe,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _ChuyenTrangMuotBuilder(),
        TargetPlatform.iOS: _ChuyenTrangMuotBuilder(),
      },
    ),
  );
}

/// Hiệu ứng chuyển màn hình trượt nhẹ + mờ dần kiểu Material 3 Shared-Axis.
class _ChuyenTrangMuotBuilder extends PageTransitionsBuilder {
  const _ChuyenTrangMuotBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final vao = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    final lui = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(vao),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(vao),
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 0.97).animate(lui),
          child: child,
        ),
      ),
    );
  }
}
