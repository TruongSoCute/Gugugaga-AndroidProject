package vn.edu.vhu.ltdd.gugugaga.admin.model;

import java.util.List;

/** Dạng lỗi backend trả về: { "loi": { "ma", "thongDiep", "chiTiet": [{ "truong", "thongDiep" }] } }. */
public class LoiApi {
    public Loi loi;

    public static class Loi {
        public String ma;
        public String thongDiep;
        public List<ChiTiet> chiTiet;
    }

    public static class ChiTiet {
        public String truong;
        public String thongDiep;
    }
}
