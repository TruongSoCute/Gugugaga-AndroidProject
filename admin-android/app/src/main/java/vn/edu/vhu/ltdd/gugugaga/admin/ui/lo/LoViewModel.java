package vn.edu.vhu.ltdd.gugugaga.admin.ui.lo;

import android.app.Application;

import androidx.annotation.NonNull;

import vn.edu.vhu.ltdd.gugugaga.admin.data.KetQuaApi;
import vn.edu.vhu.ltdd.gugugaga.admin.data.LoSanXuatRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.model.DanhSach;
import vn.edu.vhu.ltdd.gugugaga.admin.model.LoSanXuat;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.LocDanhSachViewModel;

/** Danh sách lô không có bộ lọc: dùng taiLanDau(); cuộn gần cuối thì tải thêm trang sau. */
public class LoViewModel extends LocDanhSachViewModel<LoSanXuat> {
    private final LoSanXuatRepository repo;

    public LoViewModel(@NonNull Application app) {
        super(app);
        repo = new LoSanXuatRepository(app);
    }

    @Override
    protected void goiTrang(String loc, int trang, int kichThuoc, KetQuaApi<DanhSach<LoSanXuat>> kq) {
        repo.danhSach(trang, kichThuoc, kq);
    }
}
