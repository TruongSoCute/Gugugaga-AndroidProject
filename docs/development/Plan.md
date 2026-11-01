# Thứ tự thực hiện đề xuất

Nguồn và cách phân biệt yêu cầu: xem [README](../README.md).

1. Tạo tài khoản Supabase và Render, đọc phụ lục 2–3 của tài liệu nguồn về gọi API; chốt vai trò, luồng duyệt, các trạng thái đơn, cách gán lô và mã nhóm; lập use case và ERD.
2. Dựng backend, CSDL, `/health` và deploy sớm. Xem [mốc của môn học](../course/Delivery.md) để lập lịch phù hợp. Làm một luồng xuyên suốt: Admin tạo và duyệt sản phẩm, tạo lô và thêm các bước truy xuất, Client quét QR công khai và thấy đúng lô. Chuẩn bị dữ liệu mẫu với ít nhất 100 lô đủ bốn bước mỗi lô theo yêu cầu đề.
3. Hoàn thiện đăng nhập/phân quyền, danh sách sản phẩm, giỏ và giao dịch đặt đơn; sau đó xử lý đơn, đánh giá, báo cáo, yêu thích và theo dõi.
4. Làm báo cáo, đủ dữ liệu mẫu, kiểm thử trên thiết bị thật, APK, video và tài liệu; chỉ sau đó cân nhắc phần mở rộng.

## Trạng thái hiện tại và việc tiếp theo

Cập nhật bảng này mỗi khi xong hoặc nhận một việc, để thành viên mới biết nên làm gì. Thứ tự ưu tiên theo [mốc môn học](../course/Delivery.md): tuần 11 cần backend đã deploy, 3 API thật và 2 màn hình mỗi app; tuần 13 cần hai app gọi API thật và demo luồng chính.

**Đã xong (01/11/2026):**
- Backend: đủ các nhóm API của đề (xác thực, danh mục, nhà cung cấp kể cả tự gửi hồ sơ, sản phẩm, lô và truy xuất QR, giỏ và đơn hàng, đánh giá, phản ánh, yêu thích, theo dõi, báo cáo doanh số, tải ảnh). 78 test tự động.
- CSDL trên Supabase đủ dữ liệu mẫu, có 2 tài khoản nhà cung cấp, bucket ảnh `ocop-anh`.
- App Admin: 13 màn hình (đăng nhập, sản phẩm, nhà cung cấp, lô + QR + tạo lô, đơn hàng, phản ánh, báo cáo biểu đồ, tài khoản), đủ 10 yêu cầu C.1; 63 unit test.
- App Client: 22 màn hình cho khách (mua hàng, đánh giá kèm ảnh, phản ánh, yêu thích, theo dõi, quét QR) và nhà cung cấp (hồ sơ, sản phẩm); 52 test + 8 contract test.
- Cả hai app build được APK release.

**Việc tiếp theo:**

| Ưu tiên | Phần | Việc | Ghi chú |
| --- | --- | --- | --- |
| 1 | Triển khai | Đưa code mới lên `main` để Render deploy; khai báo `SUPABASE_URL`, `SUPABASE_SERVICE_KEY` trên Render để bật tải ảnh | Hiện bản trên Render là bản cũ |
| 1 | Hai app | Cài APK lên điện thoại thật, chạy hết các luồng, chụp màn hình | Chưa chạy thử giao diện trên thiết bị; camera và chọn ảnh chỉ thử được trên máy thật |
| 2 | Nộp bài | Ký APK release bằng khóa của nhóm (`keystore.properties`, `key.properties`) | App Admin hiện ra APK chưa ký |
| 2 | Nhóm | Mỗi thành viên nắm phần của mình, tự commit các cải tiến bằng tài khoản riêng | Minh chứng đóng góp |
| 3 | Admin | Tải ảnh lô từ máy (hiện nhập URL); phân trang danh sách (hiện tối đa 100 dòng) | Cải tiến |
| 3 | Client | `--split-per-abi` để APK nhỏ hơn (hiện ~71 MB do `mobile_scanner`) | Cải tiến |
| 4 | Nộp bài | Báo cáo PDF, video demo, ít nhất 25 trường hợp kiểm thử có kết quả thật | Xem [Submission checklist](../course/Submission_checklist.md) |
| 5 | Mở rộng | Trang truy xuất HTML, bản đồ vùng nguyên liệu, tự khóa bán khi chứng nhận hết hạn | Chỉ làm sau phần bắt buộc |
