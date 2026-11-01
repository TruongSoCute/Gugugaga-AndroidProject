import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/api_client.dart';
import '../data/tai_anh_repository.dart';
import '../widgets/hop_thoai.dart';

/// Ảnh đã chọn trên máy và đã tải lên backend.
class AnhDaTai {
  const AnhDaTai({required this.bytes, required this.url});

  final Uint8List bytes;
  final String url;
}

/// Hỏi người dùng chụp ảnh hay chọn từ thư viện, rồi tải ảnh lên (POST /tai-len/anh).
/// Trả null nếu người dùng hủy hoặc tải lỗi (đã báo bằng SnackBar).
/// Backend chưa cấu hình kho ảnh (503 CHUA_CAU_HINH_LUU_ANH) thì gọi [khiChuaCauHinh] để màn hình
/// cho gửi tiếp không kèm ảnh (hoặc nhập URL ảnh).
Future<AnhDaTai?> chonVaTaiAnh(
  BuildContext context, {
  required TaiAnhRepository repository,
  required String mucDich,
  VoidCallback? khiChuaCauHinh,
}) async {
  final nguon = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Chụp ảnh'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Chọn từ thư viện'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (nguon == null || !context.mounted) return null;

  final XFile? tep;
  try {
    // Thu nhỏ trước khi gửi để dưới giới hạn 5 MB của backend.
    tep = await ImagePicker().pickImage(source: nguon, maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
  } on Object {
    if (context.mounted) thongBao(context, 'Không mở được camera hoặc thư viện ảnh. Kiểm tra quyền của ứng dụng.');
    return null;
  }
  if (tep == null || !context.mounted) return null;

  final bytes = await tep.readAsBytes();
  if (!context.mounted) return null;
  try {
    final url = await repository.taiAnh(bytes, tenTep: tep.name, mucDich: mucDich);
    return AnhDaTai(bytes: bytes, url: url);
  } on ApiException catch (e) {
    if (!context.mounted) return null;
    if (TaiAnhRepository.laChuaCauHinh(e)) {
      khiChuaCauHinh?.call();
      thongBao(context, 'Máy chủ chưa cấu hình lưu ảnh nên chưa tải ảnh lên được. Bạn vẫn có thể gửi không kèm ảnh.');
    } else {
      thongBao(context, 'Tải ảnh thất bại: ${e.thongDiepDayDu}');
    }
    return null;
  }
}
