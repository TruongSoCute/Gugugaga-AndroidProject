/// Cấu hình chung của app Client.
class AppConfig {
  AppConfig._();

  /// TAG log chứa mã nhóm "gugugaga" (quy định E.4).
  static const String tag = 'GUGUGAGA_CLIENT';

  /// Địa chỉ backend, truyền lúc build:
  ///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
  ///   flutter build apk --release --dart-define=API_BASE_URL=https://ocop-backend.onrender.com
  /// Mặc định là backend chạy trên máy tính, gọi từ máy ảo Android (10.0.2.2).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  /// Render gói Free có thể mất tới một phút để thức dậy (Phụ lục 2, 3).
  static const Duration timeout = Duration(seconds: 90);
}
