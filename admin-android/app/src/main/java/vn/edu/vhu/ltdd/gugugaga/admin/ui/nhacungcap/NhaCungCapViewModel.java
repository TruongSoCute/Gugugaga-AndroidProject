package vn.edu.vhu.ltdd.gugugaga.admin.ui.nhacungcap;

import android.app.Application;

import androidx.annotation.NonNull;

import vn.edu.vhu.ltdd.gugugaga.admin.data.KetQuaApi;
import vn.edu.vhu.ltdd.gugugaga.admin.data.NhaCungCapRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.model.DanhSach;
import vn.edu.vhu.ltdd.gugugaga.admin.model.NhaCungCap;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.LocDanhSachViewModel;

public class NhaCungCapViewModel extends LocDanhSachViewModel<NhaCungCap> {
    private final NhaCungCapRepository repo;

    public NhaCungCapViewModel(@NonNull Application app) {
        super(app);
        repo = new NhaCungCapRepository(app);
    }

    @Override
    protected void goiTrang(String loc, int trang, int kichThuoc, KetQuaApi<DanhSach<NhaCungCap>> kq) {
        repo.danhSach(loc, trang, kichThuoc, kq);
    }
}
