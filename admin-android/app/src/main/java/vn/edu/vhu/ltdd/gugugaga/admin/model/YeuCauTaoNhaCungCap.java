
package vn.edu.vhu.ltdd.gugugaga.admin.model;

import java.util.List;

public class YeuCauTaoNhaCungCap {
    public String ten;
    public String nguoiDaiDien;
    public String soDienThoai;
    public String diaChi;
    public int vungId;
    public String anhCoSoUrl;
    public List<ChungNhan> chungNhan;

    public static class ChungNhan {
        public String loai;
        public String soHieu;
        public String ngayCap;
        public String ngayHetHan;
        public String anhUrl;
    }
}
