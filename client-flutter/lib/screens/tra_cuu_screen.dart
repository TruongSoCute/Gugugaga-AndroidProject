import 'package:flutter/material.dart';

import '../data/truy_xuat_repository.dart';
import 'hanh_trinh_screen.dart';
import 'quet_qr_screen.dart';

/// Màn hình 2: tra cứu nguồn gốc theo mã lô in trên bao bì. KHÔNG cần đăng nhập.
/// Hai cách: quét QR bằng camera (QuetQrScreen trả mã về qua Navigator), hoặc nhập/dán mã
/// 20 ký tự hay cả đường dẫn trong QR. Form + validator chặn gửi khi sai (C.2 #4).
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
    _moHanhTrinh(ma);
  }

  void _moHanhTrinh(String ma) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => HanhTrinhScreen(maTruyXuat: ma)),
    );
  }

  /// Mở camera, chờ mã quét được (Navigator trả kết quả) rồi xem hành trình.
  Future<void> _quetQr() async {
    final ma = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QuetQrScreen()),
    );
    if (!mounted || ma == null) return;
    _maController.text = ma;
    _moHanhTrinh(ma);
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
              FilledButton.icon(
                key: const Key('nutQuetQr'),
                onPressed: _quetQr,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Quét mã QR bằng camera'),
              ),
              const SizedBox(height: 16),
              const Row(children: [
                Expanded(child: Divider()),
                Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('hoặc nhập mã')),
                Expanded(child: Divider()),
              ]),
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
              OutlinedButton.icon(
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
