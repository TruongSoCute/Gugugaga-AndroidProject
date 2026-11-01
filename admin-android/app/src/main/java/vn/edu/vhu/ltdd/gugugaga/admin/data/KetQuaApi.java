package vn.edu.vhu.ltdd.gugugaga.admin.data;

import java.util.Map;

/** Kết quả một lần gọi API, trả về trên main thread. */
public interface KetQuaApi<T> {
    void thanhCong(T duLieu);

    /** Lỗi có thể hiển thị cho người dùng (lỗi mạng, 400, 403, 404, 409, 500...). */
    void loi(String thongDiep);

    /** Backend trả 401: token thiếu, sai hoặc hết hạn -> phải đăng nhập lại (C.1 #1). */
    void hetPhien();

    /**
     * Lỗi 400 có chiTiet[].truong: form dùng để setError đúng ô (Labs_Android.md, Phụ lục 2).
     * Mặc định coi như lỗi thường, nên màn hình không có form không cần viết thêm gì.
     */
    default void loiDuLieu(String thongDiep, Map<String, String> loiTheoTruong) {
        loi(thongDiep);
    }
}
