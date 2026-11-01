package vn.edu.vhu.ltdd.gugugaga.admin.ui.nhacungcap;

import android.app.Application;

import androidx.annotation.NonNull;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.data.KetQuaApi;
import vn.edu.vhu.ltdd.gugugaga.admin.data.NhaCungCapRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.model.NhaCungCap;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.ChiTietViewModel;

public class ChiTietNhaCungCapViewModel extends ChiTietViewModel<NhaCungCap> {
    private final NhaCungCapRepository repo;

    public ChiTietNhaCungCapViewModel(@NonNull Application app) {
        super(app);
        repo = new NhaCungCapRepository(app);
    }

    @Override
    protected void goiChiTiet(int id, KetQuaApi<NhaCungCap> kq) {
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
