## Thay đổi gì

<!-- Tóm tắt ngắn: làm gì, vì sao. Liên kết issue: "Đóng #12" -->

## Phần bị ảnh hưởng

- [ ] Backend (API, `schema.sql`, `seed.sql`)
- [ ] App Admin (Android Java/XML)
- [ ] App Client (Flutter)
- [ ] Tài liệu
- [ ] Phát hành (workflow, Render)

## Đã kiểm tra

<!-- Đánh dấu những lệnh đã chạy và đạt cho phần đã sửa -->

- [ ] `backend/`: `npm run check:arch` và `npm test`
- [ ] `admin-android/`: `./gradlew testDebugUnitTest lintDebug`
- [ ] `client-flutter/`: `flutter analyze` và `flutter test`
- [ ] Chạy thử trên máy ảo hoặc điện thoại (ghi thiết bị, kèm ảnh nếu có giao diện)
- [ ] Đã thêm test cho trường hợp thành công, sai quyền, dữ liệu sai

## Trước khi merge

- [ ] Không có mật khẩu, token, khóa ký, `.env`, `keystore.properties`, `key.properties`
- [ ] Backend tự kiểm tra quyền, giá, trạng thái; SQL tham số hóa
- [ ] Đã cập nhật API.md, README, tài liệu liên quan cho khớp hành vi thực tế
- [ ] Đổi `schema.sql`: đã có câu `ALTER` cho CSDL dùng chung trên Supabase (chạy trước khi phát hành)
- [ ] Commit bằng tài khoản GitHub của chính tôi; mã tham khảo đã ghi nguồn

## Ảnh chụp màn hình

<!-- Với thay đổi giao diện -->
