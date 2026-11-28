package vn.edu.vhu.ltdd.gugugaga.admin.model;

/**
 * Body của PATCH /san-pham/:id/duyet và PATCH /nha-cung-cap/:id/duyet. Trường null không được Gson gửi đi.
 * Backend vẫn tự kiểm tra lại mọi điều kiện (hạng 3–5, lý do bắt buộc khi từ chối).
 */
public class ReviewRequest {
    public final String trangThai;
    public final Integer hangSao;
    public final String lyDo;

    private ReviewRequest(String trangThai, Integer hangSao, String lyDo) {
        this.trangThai = trangThai;
        this.hangSao = hangSao;
        this.lyDo = lyDo;
    }

    public static ReviewRequest duyet(int hangSao) {
        return new ReviewRequest("DA_DUYET", hangSao, null);
    }

    /** Duyệt hồ sơ nhà cung cấp: không có hạng sao. */
    public static ReviewRequest duyetHoSo() {
        return new ReviewRequest("DA_DUYET", null, null);
    }

    public static ReviewRequest tuChoi(String lyDo) {
        return new ReviewRequest("TU_CHOI", null, lyDo);
    }
}
