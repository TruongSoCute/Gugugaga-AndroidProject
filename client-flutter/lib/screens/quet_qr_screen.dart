import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../data/truy_xuat_repository.dart';

/// Quét QR trên bao bì bằng camera (mobile_scanner). Nội dung QR là
/// `https://…/truy-xuat/<mã>`; tách được mã hợp lệ thì `Navigator.pop(context, ma)` trả mã về
/// màn hình tra cứu (Navigator trả kết quả). Không cần đăng nhập.
class QuetQrScreen extends StatefulWidget {
  const QuetQrScreen({super.key});

  @override
  State<QuetQrScreen> createState() => _QuetQrScreenState();
}

class _QuetQrScreenState extends State<QuetQrScreen> {
  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  bool _daTra = false;
  String? _canhBao;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _khiQuet(BarcodeCapture capture) {
    if (_daTra) return;
    for (final b in capture.barcodes) {
      final noiDung = b.rawValue;
      if (noiDung == null) continue;
      final ma = TruyXuatRepository.tachMa(noiDung);
      if (ma != null) {
        _daTra = true;
        Navigator.pop(context, ma);
        return;
      }
      if (_canhBao == null) {
        setState(() => _canhBao = 'Mã QR này không phải mã truy xuất OCOP. Hãy quét QR in trên bao bì.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét mã QR'),
        actions: [
          IconButton(
            tooltip: 'Bật/tắt đèn',
            icon: const Icon(Icons.flashlight_on_outlined),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _khiQuet,
            errorBuilder: (context, loi) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  loi.errorCode == MobileScannerErrorCode.permissionDenied
                      ? 'Ứng dụng chưa được cấp quyền camera. Hãy cấp quyền trong Cài đặt, hoặc quay lại và nhập mã bằng tay.'
                      : 'Không mở được camera (${loi.errorCode.name}). Hãy quay lại và nhập mã bằng tay.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_canhBao ?? 'Đưa mã QR trên bao bì vào khung để xem hành trình của đúng lô hàng.',
                    textAlign: TextAlign.center),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
