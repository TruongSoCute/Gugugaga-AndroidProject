import 'api_client.dart';

/// Tải ảnh thật lên backend (POST /tai-len/anh?mucDich=), backend lưu lên Supabase Storage
/// và trả URL công khai. Body là byte ảnh, không phải base64/JSON.
class TaiAnhRepository {
  TaiAnhRepository(this._api);

  final ApiClient _api;

  /// Mã lỗi khi backend chưa cấu hình kho ảnh (503): app cho gửi không ảnh hoặc nhập URL.
  static const chuaCauHinh = 'CHUA_CAU_HINH_LUU_ANH';

  static bool laChuaCauHinh(ApiException e) => e.maHttp == 503 || e.ma == chuaCauHinh;

  /// Đoán Content-Type theo đuôi tệp (backend chỉ nhận jpeg, png, webp và tự kiểm tra byte đầu).
  static String loaiAnh(String tenTep) {
    final t = tenTep.toLowerCase();
    if (t.endsWith('.png')) return 'image/png';
    if (t.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  /// `mucDich`: danh-gia, san-pham, nha-cung-cap, lo, phan-anh.
  Future<String> taiAnh(List<int> bytes, {required String tenTep, required String mucDich}) async {
    final json = await _api.postBytes('/tai-len/anh', bytes,
        contentType: loaiAnh(tenTep), query: {'mucDich': mucDich}) as Map<String, dynamic>;
    return json['url'] as String;
  }
}
