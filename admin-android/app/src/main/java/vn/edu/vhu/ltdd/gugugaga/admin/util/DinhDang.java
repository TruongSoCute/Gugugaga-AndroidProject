package vn.edu.vhu.ltdd.gugugaga.admin.util;

import java.text.NumberFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.TimeZone;

/**
 * Định dạng hiển thị. Tiền lưu bằng int/long, chỉ định dạng khi hiện ra màn hình (Lab A9).
 * Ngày giờ dùng SimpleDateFormat vì java.time cần API 26, còn minSdk của app là 24.
 */
public final class DinhDang {
    private static final Locale VI = Locale.forLanguageTag("vi-VN");
    /** Giờ Việt Nam cố định +07:00 (không có giờ mùa hè), nên không phụ thuộc múi giờ của máy. */
    private static final TimeZone GIO_VN = TimeZone.getTimeZone("GMT+07:00");
    private static final TimeZone UTC = TimeZone.getTimeZone("UTC");

    private DinhDang() { }

    /** 320000 -> "320.000 đ" */
    public static String tien(long dong) {
        return NumberFormat.getIntegerInstance(VI).format(dong) + " đ";
    }

    /** "2026-03-02" -> "02/03/2026". Chuỗi sai dạng thì trả nguyên văn, null thì trả "". */
    public static String ngay(String yyyyMmDd) {
        if (yyyyMmDd == null) return "";
        SimpleDateFormat vao = new SimpleDateFormat("yyyy-MM-dd", Locale.US);
        vao.setLenient(false);
        try {
            return new SimpleDateFormat("dd/MM/yyyy", Locale.US).format(vao.parse(yyyyMmDd));
        } catch (ParseException e) {
            return yyyyMmDd;
        }
    }

    /** Thời điểm backend trả (UTC, vd "2026-02-27T00:00:00.000Z") -> giờ Việt Nam "27/02/2026 07:00". */
    public static String thoiDiem(String isoUtc) {
        if (isoUtc == null) return "";
        Date d = docIsoUtc(isoUtc);
        if (d == null) return isoUtc;
        SimpleDateFormat ra = new SimpleDateFormat("dd/MM/yyyy HH:mm", Locale.US);
        ra.setTimeZone(GIO_VN);
        return ra.format(d);
    }

    private static Date docIsoUtc(String s) {
        String[] mau = {"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", "yyyy-MM-dd'T'HH:mm:ss'Z'"};
        for (String m : mau) {
            SimpleDateFormat f = new SimpleDateFormat(m, Locale.US);
            f.setTimeZone(UTC);
            f.setLenient(false);
            try {
                return f.parse(s);
            } catch (ParseException ignored) {
                // thử mẫu tiếp theo
            }
        }
        return null;
    }

    /** Ngày gửi lên API: (2026, 3, 2) -> "2026-03-02". Tháng tính từ 1. */
    public static String ngayIso(int nam, int thang, int ngay) {
        return String.format(Locale.US, "%04d-%02d-%02d", nam, thang, ngay);
    }

    /**
     * Thời điểm gửi lên API phải có múi giờ (API.md): (2026, 3, 1, 7, 5) -> "2026-03-01T07:05:00+07:00".
     * Tháng tính từ 1.
     */
    public static String thoiDiemIso(int nam, int thang, int ngay, int gio, int phut) {
        return String.format(Locale.US, "%04d-%02d-%02dT%02d:%02d:00+07:00", nam, thang, ngay, gio, phut);
    }

    /** "2026-03-01T07:05:00+07:00" -> "01/03/2026 07:05" để hiện lại thời điểm người dùng vừa chọn. */
    public static String thoiDiemDaChon(String isoCoMuiGio) {
        if (isoCoMuiGio == null || isoCoMuiGio.length() < 16) return "";
        return ngay(isoCoMuiGio.substring(0, 10)) + " " + isoCoMuiGio.substring(11, 16);
    }
}
