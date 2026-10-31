# Tài liệu đề tài 05

Đề tài: **Sàn đặc sản vùng và sản phẩm OCOP TP.HCM mở rộng**. Nguồn đối chiếu: [tài liệu Word](C:/Users/admin/Downloads/DoAn_CuoiKy_25DeTai_INT4211.docx) (phần A–E, đề 5 và phụ lục 4) và [slide giới thiệu](C:/Users/admin/Downloads/DoAn_CuoiKy_GioiThieu_INT4211.pptx) (slide 2–7, 9, 14–15). Hai đường dẫn nguồn chỉ dùng trên máy hiện tại; khi chia sẻ repository cần cung cấp tài liệu nguồn theo cách phù hợp.

**Phạm vi bắt buộc:** hai app riêng, gồm Admin Android Java/XML và Client Flutter/Dart cho khách; mỗi app ít nhất 6 màn hình. Hai app dùng chung backend đã deploy và cơ sở dữ liệu. Xem [Product](development/Product.md) để hiểu chức năng và [Delivery](course/Delivery.md) để biết điều kiện nộp bài.

Các mục ghi **Bắt buộc** hoặc nói rõ là yêu cầu từ đề dựa trên tài liệu giảng viên. Các mục ghi **Đề xuất** là phương án để nhóm thảo luận, chưa phải yêu cầu chính thức. Các quyết định sản phẩm chưa chốt được ghi trong [Open questions](development/Open_questions.md).

## Phát triển hệ thống

Thư mục [development](development/) dành cho việc xác định và xây dựng sản phẩm. Yêu cầu kỹ thuật trong đó vẫn bao gồm các điều bắt buộc từ đề.

| Tệp | Mục đích |
| --- | --- |
| [Goal](development/Goal.md) | Mục tiêu, bối cảnh, phạm vi và khái niệm sản phẩm so với lô. |
| [Product](development/Product.md) | Chức năng bắt buộc và phần mở rộng của hai ứng dụng. |
| [Rule](development/Rule.md) | Quy tắc nghiệp vụ bắt buộc và các quy tắc đề xuất. |
| [Tech stack](development/Tech_stack.md) | Kiến trúc, công nghệ và yêu cầu kỹ thuật của hai app. |
| [Labs Android](development/Labs_Android.md) | Kiến thức Lab A5–A9 và Phụ lục 2 (Retrofit) áp dụng cho app Admin, đối chiếu từng yêu cầu C.1. |
| [Architecture](development/Architecture.md) | Kiến trúc mã nguồn phân tầng theo miền, quy tắc phụ thuộc được kiểm tra bằng máy (đề xuất). Đọc trước khi sửa code. |
| [Data model](development/Data_model.md) | Các bảng, quan hệ và ràng buộc định hướng. |
| [API](development/API.md) | Nhóm API chính theo đề, cần chi tiết hóa khi triển khai. |
| [Testing](development/Testing.md) | Dữ liệu mẫu và các trường hợp kiểm thử hệ thống. |
| [Plan](development/Plan.md) | Thứ tự phát triển đề xuất. |
| [Open questions](development/Open_questions.md) | Các quyết định sản phẩm cần nhóm hoặc giảng viên xác nhận. |
| [Design decisions](development/Design_decisions.md) | Các phương án đề xuất backend đang áp dụng (vai trò, duyệt, mã truy xuất, gán lô), chưa xác nhận. |

## Môn học và lớp

Thư mục [course](course/) dành cho quy định học phần, mốc, chấm điểm và chuẩn bị nộp bài.

| Tệp | Mục đích |
| --- | --- |
| [Delivery](course/Delivery.md) | Mốc học phần, điểm, quy định nhóm và sản phẩm nộp. |
| [Submission checklist](course/Submission_checklist.md) | Danh sách tự kiểm trước khi nộp và demo. |

Bắt đầu bằng Goal và Product, sau đó đọc Rule và Tech stack trước khi thiết kế Data model và API. Đọc Architecture trước khi viết hoặc sửa code. Cập nhật tài liệu khi nhóm chốt quyết định hoặc triển khai thay đổi.
