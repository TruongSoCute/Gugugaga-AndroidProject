package vn.edu.vhu.ltdd.gugugaga.admin.data;

import android.content.Context;

import java.util.List;

import vn.edu.vhu.ltdd.gugugaga.admin.model.BuocTruyXuat;
import vn.edu.vhu.ltdd.gugugaga.admin.model.LoSanXuat;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauTaoLo;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauThemBuoc;

/** API lô sản xuất và bước truy xuất. */
public class LoSanXuatRepository {
    private static final int KICH_THUOC_TRANG = 100;

    private final Context app;

    public LoSanXuatRepository(Context ctx) {
        this.app = ctx.getApplicationContext();
    }

    /** 100 lô mới nhất (giới hạn một trang của backend). */
    public void danhSach(KetQuaApi<List<LoSanXuat>> kq) {
        GoiApi.goi(app, ApiClient.get(app).dsLo(1, KICH_THUOC_TRANG), true, GoiApi.chiLayDuLieu(kq));
    }

    public void chiTiet(int id, KetQuaApi<LoSanXuat> kq) {
        GoiApi.goi(app, ApiClient.get(app).chiTietLo(id), true, kq);
    }

    /** Mã truy xuất do server sinh; backend trả 409 nếu sản phẩm bị từ chối. */
    public void taoLo(YeuCauTaoLo yeuCau, KetQuaApi<LoSanXuat> kq) {
        GoiApi.goi(app, ApiClient.get(app).taoLo(yeuCau), true, kq);
    }

    public void themBuoc(int loId, YeuCauThemBuoc yeuCau, KetQuaApi<BuocTruyXuat> kq) {
        GoiApi.goi(app, ApiClient.get(app).themBuoc(loId, yeuCau), true, kq);
    }
}
