package vn.edu.vhu.ltdd.gugugaga.admin.ui.sanpham;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;

import java.util.Collections;
import java.util.List;
import java.util.Map;

import vn.edu.vhu.ltdd.gugugaga.admin.data.KetQuaApi;
import vn.edu.vhu.ltdd.gugugaga.admin.data.NhaCungCapRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.data.SanPhamRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.model.NhaCungCap;
import vn.edu.vhu.ltdd.gugugaga.admin.model.SanPham;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauTaoSanPham;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.CoSoViewModel;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.SuKien;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.TrangThai;

/** ViewModel cho form tạo sản phẩm mới cho một nhà cung cấp đã chọn (Issue #13). */
public class TaoSanPhamViewModel extends CoSoViewModel {
    public static final class LoiGui {
        public final String thongDiep;
        public final Map<String, String> loiTheoTruong;

        LoiGui(String thongDiep, Map<String, String> loiTheoTruong) {
            this.thongDiep = thongDiep;
            this.loiTheoTruong = loiTheoTruong == null ? Collections.emptyMap() : loiTheoTruong;
        }
    }

    private final NhaCungCapRepository nccRepo;
    private final SanPhamRepository spRepo;
    private final MutableLiveData<TrangThai<List<NhaCungCap>>> dsNcc = new MutableLiveData<>();
    private final MutableLiveData<SuKien<SanPham>> daTao = new MutableLiveData<>();
    private final MutableLiveData<SuKien<LoiGui>> loiGui = new MutableLiveData<>();

    public TaoSanPhamViewModel(@NonNull Application app) {
        super(app);
        nccRepo = new NhaCungCapRepository(app);
        spRepo = new SanPhamRepository(app);
    }

    public LiveData<TrangThai<List<NhaCungCap>>> getDsNcc() { return dsNcc; }
    public LiveData<SuKien<SanPham>> getDaTao() { return daTao; }
    public LiveData<SuKien<LoiGui>> getLoiGui() { return loiGui; }

    public void taiNccLanDau() {
        if (dsNcc.getValue() == null) taiNcc();
    }

    public void taiNcc() {
        dsNcc.setValue(TrangThai.dangTai());
        nccRepo.danhSach(napVao(dsNcc));
    }

    public void tao(YeuCauTaoSanPham body) {
        spRepo.tao(body, new KetQuaApi<SanPham>() {
            @Override
            public void thanhCong(SanPham dl) {
                daTao.setValue(new SuKien<>(dl));
            }

            @Override
            public void hetPhien() {
                daHetPhien();
            }

            @Override
            public void loi(String thongDiep) {
                loiGui.setValue(new SuKien<>(new LoiGui(thongDiep, Collections.emptyMap())));
            }

            @Override
            public void loiDuLieu(String thongDiep, Map<String, String> loiTheoTruong) {
                loiGui.setValue(new SuKien<>(new LoiGui(thongDiep, loiTheoTruong)));
            }
        });
    }
}
