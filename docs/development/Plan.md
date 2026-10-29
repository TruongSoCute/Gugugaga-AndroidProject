# Thứ tự thực hiện đề xuất

Nguồn và cách phân biệt yêu cầu: xem [README](../README.md).

1. Tạo tài khoản Supabase và Render, đọc phụ lục 2–3 của tài liệu nguồn về gọi API; chốt vai trò, luồng duyệt, các trạng thái đơn, cách gán lô và mã nhóm; lập use case và ERD.
2. Dựng backend, CSDL, `/health` và deploy sớm. Xem [mốc của môn học](../course/Delivery.md) để lập lịch phù hợp. Làm một luồng xuyên suốt: Admin tạo và duyệt sản phẩm, tạo lô và thêm các bước truy xuất, Client quét QR công khai và thấy đúng lô. Chuẩn bị dữ liệu mẫu với ít nhất 100 lô đủ bốn bước mỗi lô theo yêu cầu đề.
3. Hoàn thiện đăng nhập/phân quyền, danh sách sản phẩm, giỏ và giao dịch đặt đơn; sau đó xử lý đơn, đánh giá, báo cáo, yêu thích và theo dõi.
4. Làm báo cáo, đủ dữ liệu mẫu, kiểm thử trên thiết bị thật, APK, video và tài liệu; chỉ sau đó cân nhắc phần mở rộng.
