package vn.edu.vhu.ltdd.gugugaga.admin.model;

import java.util.List;

/** Hồ sơ nhà cung cấp cho quản trị (GET /quan-tri/nha-cung-cap và /:id). */
public class NhaCungCap {
    public int id;
    public String ten;
    public String nguoiDaiDien;
    public String soDienThoai;
    public String diaChi;
    public int vungId;
    public String tenVung;
    public String anhCoSoUrl;
    public String trangThaiDuyet;
    public String lyDoTuChoi;
    public String taoLuc;
    /** true nếu chính nhà cung cấp tự gửi hồ sơ từ app Client. */
    public boolean tuGui;

    // Chỉ có ở chi tiết
    public String duyetLuc;
    public String nguoiDuyet;
    public List<ChungNhan> chungNhan;

    public static class ChungNhan {
        public int id;
        public String loai;
        public String soHieu;
        public String ngayCap;
        public String ngayHetHan;
        public String anhUrl;
        public boolean conHieuLuc;
    }
}
