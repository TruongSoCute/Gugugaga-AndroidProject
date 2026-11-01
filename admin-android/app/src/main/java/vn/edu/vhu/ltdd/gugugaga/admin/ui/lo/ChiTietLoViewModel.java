package vn.edu.vhu.ltdd.gugugaga.admin.ui.lo;

import android.app.Application;

import androidx.annotation.NonNull;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.data.KetQuaApi;
import vn.edu.vhu.ltdd.gugugaga.admin.data.LoSanXuatRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.model.BuocTruyXuat;
import vn.edu.vhu.ltdd.gugugaga.admin.model.LoSanXuat;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauThemBuoc;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.ChiTietViewModel;

public class ChiTietLoViewModel extends ChiTietViewModel<LoSanXuat> {
    private final LoSanXuatRepository repo;

    public ChiTietLoViewModel(@NonNull Application app) {
        super(app);
        repo = new LoSanXuatRepository(app);
    }

    @Override
    protected void goiChiTiet(int id, KetQuaApi<LoSanXuat> kq) {
        repo.chiTiet(id, kq);
    }

    /** Thêm xong thì tải lại chi tiết để thấy bước mới đúng thứ tự. */
    public void themBuoc(YeuCauThemBuoc yeuCau) {
        if (!batDauGui()) return;
        KetQuaApi<BuocTruyXuat> kq = ketQuaThaoTacRoiTaiLai(chuoi(R.string.da_them_buoc, yeuCau.tenBuoc));
        repo.themBuoc(id, yeuCau, kq);
    }
}
