# Các điểm cần xác nhận

Nguồn và cách phân biệt yêu cầu: xem [README](../README.md).

- Quyền cụ thể của hai vai trò Admin, người tạo hồ sơ nhà cung cấp và người nhập dữ liệu lô. Nhóm đang đề xuất: nhà cung cấp dùng tài khoản `NHA_CUNG_CAP` trên app Client để gửi hồ sơ và sản phẩm; Quản trị duyệt và tạo lô trên app Admin. Cần hỏi giảng viên vì slide giới thiệu ghi app Client dành cho khách hàng.
- Hình thức giao, phí giao và phạm vi vận chuyển liên vùng; có cần tích hợp dịch vụ thật hay chỉ mô phỏng.
- Quy tắc gán lô, chia một dòng đơn cho nhiều lô, trừ tồn và hủy/hoàn đơn.
- Định nghĩa doanh số, trạng thái được tính, vùng của từng lô, và chính sách đánh giá/chứng nhận hết hạn.
- Nguồn dữ liệu và ảnh mẫu hợp lệ; không trình bày dữ liệu hoặc chứng nhận giả lập như dữ liệu đã được xác minh thực tế.

Backend đang tạm áp dụng các phương án trong [Design decisions](Design_decisions.md) cho những điểm trên; khi nhóm hoặc giảng viên chốt khác, cần cập nhật schema, code và tài liệu.
