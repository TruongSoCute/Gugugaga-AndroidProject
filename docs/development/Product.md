# Phạm vi và chức năng sản phẩm

Nguồn và cách phân biệt yêu cầu: xem [README](../README.md).

## Hai ứng dụng đều bắt buộc

Đây là một hệ thống gồm **hai app riêng**: app Admin cho quản lý và app Client cho khách hàng. Mỗi app có ít nhất 6 màn hình, cần được xây dựng, kết nối với cùng backend và cơ sở dữ liệu, rồi đóng gói thành APK release riêng để nộp. Không thể hoàn thành đề chỉ với app Admin. Backend phải được deploy và truy cập được trên Internet.

Ví dụ luồng chung: Admin duyệt sản phẩm, tạo lô và các bước truy xuất; Client tải dữ liệu sản phẩm và quét mã của lô đó để xem hành trình. Người quét không cần đăng nhập để xem truy xuất. Xem thêm [Tech stack](Tech_stack.md) và [Delivery](../course/Delivery.md) để đối chiếu yêu cầu kỹ thuật và sản phẩm nộp.

## Chức năng bắt buộc

### Admin Android Java và XML

- Duyệt hồ sơ nhà cung cấp, giấy chứng nhận OCOP và ảnh cơ sở sản xuất.
- Duyệt sản phẩm và hạng OCOP 3, 4 hoặc 5 sao.
- Quản lý lô: ngày sản xuất, vùng nguyên liệu, người sản xuất, ảnh hiện trường; tạo mã QR duy nhất cho từng lô.
- Quản lý đơn hàng và vận chuyển liên vùng.
- Xử lý báo cáo hàng giả hoặc sai mô tả của người mua.
- Báo cáo doanh số theo vùng nguyên liệu, hạng sao và nhà cung cấp bán tốt nhất.

### Client Flutter

- Duyệt và lọc sản phẩm theo vùng và hạng sao; xem thông tin sản phẩm, nhà cung cấp và chứng nhận.
- Quét QR trên bao bì để xem toàn bộ hành trình của đúng lô, kể cả khi chưa đăng nhập.
- Giỏ hàng, đặt hàng và chọn hình thức giao; theo dõi đơn và xác nhận đã nhận.
- Đánh giá sản phẩm kèm ảnh thật, báo cáo hàng nghi giả; lưu sản phẩm yêu thích và theo dõi nhà cung cấp.

## Tính năng mở rộng, chỉ làm sau phần bắt buộc

Trang truy xuất trên trình duyệt bằng HTML, bản đồ vùng nguyên liệu và tự động khóa bán khi chứng nhận hết hạn là các gợi ý mở rộng trong đề. Endpoint truy xuất công khai là bắt buộc; trang HTML trình duyệt là phần mở rộng.

