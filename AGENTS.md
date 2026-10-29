# Quy tắc phát triển dự án

Danh mục tài liệu dự án: [docs/README.md](docs/README.md). Trước khi thiết kế hoặc thay đổi chức năng, đối chiếu yêu cầu trong [Product](docs/development/Product.md) và quy tắc trong [Rule](docs/development/Rule.md); tham khảo các tài liệu liên quan theo mục đích công việc. Khi yêu cầu chưa được giảng viên quy định, đánh dấu là đề xuất hoặc cần xác nhận; không trình bày giả định như yêu cầu chính thức.

- Bắt buộc xây dựng cả hai app riêng: Admin Android Java/XML cho quản lý và Client Flutter/Dart cho khách; mỗi app tối thiểu 6 màn hình và có APK release riêng. Cả hai cùng dùng backend Node.js/Express đã deploy và PostgreSQL trên Supabase. Không coi app Client là tùy chọn. Không thay stack bắt buộc khi chưa được giảng viên cho phép.
- Không bỏ chức năng bắt buộc để ưu tiên chức năng mở rộng. Điểm nhấn là truy xuất công khai theo từng lô, không yêu cầu đăng nhập; mã của mỗi lô duy nhất và khó đoán.
- Quyết định về quyền, giá, trạng thái và tính hợp lệ phải được backend kiểm tra. Không tin dữ liệu do client gửi. Dùng JWT, bcrypt, truy vấn SQL tham số hóa và transaction khi nhiều thay đổi phải thành công cùng nhau.
- Không đưa mật khẩu, token, khóa dịch vụ hoặc `.env` vào Git. Chỉ cung cấp `.env.example` không có bí mật. Không đưa khóa Supabase service role vào ứng dụng di động.
- Giữ API, schema.sql, seed.sql, README và tài liệu phù hợp với hành vi thực tế khi triển khai. Kiểm thử các trường hợp thành công, sai quyền, dữ liệu không hợp lệ và luồng QR công khai.
- Tên app, tên package và TAG log chứa mã nhóm khi đã biết. Mỗi thành viên dùng tài khoản GitHub riêng, có ít nhất 15 commit có ý nghĩa theo quy định học phần.
- Giải thích các khái niệm và lý do triển khai bằng ngôn ngữ dễ hiểu để thành viên có thể trình bày khi bảo vệ.

