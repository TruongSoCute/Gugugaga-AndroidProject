package vn.edu.vhu.ltdd.gugugaga.admin.ui.supplier;

import android.app.Application;

import androidx.annotation.NonNull;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.data.ApiResult;
import vn.edu.vhu.ltdd.gugugaga.admin.data.SupplierRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.model.Supplier;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.DetailsViewModel;

public class SupplierDetailsViewModel extends DetailsViewModel<Supplier> {
    private final SupplierRepository repo;

    public SupplierDetailsViewModel(@NonNull Application app) {
        super(app);
        repo = new SupplierRepository(app);
    }

    @Override
    protected void goiChiTiet(int id, ApiResult<Supplier> kq) {
        repo.chiTiet(id, kq);
    }

    public void duyet(String ten) {
        if (!batDauGui()) return;
        repo.duyet(id, ketQuaThaoTac(chuoi(R.string.da_duyet_ho_so, ten)));
    }

    public void tuChoi(String ten, String lyDo) {
        if (!batDauGui()) return;
        repo.tuChoi(id, lyDo, ketQuaThaoTac(chuoi(R.string.da_tu_choi, ten)));
    }
}
