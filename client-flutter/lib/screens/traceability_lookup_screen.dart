import 'package:flutter/material.dart';

import '../data/traceability_repository.dart';
import '../widgets/animations.dart';
import '../widgets/theme_widgets.dart';
import 'batch_journey_screen.dart';
import 'qr_scanner_screen.dart';

/// Màn hình 2: tra cứu nguồn gốc theo mã lô in trên bao bì. KHÔNG cần đăng nhập.
/// Thiết kế tối giản thoáng rộng kiểu Mobbin: không khung gradient nặng, đi thẳng vào quét QR.
class TraceabilityLookupScreen extends StatefulWidget {
  const TraceabilityLookupScreen({super.key});

  @override
  State<TraceabilityLookupScreen> createState() => _TraceabilityLookupScreenState();
}

class _TraceabilityLookupScreenState extends State<TraceabilityLookupScreen> {
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
    if (TraceabilityRepository.tachMa(giaTri) == null) {
      return 'Mã gồm 20 ký tự 0–9, A–F (hoặc dán đường dẫn trong mã QR)';
    }
    return null;
  }

  void _traCuu() {
    if (!_formKey.currentState!.validate()) return;
    final ma = TraceabilityRepository.tachMa(_maController.text)!;
    FocusScope.of(context).unfocus();
    _moHanhTrinh(ma);
  }

  void _moHanhTrinh(String ma) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => BatchJourneyScreen(maTruyXuat: ma)),
    );
  }

  Future<void> _quetQr() async {
    final ma = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
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
              FadeIn(
                thuTu: 0,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(color: OcopColors.xanhNhat, shape: BoxShape.circle),
                          child: const Icon(Icons.qr_code_scanner_rounded, size: 30, color: OcopColors.xanhOcop),
                        ),
                        const SizedBox(height: 14),
                        Text('Quét tem QR trên bao bì', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: PressFeedback(
                            rungNhe: true,
                            child: FilledButton.icon(
                              key: const Key('nutQuetQr'),
                              onPressed: _quetQr,
                              icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                              label: const Text('Quét mã QR'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FadeIn(
                thuTu: 1,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          key: const Key('oMaTruyXuat'),
                          controller: _maController,
                          style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600, letterSpacing: 0.6),
                          decoration: const InputDecoration(
                            labelText: 'Mã truy xuất',
                            hintText: 'Ví dụ: B056FB25CA6642785532',
                            prefixIcon: Icon(Icons.qr_code_2),
                          ),
                          textCapitalization: TextCapitalization.characters,
                          autocorrect: false,
                          validator: _kiemTraMa,
                          onFieldSubmitted: (_) => _traCuu(),
                        ),
                        const SizedBox(height: 12),
                        PressFeedback(
                          child: OutlinedButton.icon(
                            onPressed: _traCuu,
                            icon: const Icon(Icons.search_rounded, size: 20),
                            label: const Text('Xem hành trình lô'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
