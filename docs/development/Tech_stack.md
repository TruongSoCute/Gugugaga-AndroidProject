# Kiến trúc và công nghệ

Nguồn và cách phân biệt yêu cầu: xem [README](../README.md).

`Android Admin / Flutter Client → REST API Express trên Render → PostgreSQL và Storage trên Supabase`. Hai app gọi cùng API và cùng dữ liệu; không xây hai ứng dụng dữ liệu tách biệt. Truy xuất QR là ngoại lệ công khai về đăng nhập, không phải ngoại lệ về nguồn dữ liệu.

- Android Studio, Java, XML, minSdk 24; Retrofit 2 + Gson hoặc OkHttp.
- Flutter 3.35+, Dart 3; `http` hoặc `dio`.
- Node.js 20, Express 4, `pg` và SQL thuần; PostgreSQL Supabase; ảnh/tệp trên Supabase Storage, không lưu base64 trong CSDL.
- JWT tự phát hành và bcrypt. Backend deploy Render. Nếu đổi công nghệ, tài liệu yêu cầu xin phép giảng viên trước tuần 9 kèm lý do.
- Theo tài liệu, dùng Supabase Connection pooler session mode cổng 5432 cho kết nối Render; cấu hình bằng biến môi trường và xác minh trên môi trường triển khai. Hạn mức, cách kết nối và chính sách gói miễn phí có thể thay đổi, nên kiểm tra lại tài liệu nhà cung cấp khi triển khai.

## Tiêu chuẩn kỹ thuật cho ứng dụng

**Admin:** ít nhất 6 màn hình; đăng nhập, lưu token và đăng xuất khi hết hạn; ít nhất 2 vai trò; ít nhất 2 danh sách sử dụng RecyclerView + Adapter + ViewHolder; điều hướng bằng Fragment hoặc nhiều Activity; kiểm tra form; xác nhận trước xóa và phản hồi kết quả; ít nhất một báo cáo có biểu đồ; thể hiện đang tải, thành công và lỗi mạng; giữ dữ liệu form khi xoay màn hình; tên app và TAG log chứa mã nhóm.

**Client:** ít nhất 6 màn hình; đăng ký/đăng nhập và lưu token bằng `shared_preferences` theo đề; Navigator có trả kết quả; ít nhất 2 danh sách `ListView.builder` từ API; form dùng Form + validator và chặn gửi dữ liệu không hợp lệ; Scaffold với Drawer hoặc NavigationBar; xác nhận xóa và SnackBar Hoàn tác; trạng thái tải (CircularProgressIndicator)/dữ liệu/lỗi; ảnh URL có `loadingBuilder`, `errorBuilder`; kiểm tra `mounted` sau `await` trước khi dùng context; `flutter analyze` không còn lỗi.

Ví dụ màn hình giúp nhóm lên kế hoạch, không phải danh sách giới hạn: Admin đăng nhập, nhà cung cấp, sản phẩm, lô và bước truy xuất, đơn, phản ánh, báo cáo; Client đăng nhập, danh sách, chi tiết, quét/truy xuất, giỏ, đơn, đánh giá, yêu thích và nhà cung cấp. Một màn hình có thể bao gồm nhiều chức năng nếu vẫn đáp ứng yêu cầu.

## Backend và triển khai

Theo mục C.3, mọi API yêu cầu đăng nhập phải qua middleware kiểm tra JWT; mật khẩu phải được băm và không bao giờ trả về client. Quyền phải được kiểm tra trên backend, kể cả khi gọi API trực tiếp. Có ít nhất một transaction, SQL tham số hóa, các mã HTTP phù hợp, `schema.sql`, `seed.sql` và tài liệu API hoặc Postman collection.

Theo hướng dẫn nguồn, cấu hình `DATABASE_URL`, `JWT_SECRET`, `SUPABASE_URL` và `SUPABASE_SERVICE_KEY` bằng biến môi trường trên backend; khóa service role chỉ được giữ phía server. Không đưa `.env` vào Git. Nếu bí mật đã lộ trong lịch sử Git, cần thu hồi hoặc thay khóa tương ứng; chỉ xóa file không đủ. Render có thể cần thời gian khởi động sau khi ngủ và Supabase có thể bị tạm dừng khi không hoạt động; kiểm tra tình trạng thực tế trước buổi demo.

## Kiến trúc backend (Đề xuất)

Đề không quy định kiến trúc mã nguồn. Đây là lựa chọn của nhóm, cần cả nhóm thống nhất. Backend chia theo **miền nghiệp vụ** (`backend/src/domains/<miền>/`). Trong mỗi miền, code chỉ phụ thuộc theo một chiều: `types → config → repo → service → routes → index`. Các mối quan tâm xuyên suốt (CSDL, JWT/vai trò, bcrypt, sinh số ngẫu nhiên, log, xử lý lỗi HTTP) đi vào qua một cửa duy nhất là `providers/`. `app.js` (App Wiring) ghép Providers với các miền.

| Tầng | Chứa gì | Được dùng |
| --- | --- | --- |
| `types` | Kiểm tra dữ liệu vào, hằng trạng thái; hàm thuần | `utils` |
| `config` | Cấu hình riêng của miền, nếu có | `types`, `utils` |
| `repo` | Chỉ câu SQL tham số hóa; nhận `q` là pool hoặc client transaction | `types`, `config`, `utils` |
| `service` | Quy tắc nghiệp vụ, transaction, lỗi 404/409 | tầng trước, `utils`, `providers` |
| `routes` | Runtime + UI của backend: đọc request, gắn quyền, gọi service, trả JSON | `types`, `service`, `utils`, `providers`, `express` (không gọi `repo`) |
| `index` | Tạo service và router cho `app.js` | các tầng trong miền, `providers` |

Quy tắc được **kiểm tra bằng máy**: `backend/scripts/check-architecture.js` chạy trong `npm test` và báo lỗi khi:
- một tầng require tầng đứng sau nó, hoặc `routes` gọi thẳng `repo`;
- một miền require miền khác (phụ thuộc giữa các miền phải truyền vào ở `app.js`);
- `types`/`config`/`repo` dùng `providers`, hoặc `utils` phụ thuộc thứ gì khác ngoài `utils`;
- `pg`, `jsonwebtoken`, `bcryptjs`, `crypto` được dùng ngoài đúng provider của nó;
- có `require` động hoặc file nằm ngoài các vị trí trên.

Lý do áp dụng: miền đơn hàng sắp làm có nhiều quy tắc (khóa dòng, trừ tồn, gán lô, chuyển trạng thái). Tách tầng giúp thành viên làm song song theo miền, ít xung đột, và dễ trả lời khi bảo vệ (SQL ở `repo`, quy tắc ở `service`, quyền ở `providers/auth`). Kiểm tra bằng máy giữ cho code do nhiều người và AI viết vẫn theo cùng một quy tắc.

**Gợi ý cho hai app (Đề xuất, không kiểm tra bằng máy):** hai app không quyết định nghiệp vụ nên không cần tầng service.
- Android dùng `model/`, `data/` (Retrofit, repository) và `ui/<miền>/` (ViewModel, Activity/Fragment/Adapter). `ApiClient`, interceptor gắn token và quản lý phiên đóng vai trò Providers.
- Flutter dùng `models/`, `repositories/`, `screens/`, `widgets/` và một `ApiClient` dùng chung đọc token từ `shared_preferences`.
