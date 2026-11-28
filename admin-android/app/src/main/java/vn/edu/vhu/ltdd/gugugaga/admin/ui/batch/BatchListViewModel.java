package vn.edu.vhu.ltdd.gugugaga.admin.ui.batch;

import android.app.Application;

import androidx.annotation.NonNull;

import vn.edu.vhu.ltdd.gugugaga.admin.data.ApiResult;
import vn.edu.vhu.ltdd.gugugaga.admin.data.ProductionBatchRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.model.DataList;
import vn.edu.vhu.ltdd.gugugaga.admin.model.ProductionBatch;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.FilteredListViewModel;

/** Danh sách lô không có bộ lọc: dùng taiLanDau(); cuộn gần cuối thì tải thêm trang sau. */
public class BatchListViewModel extends FilteredListViewModel<ProductionBatch> {
    private final ProductionBatchRepository repo;

    public BatchListViewModel(@NonNull Application app) {
        super(app);
        repo = new ProductionBatchRepository(app);
    }

    @Override
    protected void goiTrang(String loc, int trang, int kichThuoc, ApiResult<DataList<ProductionBatch>> kq) {
        repo.danhSach(trang, kichThuoc, kq);
    }
}
