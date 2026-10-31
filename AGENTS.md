# Quy tắc phát triển dự án

Danh mục tài liệu dự án: [docs/README.md](docs/README.md). Trước khi thiết kế hoặc thay đổi chức năng, đối chiếu yêu cầu trong [Product](docs/development/Product.md) và quy tắc trong [Rule](docs/development/Rule.md); tham khảo các tài liệu liên quan theo mục đích công việc. Khi yêu cầu chưa được giảng viên quy định, đánh dấu là đề xuất hoặc cần xác nhận; không trình bày giả định như yêu cầu chính thức.

**Khi bắt đầu mỗi phiên làm việc, đọc [Architecture](docs/development/Architecture.md) trước khi đọc hoặc sửa code.** Mọi thay đổi phải theo kiến trúc và quy tắc trong tài liệu đó:

- Backend chia theo miền `backend/src/domains/<miền>/`, mỗi miền chỉ phụ thuộc theo chiều `types → config → repo → service → routes → index`. SQL chỉ nằm trong `repo`; quy tắc nghiệp vụ và transaction nằm trong `service`; `routes` không gọi `repo`.
- Mối quan tâm xuyên suốt chỉ đi vào qua `providers/`: CSDL (`pg`), JWT/vai trò, bcrypt, `crypto`, log, lỗi HTTP. Miền không require miền khác; phụ thuộc giữa các miền truyền vào ở `app.js`. `utils/` chỉ chứa hàm thuần.
- Sau khi sửa backend, chạy `npm run check:arch` và `npm test` trong `backend/`. Khi có vi phạm, sửa code cho đúng tầng; không nới quy tắc, không sửa `scripts/check-architecture.js` hoặc thêm ngoại lệ để vượt qua. Chỉ đổi quy tắc khi nhóm đã thống nhất, và khi đó cập nhật cùng lúc Architecture, script kiểm tra và `test/kien-truc.test.js`.
- Hai app tổ chức theo gợi ý trong Architecture: màn hình không gọi API trực tiếp mà qua repository, và token/phiên đăng nhập do một `ApiClient` dùng chung quản lý.
- Khi làm app Admin Android, đọc [Labs Android](docs/development/Labs_Android.md) và dùng đúng kỹ thuật giảng viên đã dạy trong lab, cùng cách gọi API theo Phụ lục 2. Không thay bằng cách khác khi lab đã có cách làm.

- Bắt buộc xây dựng cả hai app riêng: Admin Android Java/XML cho quản lý và Client Flutter/Dart cho khách; mỗi app tối thiểu 6 màn hình và có APK release riêng. Cả hai cùng dùng backend Node.js/Express đã deploy và PostgreSQL trên Supabase. Không coi app Client là tùy chọn. Không thay stack bắt buộc khi chưa được giảng viên cho phép.
- Không bỏ chức năng bắt buộc để ưu tiên chức năng mở rộng. Điểm nhấn là truy xuất công khai theo từng lô, không yêu cầu đăng nhập; mã của mỗi lô duy nhất và khó đoán.
- Quyết định về quyền, giá, trạng thái và tính hợp lệ phải được backend kiểm tra. Không tin dữ liệu do client gửi. Dùng JWT, bcrypt, truy vấn SQL tham số hóa và transaction khi nhiều thay đổi phải thành công cùng nhau.
- Không đưa mật khẩu, token, khóa dịch vụ hoặc `.env` vào Git. Chỉ cung cấp `.env.example` không có bí mật. Không đưa khóa Supabase service role vào ứng dụng di động.
- Giữ API, schema.sql, seed.sql, README và tài liệu phù hợp với hành vi thực tế khi triển khai. Kiểm thử các trường hợp thành công, sai quyền, dữ liệu không hợp lệ và luồng QR công khai.
- Mã nhóm là `gugugaga`: tên app, tên package (`vn.edu.vhu.ltdd.gugugaga...`) và TAG log phải chứa mã này. Mỗi thành viên dùng tài khoản GitHub riêng, có ít nhất 15 commit có ý nghĩa theo quy định học phần.
- Giải thích các khái niệm và lý do triển khai bằng ngôn ngữ dễ hiểu để thành viên có thể trình bày khi bảo vệ.

