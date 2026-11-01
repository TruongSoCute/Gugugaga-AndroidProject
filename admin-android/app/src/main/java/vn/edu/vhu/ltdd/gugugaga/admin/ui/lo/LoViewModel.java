package vn.edu.vhu.ltdd.gugugaga.admin.ui.lo;

import android.app.Application;

import androidx.annotation.NonNull;

import java.util.List;

import vn.edu.vhu.ltdd.gugugaga.admin.data.KetQuaApi;
import vn.edu.vhu.ltdd.gugugaga.admin.data.LoSanXuatRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.model.LoSanXuat;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.LocDanhSachViewModel;

/** Danh sách lô không có bộ lọc: dùng taiLanDau(). */
public class LoViewModel extends LocDanhSachViewModel<LoSanXuat> {
    private final LoSanXuatRepository repo;

    public LoViewModel(@NonNull Application app) {
        super(app);
        repo = new LoSanXuatRepository(app);
    }

    @Override
    protected void goiDanhSach(String loc, KetQuaApi<List<LoSanXuat>> kq) {
        repo.danhSach(kq);
    }
}
