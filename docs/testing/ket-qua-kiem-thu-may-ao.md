# Kết quả kiểm thử giao diện trên máy ảo Android

- **Ngày kiểm thử:** 22/11/2026
- **Thiết bị:** Android Emulator `medium_phone` (`emulator-5554`, Android 16 / API 36, `x86_64`)
- **Backend kết nối:** `https://ocop-backend.onrender.com` (Render nhánh `release`, commit `5e28f21`)
- **Crash (`logcat AndroidRuntime:E`):** 0 lỗi

## 1. Bảng kết quả kiểm thử (22 kịch bản)

| # | App | Kịch bản kiểm thử | Kết quả mong đợi | Kết quả thực tế | Trạng thái | Ảnh minh chứng |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Admin | Mở màn hình đăng nhập, nhập sai định dạng email | Báo lỗi định dạng email, không gửi API | Hiển thị đúng thông báo lỗi định dạng email | Đạt | [01_admin_login.png](screenshots/01_admin_login.png) |
| 2 | Admin | Đăng nhập `quantri@ocop.example` / `Demo@12345` | Vào tab Sản phẩm, thấy nút `Duyệt`/`Từ chối` và `+ Thêm sản phẩm` | Tải danh sách từ Render, hiển thị đủ nút duyệt & FAB | Đạt | [02_admin_sanpham.png](screenshots/02_admin_sanpham.png) |
| 3 | Admin | Mở form Thêm sản phẩm (#13) | Nạp Spinner nhà cung cấp, đủ ô nhập và nút chọn ảnh | Hiển thị đầy đủ, bố cục rõ ràng | Đạt | [03_admin_tao_sanpham.png](screenshots/03_admin_tao_sanpham.png) |
| 4 | Admin | Xem danh sách Lô sản xuất | Hiển thị mã truy xuất, ngày SX/HSD, tồn, số bước | Tải và hiển thị đúng danh sách lô | Đạt | [04_admin_lo.png](screenshots/04_admin_lo.png) |
| 5 | Admin | Mở Chi tiết lô & mã QR | Vẽ mã QR rõ nét kèm mã lô và đường dẫn truy xuất | Hiển thị QR `56CBFAF2FE651EE07C19` + link Render | Đạt | [05_admin_chitiet_lo_qr.png](screenshots/05_admin_chitiet_lo_qr.png) |
| 6 | Admin | Tab Tài khoản với vai trò `QUAN_TRI` | Hiện đủ Hồ sơ NCC, Báo cáo doanh số, Quản lý tài khoản nhân sự | Hiện đủ 3 nút và nút Đăng xuất | Đạt | [06_admin_taikhoan.png](screenshots/06_admin_taikhoan.png) |
| 7 | Admin | Xem danh sách Hồ sơ nhà cung cấp | Hiển thị trạng thái duyệt và nhãn tự gửi từ Client | Hiển thị đúng danh sách NCC | Đạt | [07_admin_nhacungcap.png](screenshots/07_admin_nhacungcap.png) |
| 8 | Admin | Mở form Thêm nhà cung cấp + chứng nhận (#13) | Đủ ô cơ sở, Spinner vùng, chọn ảnh, mục Chứng nhận OCOP | Hiển thị đầy đủ, cuộn mượt | Đạt | [08_admin_tao_ncc.png](screenshots/08_admin_tao_ncc.png) |
| 9 | Admin | Xem Báo cáo doanh số (`QUAN_TRI`) | Hiển thị tổng doanh số, biểu đồ theo vùng, hạng sao, top NCC | Hiển thị `20.143.000 đ` và 3 biểu đồ rõ ràng | Đạt | [09_admin_baocao.png](screenshots/09_admin_baocao.png) |
| 10 | Admin | Mở Quản lý tài khoản nhân sự (#12) khi backend chưa deploy bản mới | Báo lỗi 404 thân thiện + nút Thử lại, không văng app | Báo `Không có API GET /quan-tri/tai-khoan.` + `Thử lại` | Đạt (chờ deploy `release`) | [10_admin_taikhoan_quantri.png](screenshots/10_admin_taikhoan_quantri.png) |
| 11 | Admin | Xem danh sách Đơn hàng | Hiển thị mã đơn, tổng tiền, trạng thái nhiều màu | Hiển thị đủ đơn `#50` → `#46` | Đạt | [11_admin_donhang.png](screenshots/11_admin_donhang.png) |
| 12 | Admin | Xem danh sách Phản ánh | Hiển thị loại phản ánh, nội dung, trạng thái | Hiển thị đủ phản ánh với trạng thái | Đạt | [12_admin_phananh.png](screenshots/12_admin_phananh.png) |
| 13 | Admin | Đăng nhập `nhanvien@ocop.example` — tab Sản phẩm | Ẩn nút `Duyệt`/`Từ chối`, vẫn cho thêm sản phẩm | Không còn nút `Duyệt`/`Từ chối` | Đạt | [19_admin_nhanvien_sanpham.png](screenshots/19_admin_nhanvien_sanpham.png) |
| 14 | Admin | Đăng nhập `nhanvien@ocop.example` — tab Tài khoản | Ẩn `Báo cáo doanh số` và `Quản lý tài khoản nhân sự` | Chỉ hiện `Hồ sơ nhà cung cấp` và ghi chú vai trò | Đạt | [20_admin_nhanvien_taikhoan.png](screenshots/20_admin_nhanvien_taikhoan.png) |
| 15 | Admin | Xoay ngang màn hình khi đang nhập form Thêm sản phẩm | Giữ nguyên chữ đang nhập, không văng | Giữ nguyên `San pham test xoay` ở chế độ ngang | Đạt | [21_admin_xoay_ngang.png](screenshots/21_admin_xoay_ngang.png) |
| 16 | Admin | Tắt Wi-Fi và dữ liệu di động khi tải tab Lô | Báo lỗi mạng dễ hiểu + nút Thử lại, không văng | Hiện `Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại.` | Đạt | [22_admin_offline.png](screenshots/22_admin_offline.png) |
| 17 | Client | Mở Bản đồ vùng nguyên liệu (#16) từ màn hình Sản phẩm | Hiển thị OpenStreetMap + 5 điểm vùng + thẻ thông tin + nút lọc | Hiển thị đủ 5 vùng và thẻ `Cần Giờ` | Đạt | [14_client_bando.png](screenshots/14_client_bando.png) |
| 18 | Client | Xem Chi tiết sản phẩm (chưa đăng nhập) | Hiện giá, hạng sao, nhà cung cấp, chứng nhận ATTP/OCOP | Hiển thị đúng dữ liệu (ảnh mẫu seed chưa khớp tên SP — xem mục 2) | Đạt | [15_client_chitiet_sp.png](screenshots/15_client_chitiet_sp.png) |
| 19 | Client | Mở tab Truy xuất nguồn gốc (chưa đăng nhập) | Có nút quét QR và ô nhập mã | Hiển thị rõ ràng | Đạt | [16_client_truyxuat.png](screenshots/16_client_truyxuat.png) |
| 20 | Client | Nhập mã lô hợp lệ `830231545BCD5B99092C` (chưa đăng nhập) | Hiện đúng thông tin lô, chứng nhận, nút bản đồ và 4 bước | Hiển thị *Tôm khô Cần Giờ 250 g*, 4 bước, nút bản đồ | Đạt | [17_client_hanhtrinh_ok.png](screenshots/17_client_hanhtrinh_ok.png) |
| 21 | Client | Nhập mã lô không tồn tại `00000000000000000000` | Cảnh báo "Không xác minh được nguồn gốc" | Hiển thị đúng cảnh báo màu cam | Đạt | [18_client_hanhtrinh_404.png](screenshots/18_client_hanhtrinh_404.png) |
| 22 | Client | Đăng nhập `khach1@ocop.example` và xem Đơn hàng của tôi | Hiển thị danh sách đơn của khách và bộ lọc trạng thái | Tải đủ đơn `#50`, `#45`, `#40`… kèm chip lọc | Đạt | [24_client_donhang.png](screenshots/24_client_donhang.png) |

## 2. Ghi nhận & việc còn cần chạy trên điện thoại thật (Issue #4)

1. **Cần mở PR `main → release`** để Render cập nhật các API mới (`/quan-tri/tai-khoan` của #12 và trang HTML `/truy-xuat/:ma` của #14).
2. **Ảnh dữ liệu mẫu (`seed.sql` / Issue #17):** một số ảnh sản phẩm trên Render vẫn là ảnh ngẫu nhiên (ví dụ *Mật ong hoa cà phê 500 ml* đang hiện ảnh nĩa, đơn *Rau muống* hiện ảnh chó con) — cần thay URL ảnh đúng loại sản phẩm.
3. **Cần kiểm thử thêm trên điện thoại Android thật** (chưa mô phỏng trọn vẹn trên máy ảo):
   - Quét mã QR trực tiếp bằng camera (`mobile_scanner`).
   - Chụp/chọn ảnh thật từ thư viện (`image_picker`) và tải lên Supabase Storage.
   - Đánh giá đơn hàng kèm ảnh chụp thật và luồng nhà cung cấp `ncc11@ocop.example`.
