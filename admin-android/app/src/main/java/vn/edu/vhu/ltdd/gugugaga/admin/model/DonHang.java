package vn.edu.vhu.ltdd.gugugaga.admin.model;

import java.util.List;

/**
 * Đơn hàng: dòng trong GET /quan-tri/don-hang và chi tiết GET /quan-tri/don-hang/:id.
 * Các trường chỉ có ở chi tiết (người nhận, chiTiet, lichSu...) là null trong danh sách.
 * Tiền lưu bằng int (số đồng).
 */
public class DonHang {
    public int id;
    public String trangThai;
    public String hinhThucGiao;
    public int tongTien;
    public String taoLuc;
    public String capNhatLuc;
    public int khachId;
    public String tenKhach;
    public String tenNguoiNhan;

    // Chỉ có ở danh sách
    public int soSanPham;
    public String tenSanPhamDau;

    // Chỉ có ở chi tiết
    public String emailKhach;
    public String sdtNguoiNhan;
    public String diaChiGiao;
    public String ghiChu;
    public int phiGiao;
    public int tienHang;
    public List<DongDon> chiTiet;
    public List<LichSuDon> lichSu;

    /** Một dòng hàng; mỗi lô đã giao là một dòng, kèm mã truy xuất của lô đó. */
    public static class DongDon {
        public int sanPhamId;
        public String tenSanPham;
        public String donViTinh;
        public int loId;
        public String maTruyXuat;
        public String ngaySanXuat;
        public String vungNguyenLieu;
        public int soLuong;
        public int donGia;
        public int thanhTien;
    }

    /** Một lần chuyển trạng thái. */
    public static class LichSuDon {
        public String trangThai;
        public String ghiChu;
        public String thoiDiem;
        public String nguoiThucHien;
    }
}
