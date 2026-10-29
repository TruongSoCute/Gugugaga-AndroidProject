# Quy tắc nghiệp vụ

Nguồn và cách phân biệt yêu cầu: xem [README](../README.md).

## Yêu cầu từ đề và quy định chung

1. Mỗi lô có một `ma_truy_xuat` duy nhất, khó đoán; QR dẫn tới thông tin lô cụ thể. API `GET /truy-xuat/:maTruyXuat` công khai, không cần JWT và trả hành trình của lô đó.
2. Các bước truy xuất được thiết kế với thứ tự, thời điểm, mô tả và trường URL ảnh; dữ liệu mẫu yêu cầu 100 lô có đủ bốn bước truy xuất. Đề nêu ví dụ thu hoạch, sơ chế, đóng gói, kiểm nghiệm; không quy định bốn tên bước này áp dụng bắt buộc cho mọi loại sản phẩm hay mọi lô ngoài bộ dữ liệu mẫu. Đề yêu cầu quản lý ảnh hiện trường của lô, nhưng không nói rõ mỗi bước đều bắt buộc có ảnh.
3. Chi tiết đơn ghi lô thực tế đã giao, để gắn hàng đã mua với nguồn gốc. Quản lý nhà cung cấp và sản phẩm có trạng thái duyệt; quản lý báo cáo vi phạm có trạng thái xử lý.
4. Backend quyết định quyền và kiểm tra nghiệp vụ, kể cả khi người dùng gọi API trực tiếp. Không dựa vào việc ẩn nút trên app. Mật khẩu băm bằng bcrypt; các API cần đăng nhập kiểm tra JWT. Truy vấn SQL dùng tham số `$1`, `$2`.
5. Có ít nhất một transaction cho nghiệp vụ nhiều bước, ví dụ tạo đơn cùng chi tiết và cập nhật tồn. Transaction giúp tất cả thay đổi cùng thành công hoặc cùng được hoàn tác khi gặp lỗi.

6. App Admin bắt buộc có ít nhất hai vai trò nhìn thấy các chức năng khác nhau; backend phải thực sự kiểm tra quyền của từng vai trò. Tên và quyền cụ thể của các vai trò chưa được đề 5 chốt.

## Đề xuất cần nhóm thống nhất

- Vai trò: `QUAN_TRI` quản lý toàn bộ; `NHAN_VIEN` xử lý đơn và phản ánh theo quyền được cấp; `KHACH` đặt đơn, đánh giá và theo dõi. Admin cần ít nhất hai vai trò với chức năng khác nhau. Phân quyền cụ thể cần thống nhất trước khi lập API.
- Duyệt nhà cung cấp và sản phẩm theo `CHO_DUYET`, `DA_DUYET`, `TU_CHOI`; lưu lý do từ chối. Chỉ công bố sản phẩm đã duyệt và thuộc nhà cung cấp đã duyệt.
- Đơn hàng theo `CHO_XAC_NHAN`, `DA_XAC_NHAN`, `DANG_GIAO`, `DA_GIAO`, `DA_NHAN`, `DA_HUY`; quy định rõ ai được chuyển trạng thái và điều kiện hủy. Không tự coi các tên này là yêu cầu chính thức.
- Backend lấy giá hiện hành từ CSDL, kiểm tra số lượng và tính tổng; lưu giá tại thời điểm đặt trong chi tiết đơn. Nếu trừ tồn, khóa dữ liệu phù hợp trong transaction để tránh bán vượt khi nhiều người đặt cùng lúc.
- Thống nhất thời điểm gán lô: lúc đặt hoặc lúc chuẩn bị giao. Nếu gán sau, chỉ ghi lô thực tế khi giao và kiểm tra tồn khi phân bổ. Cần xác định xử lý một dòng hàng được giao từ nhiều lô trước khi thiết kế schema.
- Chỉ người có quyền xem thông tin riêng của đơn, chỉ người mua có thể xác nhận đơn của mình; cần thống nhất điều kiện đánh giá và xử lý báo cáo. API công khai chỉ trả thông tin truy xuất cần thiết, không lộ dữ liệu cá nhân hoặc bí mật.
- Xác định cách tính doanh số theo vùng khi một sản phẩm có nhiều lô từ các vùng khác nhau; đề xuất dựa trên lô thực tế đã giao và chốt trạng thái đơn được tính vào doanh số.

