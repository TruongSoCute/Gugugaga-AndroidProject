package vn.edu.vhu.ltdd.gugugaga.admin.data;

/** Kết quả một lần gọi API, trả về trên main thread. */
public interface KetQuaApi<T> {
    void thanhCong(T duLieu);

    /** Lỗi có thể hiển thị cho người dùng (lỗi mạng, 400, 403, 404, 409, 500...). */
    void loi(String thongDiep);

    /** Backend trả 401: token thiếu, sai hoặc hết hạn -> phải đăng nhập lại (C.1 #1). */
    void hetPhien();
}
