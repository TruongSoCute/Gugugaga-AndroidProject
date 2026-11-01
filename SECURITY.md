# Chính sách bảo mật

## Phiên bản được hỗ trợ

Chỉ **bản phát hành mới nhất** trên [GitHub Releases](https://github.com/TruongSoCute/Gugugaga-AndroidProject/releases) và backend đang chạy tại https://ocop-backend.onrender.com được sửa lỗi bảo mật. Các bản cũ hơn không được cập nhật; hãy cài bản mới nhất.

| Thành phần | Được hỗ trợ |
| --- | --- |
| Backend trên nhánh `release` (đã deploy) | ✓ |
| App Admin, app Client: bản mới nhất trên Releases | ✓ |
| Bản phát hành cũ, nhánh tính năng | ✗ |

## Báo cáo lỗ hổng

**Không mở issue công khai** cho lỗ hổng bảo mật. Hãy báo riêng bằng một trong hai cách:

1. Tab **Security → Report a vulnerability** của repository (GitHub Private Vulnerability Reporting).
2. Email **qtruong.hs@gmail.com**, tiêu đề bắt đầu bằng `[BAO MAT]`.

Nội dung nên có:

- thành phần bị ảnh hưởng (backend API, app Admin, app Client) và phiên bản;
- các bước tái hiện, request/response mẫu (che token, mật khẩu);
- tác động có thể xảy ra (lộ dữ liệu, vượt quyền, sửa dữ liệu của người khác…).

Đây là đồ án học phần do sinh viên duy trì, nên thời gian phản hồi là **nỗ lực tốt nhất**: thường xác nhận đã nhận trong vòng 3 ngày và báo kế hoạch xử lý trong vòng 7 ngày. Bản sửa được phát hành qua nhánh `release`; người báo được ghi nhận trong ghi chú phát hành nếu muốn.

## Phạm vi

Trong phạm vi:

- vượt quyền: khách gọi được API nhân sự, nhà cung cấp xem hoặc sửa dữ liệu của nhà cung cấp khác, xem đơn của người khác;
- lộ dữ liệu nhạy cảm qua API (mật khẩu băm, email, số điện thoại) hoặc qua API truy xuất công khai;
- SQL injection, bỏ qua kiểm tra JWT, đoán được mã truy xuất của lô;
- tải tệp không phải ảnh lên kho ảnh, lộ khóa dịch vụ trong app hoặc repository.

Ngoài phạm vi:

- tài khoản thử nghiệm và mật khẩu `Demo@12345` ghi trong README: đây là **tài khoản demo công khai** theo yêu cầu nộp bài;
- dữ liệu mẫu giả lập (tên cơ sở có hậu tố "(mẫu)", số hiệu `MAU-…`);
- backend trên Render gói Free khởi động chậm sau khi ngủ;
- tấn công từ chối dịch vụ, spam, tấn công vật lý hoặc lừa đảo thành viên.

## Khi kiểm tra

- Chỉ dùng tài khoản demo hoặc tài khoản của chính bạn; không truy cập, sửa hay xóa dữ liệu của người khác.
- Không chạy công cụ quét tự động cường độ cao vào backend đã deploy; ưu tiên chạy backend trên máy theo [Setup](docs/development/Setup.md).
- Không công bố chi tiết lỗ hổng trước khi bản sửa được phát hành.

## Thiết kế bảo mật hiện có

Mật khẩu băm bằng bcrypt; JWT ký HS256 có hạn dùng, backend đọc lại vai trò trong CSDL ở mỗi request; SQL luôn tham số hóa; mã truy xuất 80 bit ngẫu nhiên; mọi bảng Supabase bật RLS không policy; khóa dịch vụ chỉ nằm trong biến môi trường của Render. Chi tiết: [Architecture](docs/development/Architecture.md) và [Design decisions](docs/development/Design_decisions.md).
