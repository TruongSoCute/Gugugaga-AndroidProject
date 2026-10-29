# Mục tiêu dự án

Nguồn và cách phân biệt yêu cầu: xem [README](../README.md).

**Bắt buộc:** Xây dựng hệ thống bán đặc sản vùng và sản phẩm OCOP, giúp người mua kiểm tra nguồn gốc hàng hóa. Hệ thống gồm app Android cho quản trị, app Flutter cho khách và backend công khai trên Internet; hai app dùng chung cơ sở dữ liệu. Trọng tâm là mỗi **lô sản xuất** có mã QR riêng và hành trình riêng, người cầm sản phẩm có thể truy xuất mà không cần đăng nhập.

**Điều kiện hoàn thành:** Phải có cả app Admin Android và app người dùng Flutter, mỗi app ít nhất 6 màn hình, cùng kết nối backend đã deploy và cơ sở dữ liệu chung. Cần nộp APK release của từng app. App người dùng không phải chức năng tùy chọn; xem [Product](Product.md) để biết đầy đủ chức năng của mỗi app.

**Bối cảnh theo đề:** Các vùng ví dụ gồm Cần Giờ, Củ Chi và Bà Rịa – Vũng Tàu, với đặc sản như khô cá dứa, yến, hạt điều, muối và tiêu. Người mua trực tuyến thiếu tin tưởng về nguồn gốc; truy xuất từng lô giúp cung cấp thông tin để họ kiểm tra. Đây là ví dụ bối cảnh, không phải giới hạn danh mục.

**Đề xuất phạm vi:** Nhóm quản trị vận hành sàn, duyệt thông tin nhà cung cấp, sản phẩm và lô; khách tìm sản phẩm, mua hàng và phản ánh. Đề không yêu cầu xây app riêng cho nhà cung cấp hoặc tích hợp thanh toán và hãng vận chuyển thực tế. Có thể quản lý giao hàng bằng trạng thái và dữ liệu mẫu; cần làm rõ với giảng viên trước khi chốt nếu nhóm muốn triển khai theo cách này.

**Khái niệm cần phân biệt:** Sản phẩm là mặt hàng chung, ví dụ “Khô cá dứa 500 g”. Lô là một đợt sản xuất cụ thể của sản phẩm đó, có ngày sản xuất, số lượng và hành trình riêng. Hai lô cùng sản phẩm phải có QR khác nhau và có thể có các bước khác nhau. Quét QR lô A phải trả dữ liệu của lô A, không chỉ trả trang chung của sản phẩm.
