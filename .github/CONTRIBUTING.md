# Đóng góp cho dự án

Cảm ơn bạn quan tâm tới dự án OCOP của nhóm **gugugaga** (đồ án INT4211). Hướng dẫn đầy đủ nằm trong [docs/development/Contributing.md](../docs/development/Contributing.md); dưới đây là phần tóm tắt.

## Bắt đầu

1. Đọc [Setup](../docs/development/Setup.md) để cài đặt và chạy backend, app Admin (Android Java/XML), app Client (Flutter).
2. Đọc [Architecture](../docs/development/Architecture.md) trước khi sửa code. Quy tắc phân tầng được **kiểm tra bằng máy**; khi đỏ thì sửa code, không nới quy tắc.
3. Xem việc đang cần làm ở [Plan](../docs/development/Plan.md#trạng-thái-hiện-tại-và-việc-tiếp-theo) và các [issue](https://github.com/TruongSoCute/Gugugaga-AndroidProject/issues).

## Quy trình

1. Tạo nhánh từ `main`: `feat/...`, `fix/...`, `docs/...`.
2. Commit nhỏ, thông điệp rõ ràng, **bằng tài khoản GitHub của chính bạn** (minh chứng đóng góp của học phần).
3. Chạy kiểm tra của phần đã sửa:
   - `backend/`: `npm run check:arch` và `npm test`;
   - `admin-android/`: `./gradlew testDebugUnitTest lintDebug`;
   - `client-flutter/`: `flutter analyze` và `flutter test`.
4. Mở Pull Request vào `main` theo mẫu có sẵn. Cần ít nhất một thành viên khác duyệt.
5. Khi `main` ổn định, mở Pull Request từ `main` vào `release` để phát hành: GitHub Actions chạy test, deploy backend và đăng APK lên Releases ([Setup mục 8](../docs/development/Setup.md#8-phát-hành-tự-động-nhánh-release)).

## Báo lỗi, đề xuất

- Lỗi chức năng, đề xuất tính năng: mở [issue](https://github.com/TruongSoCute/Gugugaga-AndroidProject/issues/new/choose) theo mẫu.
- **Lỗ hổng bảo mật: không mở issue công khai**, xem [SECURITY.md](../SECURITY.md).

## Điều bắt buộc

- Không commit mật khẩu, token, khóa ký, `.env`, `keystore.properties`, `key.properties`.
- Backend phải tự kiểm tra quyền, giá, trạng thái; SQL luôn tham số hóa.
- Mã tham khảo trên mạng phải ghi nguồn; không sao chép mã của nhóm khác.
- Tuân theo [Quy tắc ứng xử](../CODE_OF_CONDUCT.md).

Bằng việc đóng góp, bạn đồng ý phần đóng góp được phát hành theo [giấy phép MIT](../LICENSE) của dự án.
