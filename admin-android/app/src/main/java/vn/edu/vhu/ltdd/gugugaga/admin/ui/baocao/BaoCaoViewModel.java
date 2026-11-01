package vn.edu.vhu.ltdd.gugugaga.admin.ui.baocao;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;

import java.util.Objects;

import vn.edu.vhu.ltdd.gugugaga.admin.data.BaoCaoRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.model.BaoCaoDoanhSo;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.CoSoViewModel;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.TrangThai;

/** Giữ báo cáo đã tải qua việc xoay màn hình; chỉ gọi lại API khi khoảng ngày đổi. */
public class BaoCaoViewModel extends CoSoViewModel {
    private final BaoCaoRepository repo;
    private final MutableLiveData<TrangThai<BaoCaoDoanhSo>> baoCao = new MutableLiveData<>();
    private boolean daTai = false;
    private String tu;
    private String den;

    public BaoCaoViewModel(@NonNull Application app) {
        super(app);
        repo = new BaoCaoRepository(app);
    }

    public LiveData<TrangThai<BaoCaoDoanhSo>> getBaoCao() { return baoCao; }

    /** @param tu, den yyyy-MM-dd hoặc null (không giới hạn). */
    public void tai(String tu, String den) {
        if (daTai && Objects.equals(this.tu, tu) && Objects.equals(this.den, den)) return;
        daTai = true;
        this.tu = tu;
        this.den = den;
        taiLai();
    }

    public void taiLai() {
        baoCao.setValue(TrangThai.dangTai());
        repo.doanhSo(tu, den, napVao(baoCao));
    }
}
