package vn.edu.vhu.ltdd.gugugaga.admin.model;

/**
 * Body của PATCH /san-pham/:id/duyet. Trường null không được Gson gửi đi.
 * Backend vẫn tự kiểm tra lại mọi điều kiện (hạng 3–5, lý do bắt buộc khi từ chối).
 */
public class YeuCauDuyet {
    public final String trangThai;
    public final Integer hangSao;
    public final String lyDo;

    private YeuCauDuyet(String trangThai, Integer hangSao, String lyDo) {
        this.trangThai = trangThai;
        this.hangSao = hangSao;
        this.lyDo = lyDo;
    }

    public static YeuCauDuyet duyet(int hangSao) {
        return new YeuCauDuyet("DA_DUYET", hangSao, null);
    }

    public static YeuCauDuyet tuChoi(String lyDo) {
        return new YeuCauDuyet("TU_CHOI", null, lyDo);
    }
}
