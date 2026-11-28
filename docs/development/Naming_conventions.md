# Đề xuất quy ước đặt tên tiếng Anh

Tên kỹ thuật trong PostgreSQL, backend, Admin và Client dùng chung từ vựng tiếng Anh. Mỗi nền tảng dùng kiểu chữ phù hợp với công cụ của nó. Ví dụ, một lô sản xuất là `production_batches` trong SQL, `ProductionBatch.java` trong Admin và `production_batch.dart` trong Flutter.

Đợt đầu đổi định danh nội bộ. Các API hiện tại vẫn nhận và trả đúng hợp đồng đang được APK sử dụng, kể cả đường dẫn công khai `/truy-xuat/:ma` đã in trong mã QR. Nội dung hiển thị trong ứng dụng được viết bằng tiếng Việt. Một API tiếng Anh có thể phát hành qua `/api/v2` sau khi thiết kế hợp đồng riêng.

## Quy ước theo nền tảng

| Nơi sử dụng | Quy ước | Ví dụ |
| --- | --- | --- |
| Bảng PostgreSQL | Danh từ số nhiều, `snake_case` | `products`, `production_batches` |
| Cột PostgreSQL | `snake_case`. ID tham chiếu có hậu tố `_id`, thời điểm dùng `_at`, ngày theo lịch dùng `_on` | `supplier_id`, `created_at`, `expires_on` |
| Index, constraint, sequence | Tên bảng và cột liên quan, kèm hậu tố xác định loại | `products_supplier_id_idx`, `products_supplier_id_fkey`, `products_id_seq` |
| Miền và file Node.js | `kebab-case`. File trong miền dùng tên tầng đã quy định | `domains/issue-reports/repo.js`, `test/production-batches.test.js` |
| Biến, hàm JavaScript | `camelCase` | `listProducts`, `createProductionBatch` |
| Java | Lớp và tên file `PascalCase`, hàm và biến `camelCase`, package chữ thường | `ProductRepository.java`, `ui.product` |
| Tài nguyên Android | Tên file và ID `snake_case` | `fragment_product_list.xml`, `ic_tab_products.xml`, `tab_products` |
| Flutter | File `snake_case`, lớp `PascalCase`, hàm và biến `camelCase` | `product_list_screen.dart`, `ProductListScreen` |
| API tiếng Anh nếu có | Đường dẫn tài nguyên số nhiều dạng `kebab-case`, khóa JSON `camelCase` | `/api/v2/production-batches`, `traceabilityCode` |

Các tên dữ liệu sau mô tả bảng ứng dụng trong schema `public`. Địa chỉ và tên database kết nối lấy theo `DATABASE_URL`. Tên app, package gốc và TAG log chứa mã nhóm `gugugaga` theo quy định học phần. [Kiến trúc](Architecture.md) · [Quy trình nhóm](Contributing.md)

## Bảng và cột PostgreSQL

| Bảng hiện tại | Tên đề xuất | Cột đặc thù |
| --- | --- | --- |
| `vung_nguyen_lieu` | `sourcing_regions` | `vi_do` → `latitude`, `kinh_do` → `longitude` |
| `nguoi_dung` | `users` | `mat_khau_hash` → `password_hash`, `ho_ten` → `full_name`, `vai_tro` → `role`, `dang_hoat_dong` → `is_active` |
| `nha_cung_cap` | `suppliers` | `nguoi_dai_dien` → `representative_name`, `dia_chi` → `address`, `anh_co_so_url` → `facility_image_url`, `tai_khoan_id` → `account_id` |
| `chung_nhan` | `certificates` | `loai` → `certificate_type`, `so_hieu` → `certificate_number`, `ngay_cap` → `issued_on`, `ngay_het_han` → `expires_on` |
| `san_pham` | `products` | `don_vi_tinh` → `unit`, `gia` → `price_vnd`, `hang_sao` → `ocop_rating` |
| `lo_san_xuat` | `production_batches` | `ma_truy_xuat` → `traceability_code`, `ngay_san_xuat` → `produced_on`, `han_su_dung` → `expires_on`, `so_luong_con` → `available_quantity`, `nguoi_san_xuat` → `producer_name`, `anh_hien_truong_url` → `site_image_url` |
| `buoc_truy_xuat` | `traceability_steps` | `thu_tu` → `position`, `ten_buoc` → `name`, `thoi_diem` → `occurred_at` |
| `gio_hang` | `cart_items` | `them_luc` → `added_at`. Mỗi dòng là một mặt hàng của người dùng |
| `don_hang` | `orders` | `hinh_thuc_giao` → `delivery_method`, `phi_giao` → `delivery_fee_vnd`, `tien_hang` → `subtotal_vnd`, `tong_tien` → `total_vnd`, `ten_nguoi_nhan` → `recipient_name`, `sdt_nguoi_nhan` → `recipient_phone`, `dia_chi_giao` → `delivery_address` |
| `chi_tiet_don` | `order_items` | `don_gia` → `unit_price_vnd`. Mỗi dòng gắn với một lô giao hàng |
| `lich_su_trang_thai_don` | `order_status_history` | `nguoi_thuc_hien_id` → `changed_by_user_id`, `thoi_diem` → `changed_at` |
| `danh_gia` | `reviews` | `so_sao` → `rating`, `noi_dung` → `comment` |
| `anh_danh_gia` | `review_images` | `danh_gia_id` → `review_id` |
| `bao_cao_vi_pham` | `issue_reports` | `nguoi_bao_id` → `reporter_id`, `loai` → `report_type`, `noi_dung` → `description`, `ket_qua_xu_ly` → `resolution`, `nguoi_xu_ly_id` → `handled_by_user_id`, `xu_ly_luc` → `handled_at` |
| `yeu_thich` | `product_favorites` | Khóa chính ghép `(user_id, product_id)` |
| `theo_doi_nha_cung_cap` | `supplier_follows` | Khóa chính ghép `(user_id, supplier_id)` |

Áp dụng ánh xạ chung ở các bảng có cùng ý nghĩa:

| Cột hiện tại | Tên đề xuất |
| --- | --- |
| `id`, `email` | `id`, `email` |
| `ten`, `mo_ta`, `ghi_chu` | `name`, `description`, `notes` |
| `so_dien_thoai`, `anh_url`, `so_luong` | `phone_number`, `image_url`, `quantity` |
| `vung_id`, `vung_nguyen_lieu_id` | `sourcing_region_id` |
| `nguoi_dung_id`, `khach_id`, `nha_cung_cap_id` | `user_id`, `customer_id`, `supplier_id` |
| `san_pham_id`, `lo_id`, `don_hang_id` | `product_id`, `batch_id`, `order_id` |
| `trang_thai`, `trang_thai_duyet`, `ly_do_tu_choi` | `status`, `approval_status`, `rejection_reason` |
| `nguoi_duyet_id`, `nguoi_tao_id` | `reviewed_by_user_id`, `created_by_user_id` |
| `duyet_luc`, `tao_luc`, `cap_nhat_luc` | `reviewed_at`, `created_at`, `updated_at` |

`reviewed_at` là thời điểm xử lý duyệt và dùng được cho cả quyết định duyệt lẫn từ chối. `price_vnd` và `unit_price_vnd` nói rõ đơn vị tiền và phân biệt giá hiện hành với giá đã chốt trong đơn. [Schema hiện tại](../../backend/db/schema.sql)

## Miền backend và tên file

| Miền hiện tại | Tên đề xuất |
| --- | --- |
| `he-thong` | `health` |
| `tai-khoan` | `accounts` |
| `danh-muc` | `sourcing-regions` |
| `nha-cung-cap` | `suppliers` |
| `san-pham` | `products` |
| `truy-xuat` | `traceability` |
| `don-hang` | `orders` |
| `danh-gia` | `reviews` |
| `phan-anh` | `issue-reports` |
| `tuong-tac` | `customer-interactions` |
| `bao-cao` | `sales-reports` |
| `tai-len` | `uploads` |

| File hoặc tài nguyên hiện tại | Tên đề xuất |
| --- | --- |
| `backend/src/domains/san-pham/repo.js` | `backend/src/domains/products/repo.js` |
| `backend/test/luong-truy-xuat.test.js` | `backend/test/traceability-flow.test.js` |
| `client-flutter/lib/data/san_pham_repository.dart` | `client-flutter/lib/data/product_repository.dart` |
| `client-flutter/lib/screens/chi_tiet_san_pham_screen.dart` | `client-flutter/lib/screens/product_details_screen.dart` |
| `client-flutter/lib/screens/tra_cuu_screen.dart` | `client-flutter/lib/screens/traceability_lookup_screen.dart` |
| `client-flutter/lib/widgets/thanh_dieu_huong_noi.dart` | `client-flutter/lib/widgets/floating_navigation_bar.dart` |
| `ui/sanpham/SanPhamFragment.java` | `ui/product/ProductListFragment.java` |
| `ui/lo/ChiTietLoFragment.java` | `ui/batch/BatchDetailsFragment.java` |
| `res/layout/fragment_san_pham.xml` | `res/layout/fragment_product_list.xml` |
| `res/drawable/ic_tab_san_pham.xml` | `res/drawable/ic_tab_products.xml` |

Khi đổi tên một file hoặc lớp, cập nhật cùng lượt các import, package, manifest, XML, tham chiếu `R.`, mock và fixture liên quan. Tên file tầng backend tiếp tục là `types.js`, `config.js`, `repo.js`, `service.js`, `routes.js`, `index.js`. Dùng các lớp và thư mục kiến trúc hiện có để bộ kiểm tra tầng tiếp tục có hiệu lực. [Kiến trúc](Architecture.md) · [Labs Android](Labs_Android.md)

## Tương thích với APK và QR hiện tại

Một thuộc tính đi qua ba lớp. Chẳng hạn, PostgreSQL có `traceability_code`, repository ánh xạ kết quả SQL về `ma_truy_xuat` và API hiện tại trả `maTruyXuat`. Ánh xạ tường minh giúp mỗi lớp dùng tên riêng mà vẫn truyền đúng giá trị. Hàm chuyển `snake_case` sang `camelCase` chỉ đổi kiểu chữ, nên cần thêm ánh xạ rõ ràng cho khóa JSON, tham số truy vấn và payload hiện tại.

- Backend dùng định danh SQL mới trong repo. Service, router và bộ tuần tự hóa trả về khóa JSON, mã lỗi, trạng thái và mã HTTP theo hợp đồng đã công bố.
- Java giữ hợp đồng bằng Retrofit và `@SerializedName`. Flutter đọc và ghi các khóa cũ trong `fromJson` và payload của repository.
- Các giá trị vai trò và trạng thái đang lưu, như `QUAN_TRI` và `DA_DUYET`, thuộc hợp đồng hiện tại. Nếu đổi sang tiếng Anh, xử lý trong đợt riêng có ánh xạ ở cả hai chiều.
- URL ảnh Storage đã được ghi trong dữ liệu và mã QR đã in là các định danh bên ngoài. Phiên bản API tiếng Anh trong tương lai cần song song với tuyến công khai hiện tại trong thời gian hỗ trợ APK và QR cũ.

[Hợp đồng API hiện tại](API.md)

## Trình tự triển khai và kiểm tra

1. Đổi tên miền, file và code nội bộ theo nhóm chức năng. Kiểm tra import, View Binding, cấu hình build, script và tài liệu bằng cách tìm tên cũ còn tham chiếu. Kỳ vọng các tên kỹ thuật cũ còn xuất hiện ở hợp đồng API hiện tại và trong migration.
2. Tạo migration PostgreSQL theo chiều đi và chiều lùi bằng `ALTER TABLE … RENAME`, `RENAME COLUMN`, `RENAME CONSTRAINT`, `ALTER INDEX … RENAME` và `ALTER SEQUENCE … RENAME`. So sánh schema từ migration với schema tạo mới. Dùng giao dịch và giới hạn thời gian chờ khóa khi đổi tên. [ALTER TABLE](https://www.postgresql.org/docs/current/sql-altertable.html) · [ALTER SEQUENCE](https://www.postgresql.org/docs/current/sql-altersequence.html)
3. Đồng bộ `schema.sql`, `seed.sql`, SQL trong repo, tên fixture và tài liệu. Trên DB kiểm thử riêng, so sánh số dòng, khóa chính, khóa ngoại, mã QR, giá trị sequence và trạng thái RLS trước và sau migration. Kiểm tra cặp `(batch_id, product_id)` trong đơn hàng và phản ánh.
4. Chạy `npm run check:arch`, `npm test`, `gradlew.bat testDebugUnitTest` và `flutter test`. Kiểm tra thêm đăng nhập, danh mục công khai, truy xuất QR, đặt hàng và ảnh. Đối chiếu hợp đồng bằng yêu cầu từ cả APK hiện tại và bản build mới.
5. Trên DB có dữ liệu, áp dụng migration đầu qua MCP để đổi tên 15 bảng và tạo view tương thích. Sau khi bản backend mới chạy trên Render, áp dụng migration đổi tên bảng đánh giá. Cả hai bước có SQL hoàn tác. Gọi lại URL QR cũ và kiểm tra ảnh đã lưu sau mỗi bước. [Trình tự triển khai](../../backend/README.md#đổi-tên-định-danh-postgresql)
