import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme_widgets.dart';

/// Khung xác thực độc bản "OCOP Botanical Pass":
/// - Nền đường đồng mức địa hình vùng nguyên liệu vẽ bằng [CustomPainter].
/// - Thẻ thông hành OCOP phản ứng trực tiếp khi người dùng gõ hoặc đổi vai trò.
/// - Tấm form bo tròn nổi sạch gọn phía dưới, an toàn cho cả màn hình ngắn.
class OcopAuthFrame extends StatelessWidget {
  const OcopAuthFrame({
    super.key,
    required this.theThongHanh,
    required this.noiDungForm,
    this.hanhDongGocPhai,
    this.mauNhan = OcopColors.xanhOcop,
  });

  final Widget theThongHanh;
  final Widget noiDungForm;
  final Widget? hanhDongGocPhai;
  final Color mauNhan;

  @override
  Widget build(BuildContext context) {
    final coNutQuayLai = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: OcopColors.nenManHinh,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _TerrainPainter(mauNet: mauNhan),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: math.max(0, constraints.maxHeight - 28)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          if (coNutQuayLai)
                            _FloatingRoundButton(
                              icon: Icons.arrow_back_rounded,
                              tooltip: 'Quay lại',
                              onTap: () => Navigator.of(context).maybePop(),
                            )
                          else
                            const SizedBox(width: 40, height: 40),
                          const Spacer(),
                          ?hanhDongGocPhai,
                        ],
                      ),
                      const SizedBox(height: 12),
                      theThongHanh,
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                        decoration: BoxDecoration(
                          color: OcopColors.nenThe,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x10111827),
                              blurRadius: 28,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: noiDungForm,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingRoundButton extends StatelessWidget {
  const _FloatingRoundButton({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: OcopColors.nenThe,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.arrow_back_rounded, size: 20, color: OcopColors.chuChinh),
          ),
        ),
      ),
    );
  }
}

/// Thẻ thông hành OCOP phong cách Wallet Pass:
/// đổi sắc thái theo vai trò/trạng thái bảo mật và hiển thị trực tiếp tên/tài khoản đang gõ.
class OcopPassCard extends StatelessWidget {
  const OcopPassCard({
    super.key,
    required this.nhanVaiTro,
    required this.tieuDeChinh,
    required this.phuDe,
    required this.icon,
    this.cheDoDoiTac = false,
    this.dangNhapMatKhau = false,
  });

  final String nhanVaiTro;
  final String tieuDeChinh;
  final String phuDe;
  final IconData icon;
  final bool cheDoDoiTac;
  final bool dangNhapMatKhau;

  @override
  Widget build(BuildContext context) {
    final mauBatDau = cheDoDoiTac ? const Color(0xFF1F2937) : const Color(0xFF0E4427);
    final mauKetThuc = cheDoDoiTac ? const Color(0xFF111827) : const Color(0xFF15803D);
    final mauNhan = cheDoDoiTac ? const Color(0xFFF59E0B) : const Color(0xFF86EFAC);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [mauBatDau, mauKetThuc],
        ),
        boxShadow: [
          BoxShadow(
            color: mauKetThuc.withValues(alpha: 0.24),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _PassPatternPainter(mauNet: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_rounded, size: 12, color: mauNhan),
                                  const SizedBox(width: 4),
                                  Text(
                                    nhanVaiTro,
                                    style: TextStyle(
                                      color: mauNhan,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (dangNhapMatKhau) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.shield_rounded, size: 14, color: mauNhan),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          switchInCurve: Curves.easeOutCubic,
                          child: Align(
                            key: ValueKey<String>(tieuDeChinh),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              tieuDeChinh,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          phuDe,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        dangNhapMatKhau ? Icons.lock_rounded : icon,
                        key: ValueKey<bool>(dangNhapMatKhau),
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút chuyển 2 chế độ Đăng nhập / Đăng ký dạng viên thuốc trượt mượt.
class AuthModeSwitch extends StatelessWidget {
  const AuthModeSwitch({
    super.key,
    required this.dangDangKy,
    required this.khiChonDangNhap,
    required this.khiChonDangKy,
  });

  final bool dangDangKy;
  final VoidCallback? khiChonDangNhap;
  final VoidCallback? khiChonDangKy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: OcopColors.nenNhap,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _AuthModeButton(
              nhan: 'Đăng nhập',
              chon: !dangDangKy,
              onTap: khiChonDangNhap,
            ),
          ),
          Expanded(
            child: _AuthModeButton(
              nhan: 'Đăng ký',
              chon: dangDangKy,
              onTap: khiChonDangKy,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthModeButton extends StatelessWidget {
  const _AuthModeButton({required this.nhan, required this.chon, required this.onTap});

  final String nhan;
  final bool chon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: chon ? OcopColors.nenThe : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: chon
              ? const [BoxShadow(color: Color(0x12111827), blurRadius: 8, offset: Offset(0, 2))]
              : null,
        ),
        child: Text(
          nhan,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: chon ? FontWeight.w700 : FontWeight.w500,
            color: chon ? OcopColors.chuChinh : OcopColors.chuPhu,
          ),
        ),
      ),
    );
  }
}

/// Thanh đo độ mạnh mật khẩu 3 nấc trực quan thay cho dòng chữ tĩnh.
class PasswordStrengthBar extends StatelessWidget {
  const PasswordStrengthBar({super.key, required this.matKhau});

  final String matKhau;

  int _tinhMuc() {
    if (matKhau.isEmpty) return 0;
    var diem = 1;
    if (matKhau.length >= 8) diem++;
    if (matKhau.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(matKhau) &&
        RegExp(r'[0-9!@#\$%^&*]').hasMatch(matKhau)) {
      diem++;
    }
    return diem;
  }

  @override
  Widget build(BuildContext context) {
    final muc = _tinhMuc();
    final mau = switch (muc) {
      1 => OcopColors.doLoi,
      2 => OcopColors.vangOcop,
      3 => OcopColors.xanhOcop,
      _ => OcopColors.nenNhap,
    };
    final nhan = switch (muc) {
      0 => 'Tối thiểu 8 ký tự',
      1 => 'Yếu · Cần đủ 8 ký tự',
      2 => 'Khá ổn',
      _ => 'Mật khẩu mạnh',
    };
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 2, right: 2),
      child: Row(
        children: [
          for (var i = 1; i <= 3; i++)
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 4,
                margin: EdgeInsets.only(right: i < 3 ? 5 : 10),
                decoration: BoxDecoration(
                  color: i <= muc ? mau : OcopColors.nenNhap,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          Text(
            nhan,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: muc == 0 ? OcopColors.chuPhu : mau,
            ),
          ),
        ],
      ),
    );
  }
}

/// Vẽ đường đồng mức địa hình vùng nguyên liệu mờ thanh lịch phía nền màn xác thực.
class _TerrainPainter extends CustomPainter {
  const _TerrainPainter({required this.mauNet});

  final Color mauNet;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.75, -0.75),
        radius: 0.95,
        colors: [mauNet.withValues(alpha: 0.10), Colors.transparent],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glow);

    final net = Paint()
      ..color = mauNet.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (var i = 0; i < 6; i++) {
      final path = Path();
      final y0 = 36.0 + i * 34.0;
      path.moveTo(-20, y0 + 28);
      path.cubicTo(
        size.width * 0.28,
        y0 - 24 - i * 4,
        size.width * 0.62,
        y0 + 52 + i * 3,
        size.width + 20,
        y0 - 8,
      );
      canvas.drawPath(path, net);
    }

    final cham = Paint()..color = mauNet.withValues(alpha: 0.09);
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 6; col++) {
        canvas.drawCircle(Offset(size.width - 24 - col * 18, 28 + row * 18), 1.5, cham);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TerrainPainter oldDelegate) => oldDelegate.mauNet != mauNet;
}

class _PassPatternPainter extends CustomPainter {
  const _PassPatternPainter({required this.mauNet});

  final Color mauNet;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = mauNet
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    for (var r = 1; r <= 4; r++) {
      canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.12), r * 30.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PassPatternPainter oldDelegate) => oldDelegate.mauNet != mauNet;
}
