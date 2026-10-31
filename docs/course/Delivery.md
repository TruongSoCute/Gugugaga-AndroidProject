# Mốc thời gian và sản phẩm nộp

Nguồn và cách phân biệt yêu cầu: xem [README](../README.md).

| Mốc | Yêu cầu trong tài liệu |
| --- | --- |
| Tuần 8 | Đăng ký nhóm 3–5 người, đề và repo trên LMS trước 23:59 Chủ nhật; tối đa 2 nhóm/đề. |
| Tuần 9 | Nộp bản nháp use case, ERD, phân công; đổi đề hoặc xin thay công nghệ theo quy định trước hạn tương ứng. |
| Tuần 11 | Backend đã deploy, ít nhất 3 API thật, 2 màn hình mỗi app. Mốc này chiếm 1 điểm và không nộp bù. |
| Tuần 13 | Hai app gọi API thật, demo luồng nghiệp vụ chính. |
| Tuần 15 | Bảo vệ: 10 phút trình bày, 10 phút hỏi đáp, nộp toàn bộ sản phẩm. |

Nộp repo GitHub với ba thư mục `admin-android/`, `client-flutter/`, `backend/` và README hướng dẫn chạy; link API và `GET /health`; APK release của cả hai app; báo cáo PDF 20–35 trang đủ 9 mục; video demo thật có thuyết minh 5–8 phút; tài khoản thử nghiệm cho mỗi vai trò; bảng phân công có xác nhận cả nhóm. Tài liệu có chỗ gọi ba thành phần là “nhánh” nhưng phần nộp yêu cầu ba thư mục; cần thống nhất cách dùng branch trong nhóm, vẫn bảo đảm repo nộp có đủ ba thư mục.

Báo cáo gồm giới thiệu/phạm vi, phân tích yêu cầu và 5–7 use case, ERD, API, giao diện, triển khai, kiểm thử, phân công/tiến độ, tự đánh giá. Mỗi người dùng tài khoản GitHub riêng, tối thiểu 15 commit có ý nghĩa rải đều 8 tuần và hiểu phần mình làm. Nêu nguồn mã tham khảo; AI được phép nếu giải thích được mã. Tên ứng dụng, package và TAG log chứa mã nhóm.


## Cách chấm điểm

Theo phần E.1, điểm nhóm tối đa 10 điểm:

| Nội dung | Điểm |
| --- | ---: |
| Backend và cơ sở dữ liệu | 2,5 |
| App Admin Android | 2,0 |
| App Client Flutter | 2,0 |
| Tính đúng đắn nghiệp vụ, trọng tâm kỹ thuật của đề | 1,0 |
| Bảo mật và phân quyền | 0,5 |
| Mốc tuần 11 | 1,0 |
| Báo cáo và video | 1,0 |

Điểm cá nhân = điểm nhóm × hệ số đóng góp. Hệ số theo tài liệu là 1,0 khi đóng góp đầy đủ; 0,8 khi đóng góp thiếu so với phân công; 0,5 khi đóng góp rất ít; 0,0 khi không tham gia hoặc không có commit. Giảng viên quyết định dựa trên lịch sử commit, câu trả lời khi bảo vệ và tự đánh giá chéo.

## Chi tiết nộp bài và minh chứng đóng góp

- Repository được công khai hoặc, nếu để private, phải mời giảng viên. README ghi cách chạy từng phần, link API và tài khoản thử nghiệm của mỗi vai trò.
- Bảng phân công ghi người thực hiện, công việc, tỷ lệ đóng góp và chữ ký xác nhận của cả nhóm. Báo cáo phần tiến độ kèm ảnh biểu đồ đóng góp GitHub; bảng API có phương thức, tham số, phản hồi mẫu và mã lỗi.
- Mỗi thành viên dùng tài khoản GitHub riêng, cấu hình `user.email` đúng tài khoản và viết thông điệp commit mô tả công việc. Phải có ít nhất 15 commit có ý nghĩa rải đều trong 8 tuần; dồn vào hai ngày cuối sẽ bị hạ hệ số theo tài liệu.
- Theo phần E.4, sao chép mã từ nhóm khác hoặc khóa trước bị 0 điểm đồ án cho toàn nhóm. Dùng mã trên mạng không ghi nguồn bị trừ 50% điểm phần liên quan; mã có ghi nguồn được chấp nhận nếu hiểu và giải thích được. Dùng AI được phép nhưng phải hiểu và giải thích mã khi được hỏi.

## Thông tin lớp cần xác nhận

- Mã nhóm: **gugugaga** (đã xác nhận).
- Thành viên, phân công và lịch tuần thực tế; trạng thái đăng ký đề và các hạn nộp trên LMS.
