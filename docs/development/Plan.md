# Thứ tự thực hiện đề xuất

Nguồn và cách phân biệt yêu cầu: xem [README](../README.md).

1. Tạo tài khoản Supabase và Render, đọc phụ lục 2–3 của tài liệu nguồn về gọi API; chốt vai trò, luồng duyệt, các trạng thái đơn, cách gán lô và mã nhóm; lập use case và ERD.
2. Dựng backend, CSDL, `/health` và deploy sớm. Xem [mốc của môn học](../course/Delivery.md) để lập lịch phù hợp. Làm một luồng xuyên suốt: Admin tạo và duyệt sản phẩm, tạo lô và thêm các bước truy xuất, Client quét QR công khai và thấy đúng lô. Chuẩn bị dữ liệu mẫu với ít nhất 100 lô đủ bốn bước mỗi lô theo yêu cầu đề.
3. Hoàn thiện đăng nhập/phân quyền, danh sách sản phẩm, giỏ và giao dịch đặt đơn; sau đó xử lý đơn, đánh giá, báo cáo, yêu thích và theo dõi.
4. Làm báo cáo, đủ dữ liệu mẫu, kiểm thử trên thiết bị thật, APK, video và tài liệu; chỉ sau đó cân nhắc phần mở rộng.

## Trạng thái hiện tại và việc tiếp theo

Cập nhật bảng này mỗi khi xong hoặc nhận một việc, để thành viên mới biết nên làm gì. Thứ tự ưu tiên theo [mốc môn học](../course/Delivery.md): tuần 11 cần backend đã deploy, 3 API thật và 2 màn hình mỗi app; tuần 13 cần hai app gọi API thật và demo luồng chính.

**Đã xong (01/11/2026):**
- Backend đã deploy tại https://ocop-backend.onrender.com, CSDL trên Supabase với đủ dữ liệu mẫu.
- API: xác thực, danh mục, nhà cung cấp, sản phẩm, lô và truy xuất QR, giỏ hàng và đơn hàng. Có 59 test tự động.
- App Admin: đăng nhập, danh sách và duyệt sản phẩm, tab tài khoản (3 màn hình).
- App Client: danh sách sản phẩm có lọc, tra cứu mã, hành trình lô (3 màn hình).

**Việc tiếp theo** (mỗi app cần ít nhất 6 màn hình; xem [Tech stack](Tech_stack.md#tiêu-chuẩn-kỹ-thuật-cho-ứng-dụng)):

| Ưu tiên | Phần | Việc | Ghi chú |
| --- | --- | --- | --- |
| 1 | Hai app | Build APK, cài lên điện thoại thật, chụp màn hình gọi API thật | Minh chứng mốc tuần 11 |
| 2 | Admin | Danh sách đơn hàng (RecyclerView thứ hai) + chi tiết và chuyển trạng thái | API `/quan-tri/don-hang`, `PATCH /don-hang/:id/trang-thai` đã có |
| 2 | Client | Đăng ký/đăng nhập, lưu token | API `/auth` đã có; `TokenStore` đã sẵn; cần thêm `post` vào `ApiClient` |
| 2 | Client | Giỏ hàng, đặt đơn (chọn hình thức giao), theo dõi đơn, xác nhận đã nhận | API `/gio-hang`, `/don-hang` đã có; cần Navigator trả kết quả, SnackBar Hoàn tác |
| 3 | Admin | Duyệt hồ sơ nhà cung cấp | API đã có |
| 3 | Admin | Danh sách lô, tạo lô (form giữ dữ liệu khi xoay), thêm bước, hiển thị QR | API đã có |
| 3 | Client | Quét QR bằng camera | Hiện đang nhập hoặc dán mã |
| 4 | Backend + Client + Admin | Đánh giá kèm ảnh, báo cáo hàng giả, xử lý phản ánh | Bảng đã có, chưa có API |
| 4 | Backend + Client | Yêu thích sản phẩm, theo dõi nhà cung cấp | Bảng đã có, chưa có API |
| 4 | Backend + Admin | Báo cáo doanh số theo vùng, hạng sao, nhà cung cấp; màn hình biểu đồ | Bắt buộc C.1 #7 |
| 5 | Backend | Upload ảnh lên Supabase Storage | Hiện dùng URL ảnh |
| 5 | Nộp bài | Báo cáo PDF, video demo, ít nhất 25 trường hợp kiểm thử có kết quả thật | Xem [Submission checklist](../course/Submission_checklist.md) |

