# Mô hình dữ liệu định hướng

Nguồn và cách phân biệt yêu cầu: xem [README](../README.md).

**Bắt buộc:** tối thiểu 8 bảng có khóa ngoại thật và ràng buộc hợp lý, `schema.sql` và `seed.sql` chạy lại được trên CSDL trống. Đề gợi ý các bảng sau; nhóm cần bổ sung bảng để đáp ứng toàn bộ chức năng.

| Nhóm | Bảng gợi ý | Quan hệ và ý nghĩa |
| --- | --- | --- |
| Danh mục | `vung_nguyen_lieu`, `nha_cung_cap`, `chung_nhan`, `san_pham` | Nhà cung cấp thuộc vùng, có chứng nhận và sản phẩm; sản phẩm có hạng sao, trạng thái duyệt. |
| Truy xuất | `lo_san_xuat`, `buoc_truy_xuat` | Một sản phẩm có nhiều lô, một lô có nhiều bước; mã truy xuất duy nhất. Lưu vùng, người sản xuất và ảnh phù hợp yêu cầu của lô. |
| Mua hàng | `nguoi_dung`, `don_hang`, `chi_tiet_don` | Đơn thuộc khách; chi tiết liên kết sản phẩm và lô thực tế đã giao. Cần thiết kế thêm nếu một dòng giao nhiều lô. |
| Tương tác | `danh_gia`, `bao_cao_vi_pham`, `yeu_thich`, `theo_doi_nha_cung_cap` | Lưu đánh giá, ảnh, báo cáo và quan hệ giữa người dùng với sản phẩm hoặc nhà cung cấp. |

Khóa ngoại liên kết các bản ghi hợp lệ; `UNIQUE` ngăn trùng mã lô; `NOT NULL` bảo đảm trường bắt buộc. Không dùng tên bảng trong danh sách này như một thiết kế hoàn chỉnh: nhóm cần vẽ ERD, chốt thuộc tính, quyền và vòng đời dữ liệu trước khi viết schema.

## Các cột chính được đề gợi ý

Đây là thông tin tham khảo từ bảng của đề 5, chưa phải schema cuối cùng. Nhóm cần xác định khóa, kiểu dữ liệu và trường bắt buộc phù hợp khi thiết kế.

| Bảng | Các cột chính được gợi ý |
| --- | --- |
| `vung_nguyen_lieu` | ID, tên, mô tả, vĩ độ, kinh độ. |
| `nha_cung_cap` | ID, tên, người đại diện, số điện thoại, địa chỉ, ID vùng, trạng thái duyệt, ảnh cơ sở. |
| `chung_nhan` | ID, ID nhà cung cấp, loại, số hiệu, ngày cấp, ngày hết hạn, URL ảnh. |
| `san_pham` | ID, ID nhà cung cấp, tên, mô tả, giá, hạng sao, URL ảnh, trạng thái duyệt. |
| `lo_san_xuat` | ID, ID sản phẩm, mã truy xuất, ngày sản xuất, hạn sử dụng, số lượng, ghi chú. |
| `buoc_truy_xuat` | ID, ID lô, thứ tự, tên bước, mô tả, thời điểm, URL ảnh. |
| `don_hang`, `chi_tiet_don` | Đơn có ID, ID khách, tổng tiền, trạng thái, địa chỉ giao; chi tiết ghi ID lô đã giao. |
| `bao_cao_vi_pham` | ID, ID sản phẩm, ID lô, ID người báo, nội dung, URL ảnh, trạng thái. |

Thông tin vùng nguyên liệu, người sản xuất và ảnh hiện trường của lô cũng phải được hệ thống quản lý theo yêu cầu chức năng, dù bảng lô gợi ý trong đề chưa liệt kê hết các trường này.
