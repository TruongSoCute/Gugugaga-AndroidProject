package vn.edu.vhu.ltdd.gugugaga.admin.util;

/**
 * Các bước kiểm tra dữ liệu nhập theo Lab A4: rỗng → định dạng → miền giá trị.
 * Lớp này chỉ trả loại lỗi; màn hình chọn lời báo và gọi setError đúng ô.
 */
public final class KiemTraForm {
    public enum Loi { TRONG, SAI_DINH_DANG, NGOAI_MIEN }

    private KiemTraForm() { }

    /** Kiểm tra chuỗi là số nguyên trong [min, max]; trả null nếu hợp lệ. */
    public static Loi soNguyen(String s, int min, int max) {
        String t = s == null ? "" : s.trim();
        if (t.isEmpty()) return Loi.TRONG;
        long so;
        try {
            so = Long.parseLong(t); // dán chữ hoặc "1.5" -> NumberFormatException (Lab A4)
        } catch (NumberFormatException e) {
            return Loi.SAI_DINH_DANG;
        }
        if (so < min || so > max) return Loi.NGOAI_MIEN;
        return null;
    }

    /** Đường dẫn ảnh phải là http(s) và không chứa khoảng trắng. Chuỗi rỗng coi là không nhập. */
    public static boolean laUrlWeb(String s) {
        if (s == null) return false;
        String t = s.trim();
        if (t.isEmpty() || t.length() > 2000 || t.contains(" ")) return false;
        return (t.startsWith("https://") && t.length() > 8) || (t.startsWith("http://") && t.length() > 7);
    }

    /** Ngày dạng yyyy-MM-dd so sánh được bằng chuỗi: hạn sử dụng phải SAU ngày sản xuất. */
    public static boolean sauNgay(String ngaySau, String ngayTruoc) {
        if (ngaySau == null || ngayTruoc == null) return false;
        return ngaySau.compareTo(ngayTruoc) > 0;
    }
}
