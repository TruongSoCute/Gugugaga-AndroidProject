# Dữ liệu mẫu và kiểm thử

Nguồn và cách phân biệt yêu cầu: xem [README](../README.md).

**Bắt buộc:** ít nhất 4 vùng, 12 nhà cung cấp, 60 sản phẩm, 100 lô với đủ 4 bước truy xuất mỗi lô, 50 đơn. Dữ liệu phải thể hiện được báo cáo, các trạng thái và mối liên kết có ý nghĩa.

**Đề xuất kiểm thử trọng tâm:**

1. Hai lô cùng một sản phẩm có QR khác nhau; quét từng mã trả đúng hành trình và ảnh của lô tương ứng khi chưa đăng nhập.
2. Mã không tồn tại trả 404; mã trùng bị ràng buộc duy nhất từ chối; không lộ thông tin riêng trong truy xuất công khai.
3. Đăng nhập sai hoặc thiếu token bị từ chối; khách gọi API quản trị bị 403; kiểm tra trực tiếp bằng Postman.
4. Duyệt nhà cung cấp và sản phẩm, sau đó kiểm tra dữ liệu tương ứng trong client; lọc theo vùng và sao.
5. Đặt đơn, kiểm tra tổng tiền phía server, trạng thái, lô thực tế giao; thử dữ liệu sai và giao dịch lỗi để kiểm tra rollback.
6. Gửi đánh giá có ảnh, báo cáo và xử lý; yêu thích và theo dõi; kiểm tra khách không sửa đơn của người khác.
7. Kiểm thử báo cáo theo vùng, sao, nhà cung cấp với dữ liệu đã biết; mất mạng, ảnh lỗi, xoay màn hình, token hết hạn.

Kịch bản kiểm thử app Admin rút từ các lab (form, xoay màn hình, back stack, lỗi mạng, 401, quyền): xem [Labs Android](Labs_Android.md#kiểm-thử-app-admin-rút-từ-lab-đề-xuất).

Báo cáo cuối kỳ cần ít nhất 25 trường hợp kiểm thử kèm kết quả thực tế đạt hoặc không đạt. Không đánh dấu đã đạt khi chưa chạy.

Xem [danh sách tự kiểm trước khi nộp](../course/Submission_checklist.md) để kiểm tra các yêu cầu của môn học.
