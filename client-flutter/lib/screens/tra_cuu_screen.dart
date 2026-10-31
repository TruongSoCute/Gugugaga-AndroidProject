import 'package:flutter/material.dart';

import '../data/truy_xuat_repository.dart';
import 'hanh_trinh_screen.dart';

/// Màn hình 2: tra cứu nguồn gốc theo mã lô in trên bao bì. KHÔNG cần đăng nhập.
/// Nhận mã 20 ký tự hoặc dán cả đường dẫn trong QR. Form + validator chặn gửi khi sai (C.2 #4).
/// (Quét QR bằng camera sẽ thêm sau, dùng chung bước kiểm tra mã này.)
class TraCuuScreen extends StatefulWidget {
  const TraCuuScreen({super.key});

  @override
  State<TraCuuScreen> createState() => _TraCuuScreenState();
}

class _TraCuuScreenState extends State<TraCuuScreen> {
  final _formKey = GlobalKey<FormState>();
  final _maController = TextEditingController();

  @override
  void dispose() {
    _maController.dispose();
    super.dispose();
  }

  String? _kiemTraMa(String? giaTri) {
    if (giaTri == null || giaTri.trim().isEmpty) {
      return 'Vui lòng nhập mã truy xuất in trên bao bì';
    }
    if (TruyXuatRepository.tachMa(giaTri) == null) {
      return 'Mã gồm 20 ký tự 0–9, A–F (hoặc dán đường dẫn trong mã QR)';
    }
    return null;
  }

  void _traCuu() {
    if (!_formKey.currentState!.validate()) return; // chặn gửi khi chưa hợp lệ
    final ma = TruyXuatRepository.tachMa(_maController.text)!;
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => HanhTrinhScreen(maTruyXuat: ma)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Truy xuất nguồn gốc')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.verified_outlined, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                'Mỗi lô hàng có một mã riêng. Nhập mã để xem đúng hành trình của lô bạn đang cầm: '
                'vùng nguyên liệu, người sản xuất và từng bước từ thu hoạch tới kiểm nghiệm.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('oMaTruyXuat'),
                controller: _maController,
                decoration: const InputDecoration(
                  labelText: 'Mã truy xuất',
                  hintText: 'Ví dụ: B056FB25CA6642785532',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code_2),
                ),
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                validator: _kiemTraMa,
                onFieldSubmitted: (_) => _traCuu(),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _traCuu,
                icon: const Icon(Icons.search),
                label: const Text('Xem hành trình lô'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
