package vn.edu.vhu.ltdd.gugugaga.admin.ui.supplier;

import android.app.Application;

import androidx.annotation.NonNull;

import vn.edu.vhu.ltdd.gugugaga.admin.data.ApiResult;
import vn.edu.vhu.ltdd.gugugaga.admin.data.SupplierRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.model.DataList;
import vn.edu.vhu.ltdd.gugugaga.admin.model.Supplier;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.FilteredListViewModel;

public class SupplierListViewModel extends FilteredListViewModel<Supplier> {
    private final SupplierRepository repo;

    public SupplierListViewModel(@NonNull Application app) {
        super(app);
        repo = new SupplierRepository(app);
    }

    @Override
    protected void goiTrang(String loc, int trang, int kichThuoc, ApiResult<DataList<Supplier>> kq) {
        repo.danhSach(loc, trang, kichThuoc, kq);
    }
}
