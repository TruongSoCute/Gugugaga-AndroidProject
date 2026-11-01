import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/tai_khoan_repository.dart';
import '../models/nguoi_dung.dart';
import '../utils/kiem_tra.dart';
import '../widgets/hop_thoai.dart';
import 'dang_ky_screen.dart';

/// Màn hình đăng nhập. Thành công thì `Navigator.pop(context, nguoiDung)`:
/// màn hình gọi tới nhận lại kết quả (Navigator trả kết quả — C.2 #2) để làm tiếp thao tác
/// đang dở (thêm vào giỏ, yêu thích…). Token được lưu bằng shared_preferences trong repository.
class DangNhapScreen extends StatefulWidget {
  const DangNhapScreen({super.key, this.repository, this.lyDo});

  final TaiKhoanRepository? repository;

  /// Vì sao cần đăng nhập (vd "Đăng nhập để thêm vào giỏ").
  final String? lyDo;

  @override
  State<DangNhapScreen> createState() => _DangNhapScreenState();
}

class _DangNhapScreenState extends State<DangNhapScreen> {
  late final TaiKhoanRepository _repo = widget.repository ?? TaiKhoanRepository(ApiClient.macDinh);
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _matKhau = TextEditingController();
  bool _anMatKhau = true;
  bool _dangGui = false;

  @override
  void dispose() {
    _email.dispose();
    _matKhau.dispose();
    super.dispose();
  }

  Future<void> _dangNhap() async {
    if (!_formKey.currentState!.validate()) return; // chặn gửi khi form sai
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
    final nd = await Navigator.push<NguoiDung>(
      context,
      MaterialPageRoute(builder: (_) => DangKyScreen(repository: widget.repository)),
    );
    if (!mounted) return;
    if (nd != null) Navigator.pop(context, nd); // đăng ký xong là đã đăng nhập
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.account_circle_outlined, size: 72, color: theme.colorScheme.primary),
              if (widget.lyDo != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(widget.lyDo!, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
                ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('oEmail'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(
                    labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email_outlined)),
                validator: KiemTra.email,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('oMatKhau'),
                controller: _matKhau,
                obscureText: _anMatKhau,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: _anMatKhau ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                    icon: Icon(_anMatKhau ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _anMatKhau = !_anMatKhau),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu' : null,
                onFieldSubmitted: (_) => _dangNhap(),
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('nutDangNhap'),
                onPressed: _dangGui ? null : _dangNhap,
                child: _dangGui
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Đăng nhập'),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: _dangGui ? null : _moDangKy, child: const Text('Chưa có tài khoản? Đăng ký')),
            ],
          ),
        ),
      ),
    );
  }
}
