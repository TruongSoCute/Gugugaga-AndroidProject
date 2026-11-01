package vn.edu.vhu.ltdd.gugugaga.admin.ui.phananh;

import android.app.Application;

import androidx.annotation.NonNull;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.data.KetQuaApi;
import vn.edu.vhu.ltdd.gugugaga.admin.data.PhanAnhRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.model.PhanAnh;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.ChiTietViewModel;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.NhanTrangThai;

public class ChiTietPhanAnhViewModel extends ChiTietViewModel<PhanAnh> {
    private final PhanAnhRepository repo;

    public ChiTietPhanAnhViewModel(@NonNull Application app) {
        super(app);
        repo = new PhanAnhRepository(app);
    }

    @Override
    protected void goiChiTiet(int id, KetQuaApi<PhanAnh> kq) {
        repo.chiTiet(id, kq);
    }

    public void xuLy(String trangThaiMoi, String ketQua) {
        if (!batDauGui()) return;
        repo.xuLy(id, trangThaiMoi, ketQua,
                ketQuaThaoTac(chuoi(R.string.da_cap_nhat_phan_anh, chuoi(NhanTrangThai.chu(trangThaiMoi)))));
    }
}
