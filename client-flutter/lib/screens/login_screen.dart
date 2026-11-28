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
import 'registration_screen.dart';

/// Màn hình đăng nhập phong cách "OCOP Botanical Pass":
/// nền đường đồng mức địa hình + thẻ thông hành phản hồi trực tiếp khi nhập email/mật khẩu.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.repository, this.lyDo});

  final AccountRepository? repository;
  final String? lyDo;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AccountRepository _repo = widget.repository ?? AccountRepository(ApiClient.macDinh);
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _matKhau = TextEditingController();
  final _focusMatKhau = FocusNode();
  bool _anMatKhau = true;
  bool _dangGui = false;
  bool _dangGoMatKhau = false;
  String _tenHienThi = 'Chào mừng trở lại';

  @override
  void initState() {
    super.initState();
    _email.addListener(_capNhatThe);
    _focusMatKhau.addListener(_capNhatFocus);
  }

  void _capNhatThe() {
    final raw = _email.text.trim();
    final ten = raw.isEmpty ? 'Chào mừng trở lại' : raw.split('@').first;
    if (ten != _tenHienThi) setState(() => _tenHienThi = ten);
  }

  void _capNhatFocus() {
    if (_dangGoMatKhau != _focusMatKhau.hasFocus) {
      setState(() => _dangGoMatKhau = _focusMatKhau.hasFocus);
    }
  }

  @override
  void dispose() {
    _email.removeListener(_capNhatThe);
    _focusMatKhau.removeListener(_capNhatFocus);
    _email.dispose();
    _matKhau.dispose();
    _focusMatKhau.dispose();
    super.dispose();
  }

  Future<void> _dangNhap() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }
    setState(() => _dangGui = true);
    try {
      final nd = await _repo.dangNhap(email: _email.text, matKhau: _matKhau.text);
      if (!mounted) return;
      Navigator.pop(context, nd);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _dangGui = false);
      thongBao(context, e.thongDiepDayDu);
    }
  }

  Future<void> _moDangKy() async {
    HapticFeedback.selectionClick();
    final nd = await Navigator.push<User>(
      context,
      MaterialPageRoute(builder: (_) => RegistrationScreen(repository: widget.repository, tuDangNhap: true)),
    );
    if (!mounted) return;
    if (nd != null) Navigator.pop(context, nd);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OcopAuthFrame(
      theThongHanh: FadeIn(
        thuTu: 0,
        child: OcopPassCard(
          nhanVaiTro: 'OCOP PASS',
          tieuDeChinh: _tenHienThi,
          phuDe: _dangGoMatKhau ? 'Đang xác thực bảo mật' : 'Sàn đặc sản chuẩn nguồn gốc',
          icon: Icons.eco_rounded,
          dangNhapMatKhau: _dangGoMatKhau,
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
                dangDangKy: false,
                khiChonDangNhap: null,
                khiChonDangKy: _dangGui ? null : _moDangKy,
              ),
              if (widget.lyDo != null)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: OcopColors.vangNhat,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.lyDo!,
                    style: theme.textTheme.bodySmall?.copyWith(color: OcopColors.vangChu, fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('oEmail'),
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
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('oMatKhau'),
                controller: _matKhau,
                focusNode: _focusMatKhau,
                obscureText: _anMatKhau,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: const Icon(Icons.key_rounded, size: 20),
                  suffixIcon: IconButton(
                    tooltip: _anMatKhau ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                    icon: Icon(_anMatKhau ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                    onPressed: () => setState(() => _anMatKhau = !_anMatKhau),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu' : null,
                onFieldSubmitted: (_) => _dangNhap(),
              ),
              const SizedBox(height: 18),
              PressFeedback(
                rungNhe: true,
                child: FilledButton(
                  key: const Key('nutDangNhap'),
                  onPressed: _dangGui ? null : _dangNhap,
                  child: _dangGui
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Đăng nhập'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
