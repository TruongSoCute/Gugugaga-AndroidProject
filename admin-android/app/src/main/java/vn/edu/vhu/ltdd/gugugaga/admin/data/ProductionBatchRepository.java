package vn.edu.vhu.ltdd.gugugaga.admin.data;

import android.content.Context;

import vn.edu.vhu.ltdd.gugugaga.admin.model.TraceabilityStep;
import vn.edu.vhu.ltdd.gugugaga.admin.model.DataList;
import vn.edu.vhu.ltdd.gugugaga.admin.model.ProductionBatch;
import vn.edu.vhu.ltdd.gugugaga.admin.model.CreateBatchRequest;
import vn.edu.vhu.ltdd.gugugaga.admin.model.AddTraceabilityStepRequest;

/** API lô sản xuất và bước truy xuất. */
public class ProductionBatchRepository {
    private final Context app;

    public ProductionBatchRepository(Context ctx) {
        this.app = ctx.getApplicationContext();
    }

    /** Một trang lô sản xuất (mới nhất trước), kèm phanTrang để biết còn trang sau không. */
    public void danhSach(int trang, int kichThuoc, ApiResult<DataList<ProductionBatch>> kq) {
        ApiCall.goi(app, ApiClient.get(app).dsLo(trang, kichThuoc), true, kq);
    }

    public void chiTiet(int id, ApiResult<ProductionBatch> kq) {
        ApiCall.goi(app, ApiClient.get(app).chiTietLo(id), true, kq);
    }

    /** Mã truy xuất do server sinh; backend trả 409 nếu sản phẩm bị từ chối. */
    public void taoLo(CreateBatchRequest yeuCau, ApiResult<ProductionBatch> kq) {
        ApiCall.goi(app, ApiClient.get(app).taoLo(yeuCau), true, kq);
    }

    public void themBuoc(int loId, AddTraceabilityStepRequest yeuCau, ApiResult<TraceabilityStep> kq) {
        ApiCall.goi(app, ApiClient.get(app).themBuoc(loId, yeuCau), true, kq);
    }
}
