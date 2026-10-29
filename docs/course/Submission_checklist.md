# Danh sách tự kiểm trước khi nộp

Nguồn và cách phân biệt yêu cầu: xem [README](../README.md).

Theo phụ lục 4 của tài liệu gốc, nhóm tự kiểm các mục sau và ghi kết quả thực tế:

- [ ] Mở endpoint `/health` của Render từ máy khác và nhận 200.
- [ ] Gọi API cần đăng nhập không có token nhận 401; gọi API quản trị bằng token khách nhận 403.
- [ ] Dự án Supabase đang hoạt động; chạy `schema.sql` và `seed.sql` trên CSDL trống không lỗi; dữ liệu mẫu đủ số lượng.
- [ ] Cài APK Admin và Client lên máy Android thật, đăng nhập được cả hai.
- [ ] Thêm dữ liệu ở Admin và kiểm tra Client nhìn thấy dữ liệu đó qua hệ thống dùng chung.
- [ ] Tắt Wi-Fi kiểm tra app báo lỗi mạng và không văng; xoay màn hình khi đang nhập form kiểm tra dữ liệu không mất.
- [ ] Chạy `flutter analyze` không còn lỗi.
- [ ] Kiểm tra `.env` không nằm trong repository hoặc lịch sử commit.
- [ ] README ghi link API, tài khoản thử nghiệm cho từng vai trò và cách chạy; mỗi thành viên có ít nhất 15 commit bằng tài khoản riêng.
- [ ] Báo cáo đủ 9 mục, có sơ đồ CSDL và ít nhất 25 trường hợp kiểm thử với kết quả thật; video dài 5–8 phút, quay màn hình thật và có thuyết minh.
- [ ] Gọi thử API khoảng 3 phút trước demo để đánh thức Render theo hướng dẫn của tài liệu; kiểm tra Supabase không bị tạm dừng.
