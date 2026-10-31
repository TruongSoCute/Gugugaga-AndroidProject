# App Client Flutter: OCOP Gugugaga

App cho khách mua đặc sản OCOP (đề 05), viết bằng **Flutter/Dart**, gọi backend chung bằng gói `http`, lưu token bằng `shared_preferences` (C.2). Tổ chức mã nguồn theo [Architecture](../docs/development/Architecture.md):

```
lib/
  config.dart     địa chỉ API (--dart-define), timeout, TAG
  data/           ApiClient dùng chung, TokenStore, các repository (màn hình không gọi http trực tiếp)
  models/         lớp dữ liệu đọc từ JSON của backend
  screens/        các màn hình
  widgets/        widget dùng lại (ảnh mạng có loadingBuilder/errorBuilder, khối lỗi + Thử lại)
  utils/          định dạng tiền, ngày
```

**Mã nhóm:** `gugugaga`.
- tên app: `OCOP Gugugaga`;
- package: `vn.edu.vhu.ltdd.gugugaga.ocop_client`;
- TAG: `GUGUGAGA_CLIENT`.

## Tiến độ (mốc tuần 11: 2 màn hình gọi API thật)

| Màn hình | API | Ghi chú |
| --- | --- | --- |
| Sản phẩm | `GET /vung-nguyen-lieu`, `GET /san-pham?vung=&hangSao=` | Lọc theo vùng và hạng sao, `ListView.builder`, ảnh có `loadingBuilder`/`errorBuilder`, đủ 3 trạng thái, kéo để tải lại |
| Truy xuất | (kiểm tra mã trên máy) | `Form` + `validator`: nhận mã 20 ký tự hoặc đường dẫn trong QR |
| Hành trình lô | `GET /truy-xuat/:ma` (công khai) | Đúng lô theo mã: thông tin lô, nhà cung cấp, chứng nhận, các bước (`ListView.builder`). Mã sai/không công bố thì cảnh báo "không xác minh được nguồn gốc" |

Khung app dùng `Scaffold` + `NavigationBar`; sau mỗi `await` đều kiểm tra `mounted`.

**Chưa làm:**
- đăng ký/đăng nhập (TokenStore đã sẵn);
- quét QR bằng camera (hiện đang nhập hoặc dán mã);
- giỏ hàng, đặt đơn, theo dõi đơn, đánh giá, báo cáo, yêu thích, theo dõi nhà cung cấp;
- Navigator trả kết quả, SnackBar Hoàn tác.

## Chạy

Cần Flutter 3.35+ (đã thử với 3.47.9) và Android SDK. Backend chạy trên máy (xem [backend/README](../backend/README.md)), app mặc định gọi `http://10.0.2.2:3000` khi chạy trên máy ảo Android.

```bash
flutter pub get
```

```bash
flutter run
```

Điện thoại thật cùng Wi-Fi:

```bash
flutter run --dart-define=API_BASE_URL=http://<IP-máy-tính>:3000
```

Mã truy xuất mẫu để thử: chạy `SELECT ma_truy_xuat FROM lo_san_xuat LIMIT 5;` trên CSDL. Mã được sinh ngẫu nhiên mỗi lần chạy seed.

## Build APK release để nộp

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://<ten-service>.onrender.com
```

APK nằm ở `build/app/outputs/flutter-apk/app-release.apk`.

Khóa ký:
- Khi chưa có khóa riêng, bản release tạm ký bằng khóa debug, vẫn cài được để demo.
- Để ký bằng khóa của nhóm, tạo `android/key.properties` (không commit) với các trường `storeFile`, `storePassword`, `keyAlias`, `keyPassword`, giống app Admin.

## Kiểm thử

```bash
flutter analyze
```

```bash
flutter test
```

`test/api_backend_test.dart` gọi backend **thật** và tự bỏ qua nếu chưa đặt biến môi trường. Muốn chạy:

```bash
OCOP_API_TEST_URL=http://localhost:3000 OCOP_MA_LO_TEST=<mã lô> flutter test test/api_backend_test.dart
```

**Lần kiểm tra gần nhất:**
- `flutter analyze` không còn lỗi;
- 14 test đơn vị và widget đạt, 2 contract test với backend cục bộ đạt;
- đã build được APK debug và release.

**Chưa chạy thử giao diện trên máy ảo hoặc điện thoại thật.**
