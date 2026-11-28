import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/api_client.dart';
import '../data/account_repository.dart';
import '../models/user.dart';
import '../utils/validation.dart';
import '../widgets/animations.dart';
import '../widgets/theme_widgets.dart';
import '../widgets/dialogs.dart';
import '../widgets/auth_frame.dart';
import 'login_screen.dart';

/// Màn hình đăng ký "OCOP Botanical Pass":
/// - 2 thẻ chọn vai trò trực quan (Khách mua ↔ Nhà cung cấp) đổi màu thẻ thông hành tức thì.
/// - Thẻ thông hành in sẵn họ tên người dùng theo thời gian thực.
/// - Thanh đo độ mạnh mật khẩu 3 nấc trực quan.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key, this.repository, this.tuDangNhap = false});

  final AccountRepository? repository;
  final bool tuDangNhap;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  late final AccountRepository _repo = widget.repository ?? AccountRepository(ApiClient.macDinh);
  final _formKey = GlobalKey<FormState>();
  final _hoTen = TextEditingController();
  final _email = TextEditingController();
  final _sdt = TextEditingController();
  final _matKhau = TextEditingController();
  final _nhapLai = TextEditingController();
  String _loai = UserRole.khach;
  bool _anMatKhau = true;
  bool _dangGui = false;
  String _tenXemTruoc = '';
  String _mkHienTai = '';

  @override
  void initState() {
    super.initState();
    _hoTen.addListener(() {
      final t = _hoTen.text.trim();
      if (t != _tenXemTruoc) setState(() => _tenXemTruoc = t);
    });
    _matKhau.addListener(() {
      if (_matKhau.text != _mkHienTai) setState(() => _mkHienTai = _matKhau.text);
    });
  }

  @override
  void dispose() {
    for (final c in [_hoTen, _email, _sdt, _matKhau, _nhapLai]) {
      c.dispose();
    }
    super.dispose();
  }

  void _chonVaiTro(String moi) {
    if (_loai == moi) return;
    HapticFeedback.selectionClick();
    setState(() => _loai = moi);
  }

  void _veDangNhap() {
    HapticFeedback.selectionClick();
    if (widget.tuDangNhap) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement<User, User>(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen(repository: widget.repository)),
      );
    }
  }

  Future<void> _dangKy() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }
    setState(() => _dangGui = true);
    try {
      final nd = await _repo.dangKy(
        email: _email.text,
        matKhau: _matKhau.text,
        hoTen: _hoTen.text,
        soDienThoai: _sdt.text,
        loaiTaiKhoan: _loai,
      );
      if (!mounted) return;
      Navigator.pop(context, nd);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _dangGui = false);
      thongBao(context, e.thongDiepDayDu);
    }
  }

  @override
  Widget build(BuildContext context) {
    final laNcc = _loai == UserRole.nhaCungCap;
    final tieuDePass = _tenXemTruoc.isEmpty
        ? (laNcc ? 'Đối tác đặc sản' : 'Thành viên mới')
        : _tenXemTruoc;

    return OcopAuthFrame(
      mauNhan: laNcc ? OcopColors.vangOcop : OcopColors.xanhOcop,
      theThongHanh: FadeIn(
        thuTu: 0,
        child: OcopPassCard(
          nhanVaiTro: laNcc ? 'ĐỐI TÁC OCOP' : 'THÀNH VIÊN',
          tieuDeChinh: tieuDePass,
          phuDe: laNcc ? 'Đăng bán & minh bạch nguồn gốc lô hàng' : 'Mua đặc sản chuẩn & quét mã truy xuất',
          icon: laNcc ? Icons.storefront_rounded : Icons.shopping_bag_rounded,
          cheDoDoiTac: laNcc,
        ),
      ),
      noiDungForm: FadeIn(
        thuTu: 1,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthModeSwitch(
                dangDangKy: true,
                khiChonDangNhap: _dangGui ? null : _veDangNhap,
                khiChonDangKy: null,
              ),
              const SizedBox(height: 14),
              // 2 thẻ vai trò trực quan đặt gọn trên 1 hàng
              Row(
                children: [
                  Expanded(
                    child: _RoleCard(
                      icon: Icons.shopping_bag_outlined,
                      tieuDe: 'Khách mua',
                      chon: !laNcc,
                      mauChon: OcopColors.xanhOcop,
                      nenChon: OcopColors.xanhNhat,
                      onTap: () => _chonVaiTro(UserRole.khach),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _RoleCard(
                      icon: Icons.storefront_outlined,
                      tieuDe: 'Nhà cung cấp',
                      chon: laNcc,
                      mauChon: OcopColors.vangChu,
                      nenChon: OcopColors.vangNhat,
                      onTap: () => _chonVaiTro(UserRole.nhaCungCap),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hoTen,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: laNcc ? 'Người quản lý' : 'Họ và tên',
                  prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                ),
                validator: (v) => Validation.batBuoc(v, 'họ tên') ?? Validation.doDaiToiDa(v, 120),
              ),
              const SizedBox(height: 11),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
                ),
                validator: Validation.email,
              ),
              const SizedBox(height: 11),
              TextFormField(
                controller: _sdt,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại (tùy chọn)',
                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                ),
                validator: (v) => Validation.soDienThoai(v, batBuoc: false),
              ),
              const SizedBox(height: 11),
              TextFormField(
                controller: _matKhau,
                obscureText: _anMatKhau,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: const Icon(Icons.key_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_anMatKhau ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                    onPressed: () => setState(() => _anMatKhau = !_anMatKhau),
                  ),
                ),
                validator: Validation.matKhau,
              ),
              PasswordStrengthBar(matKhau: _mkHienTai),
              const SizedBox(height: 11),
              TextFormField(
                controller: _nhapLai,
                obscureText: _anMatKhau,
                decoration: const InputDecoration(
                  labelText: 'Nhập lại mật khẩu',
                  prefixIcon: Icon(Icons.verified_user_outlined, size: 20),
                ),
                validator: (v) => v != _matKhau.text ? 'Mật khẩu nhập lại không khớp' : null,
                onFieldSubmitted: (_) => _dangKy(),
              ),
              const SizedBox(height: 18),
              PressFeedback(
                rungNhe: true,
                child: FilledButton(
                  style: laNcc
                      ? FilledButton.styleFrom(backgroundColor: OcopColors.chuChinh, foregroundColor: Colors.white)
                      : null,
                  onPressed: _dangGui ? null : _dangKy,
                  child: _dangGui
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Tạo tài khoản'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.tieuDe,
    required this.chon,
    required this.mauChon,
    required this.nenChon,
    required this.onTap,
  });

  final IconData icon;
  final String tieuDe;
  final bool chon;
  final Color mauChon;
  final Color nenChon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: chon ? nenChon : OcopColors.nenNhap,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: chon ? mauChon : OcopColors.chuPhu),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                tieuDe,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: chon ? FontWeight.w700 : FontWeight.w600,
                  color: chon ? mauChon : OcopColors.chuPhu,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
