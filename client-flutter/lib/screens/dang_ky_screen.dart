import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/tai_khoan_repository.dart';
import '../models/nguoi_dung.dart';
import '../utils/kiem_tra.dart';
import '../widgets/hop_thoai.dart';

/// Đăng ký tài khoản KHÁCH hoặc NHÀ CUNG CẤP (gửi hồ sơ, sản phẩm chờ quản trị duyệt).
/// Thành công thì pop trả về NguoiDung (đã đăng nhập luôn).
class DangKyScreen extends StatefulWidget {
  const DangKyScreen({super.key, this.repository});

  final TaiKhoanRepository? repository;

  @override
  State<DangKyScreen> createState() => _DangKyScreenState();
}

class _DangKyScreenState extends State<DangKyScreen> {
  late final TaiKhoanRepository _repo = widget.repository ?? TaiKhoanRepository(ApiClient.macDinh);
  final _formKey = GlobalKey<FormState>();
  final _hoTen = TextEditingController();
  final _email = TextEditingController();
  final _sdt = TextEditingController();
  final _matKhau = TextEditingController();
  final _nhapLai = TextEditingController();
  String _loai = VaiTro.khach;
  bool _dangGui = false;

  @override
  void dispose() {
    for (final c in [_hoTen, _email, _sdt, _matKhau, _nhapLai]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _dangKy() async {
    if (!_formKey.currentState!.validate()) return;
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
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Loại tài khoản', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: VaiTro.khach, label: Text('Khách mua'), icon: Icon(Icons.shopping_bag_outlined)),
                  ButtonSegment(value: VaiTro.nhaCungCap, label: Text('Nhà cung cấp'), icon: Icon(Icons.store_outlined)),
                ],
                selected: {_loai},
                onSelectionChanged: (s) => setState(() => _loai = s.first),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _loai == VaiTro.khach
                      ? 'Mua hàng, theo dõi đơn, đánh giá và phản ánh sản phẩm.'
                      : 'Gửi hồ sơ cơ sở và sản phẩm để quản trị viên duyệt trước khi bán.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              TextFormField(
                controller: _hoTen,
                decoration: InputDecoration(
                    labelText: _loai == VaiTro.khach ? 'Họ tên' : 'Họ tên người quản lý',
                    border: const OutlineInputBorder()),
                validator: (v) => KiemTra.batBuoc(v, 'họ tên') ?? KiemTra.doDaiToiDa(v, 120),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                validator: KiemTra.email,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sdt,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Số điện thoại (không bắt buộc)', border: OutlineInputBorder()),
                validator: (v) => KiemTra.soDienThoai(v, batBuoc: false),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _matKhau,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Mật khẩu', helperText: 'Ít nhất 8 ký tự', border: OutlineInputBorder()),
                validator: KiemTra.matKhau,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nhapLai,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nhập lại mật khẩu', border: OutlineInputBorder()),
                validator: (v) => v != _matKhau.text ? 'Mật khẩu nhập lại không khớp' : null,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _dangGui ? null : _dangKy,
                child: _dangGui
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Tạo tài khoản'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
