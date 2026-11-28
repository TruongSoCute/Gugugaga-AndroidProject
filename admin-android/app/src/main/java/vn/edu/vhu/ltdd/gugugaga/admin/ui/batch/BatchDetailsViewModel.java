package vn.edu.vhu.ltdd.gugugaga.admin.ui.batch;

import android.app.Application;

import androidx.annotation.NonNull;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.data.ApiResult;
import vn.edu.vhu.ltdd.gugugaga.admin.data.ProductionBatchRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.model.TraceabilityStep;
import vn.edu.vhu.ltdd.gugugaga.admin.model.ProductionBatch;
import vn.edu.vhu.ltdd.gugugaga.admin.model.AddTraceabilityStepRequest;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.DetailsViewModel;

public class BatchDetailsViewModel extends DetailsViewModel<ProductionBatch> {
    private final ProductionBatchRepository repo;

    public BatchDetailsViewModel(@NonNull Application app) {
        super(app);
        repo = new ProductionBatchRepository(app);
    }

    @Override
    protected void goiChiTiet(int id, ApiResult<ProductionBatch> kq) {
        repo.chiTiet(id, kq);
    }

    /** Thêm xong thì tải lại chi tiết để thấy bước mới đúng thứ tự. */
    public void themBuoc(AddTraceabilityStepRequest yeuCau) {
        if (!batDauGui()) return;
        ApiResult<TraceabilityStep> kq = ketQuaThaoTacRoiTaiLai(chuoi(R.string.da_them_buoc, yeuCau.tenBuoc));
        repo.themBuoc(id, yeuCau, kq);
    }
}
