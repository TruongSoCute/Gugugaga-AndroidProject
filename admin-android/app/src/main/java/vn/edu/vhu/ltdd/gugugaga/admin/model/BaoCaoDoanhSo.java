package vn.edu.vhu.ltdd.gugugaga.admin.model;

import java.util.List;

/**
 * Phản hồi GET /bao-cao/doanh-so. Tổng doanh số có thể vượt giới hạn int nên dùng long
 * (Labs_Android.md, Lab A9).
 */
public class BaoCaoDoanhSo {
    public Tong tong;
    public List<TheoVung> theoVung;
    public List<TheoHangSao> theoHangSao;
    public List<NhaCungCapBanChay> nhaCungCapBanChay;

    public static class Tong {
        public long doanhSo;
        public int soLuong;
        public int soDon;
    }

    public static class TheoVung {
        public int vungId;
        public String tenVung;
        public long doanhSo;
        public int soLuong;
    }

    public static class TheoHangSao {
        public int hangSao;
        public long doanhSo;
        public int soLuong;
    }

    public static class NhaCungCapBanChay {
        public int id;
        public String ten;
        public String tenVung;
        public long doanhSo;
        public int soLuong;
        public int soDon;
    }
}
