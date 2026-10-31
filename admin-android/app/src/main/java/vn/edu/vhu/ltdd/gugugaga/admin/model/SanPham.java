package vn.edu.vhu.ltdd.gugugaga.admin.model;

/**
 * Một sản phẩm trong danh sách quản trị (GET /quan-tri/san-pham).
 * Tiền lưu bằng int (số đồng), chỉ định dạng khi hiển thị (Lab A9).
 */
public class SanPham {
    public int id;
    public String ten;
    public String moTa;
    public String donViTinh;
    public int gia;
    /** null khi chưa được duyệt (hạng sao do quản trị chốt lúc duyệt). */
    public Integer hangSao;
    public String anhUrl;
    public int nhaCungCapId;
    public String tenNhaCungCap;
    public String tenVung;
    public String trangThaiDuyet;
    public String trangThaiNhaCungCap;
    public String lyDoTuChoi;
}
