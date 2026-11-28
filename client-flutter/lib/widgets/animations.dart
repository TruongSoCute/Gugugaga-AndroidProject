import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bộ thành phần chuyển động chuẩn từ lớn đến nhỏ cho app Client:
/// - [FadeIn]: hiệu ứng đổ tầng (staggered entrance) mượt, hữu hạn (an toàn với pumpAndSettle).
/// - [PressFeedback]: phản hồi nén nhẹ lò xo (micro press-scale) khi chạm thẻ/nút.
/// - [AnimatedNumber]: bộ đếm số / giá tiền trượt dọc khi thay đổi giá trị.
/// - [AnimatedStateTransition]: chuyển mượt giữa các trạng thái đang tải / có dữ liệu / trống / lỗi.
class FadeIn extends StatelessWidget {
  const FadeIn({
    super.key,
    required this.child,
    this.thuTu = 0,
    this.dichDoc = 14,
  });

  final Widget child;
  final int thuTu;
  final double dichDoc;

  @override
  Widget build(BuildContext context) {
    final buoc = thuTu.clamp(0, 6);
    final treMs = buoc * 42;
    const thoiLuongChinhMs = 280;
    final tongMs = thoiLuongChinhMs + treMs;
    final batDau = treMs / tongMs;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: tongMs),
      curve: Interval(batDau, 1, curve: Curves.easeOutCubic),
      child: child,
      builder: (context, t, con) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * dichDoc),
          child: con,
        ),
      ),
    );
  }
}

/// Phản hồi xúc giác + nén nhẹ khi chạm vào thẻ hoặc nút chính.
/// Dùng [Listener] để không tranh chấp gesture với [InkWell] / [FilledButton].
class PressFeedback extends StatefulWidget {
  const PressFeedback({
    super.key,
    required this.child,
    this.tiLeNhan = 0.97,
    this.rungNhe = false,
  });

  final Widget child;
  final double tiLeNhan;
  final bool rungNhe;

  @override
  State<PressFeedback> createState() => _PressFeedbackState();
}

class _PressFeedbackState extends State<PressFeedback> {
  bool _dangNhan = false;

  void _datTrangThai(bool nhan) {
    if (_dangNhan == nhan) return;
    setState(() => _dangNhan = nhan);
    if (nhan && widget.rungNhe) {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _datTrangThai(true),
      onPointerUp: (_) => _datTrangThai(false),
      onPointerCancel: (_) => _datTrangThai(false),
      child: AnimatedScale(
        scale: _dangNhan ? widget.tiLeNhan : 1,
        duration: Duration(milliseconds: _dangNhan ? 95 : 180),
        curve: _dangNhan ? Curves.easeOut : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

/// Hiệu ứng trượt dọc mượt cho số lượng hoặc tổng tiền khi thay đổi.
class AnimatedNumber extends StatelessWidget {
  const AnimatedNumber({
    super.key,
    required this.giaTri,
    required this.text,
    this.style,
    this.textAlign,
  });

  final Object giaTri;
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.25),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: Text(
        text,
        key: ValueKey<Object>(giaTri),
        style: style,
        textAlign: textAlign,
      ),
    );
  }
}

/// Chuyển trạng thái tải / dữ liệu / trống / lỗi nhẹ nhàng thay vì giật khung.
class AnimatedStateTransition extends StatelessWidget {
  const AnimatedStateTransition({
    super.key,
    required this.khoa,
    required this.child,
  });

  final Object khoa;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(key: ValueKey<Object>(khoa), child: child),
    );
  }
}
