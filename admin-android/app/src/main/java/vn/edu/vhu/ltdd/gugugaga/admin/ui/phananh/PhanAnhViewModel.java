package vn.edu.vhu.ltdd.gugugaga.admin.ui.phananh;

import android.app.Application;

import androidx.annotation.NonNull;

import java.util.List;

import vn.edu.vhu.ltdd.gugugaga.admin.data.KetQuaApi;
import vn.edu.vhu.ltdd.gugugaga.admin.data.PhanAnhRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.model.PhanAnh;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.LocDanhSachViewModel;

public class PhanAnhViewModel extends LocDanhSachViewModel<PhanAnh> {
    private final PhanAnhRepository repo;

    public PhanAnhViewModel(@NonNull Application app) {
        super(app);
        repo = new PhanAnhRepository(app);
    }

    @Override
    protected void goiDanhSach(String loc, KetQuaApi<List<PhanAnh>> kq) {
        repo.danhSach(loc, kq);
    }
}
