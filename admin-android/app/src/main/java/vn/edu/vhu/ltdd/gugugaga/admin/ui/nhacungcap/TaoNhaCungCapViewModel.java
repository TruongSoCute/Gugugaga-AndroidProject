package vn.edu.vhu.ltdd.gugugaga.admin.ui.nhacungcap;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;

import java.util.Collections;
import java.util.List;
import java.util.Map;

import vn.edu.vhu.ltdd.gugugaga.admin.data.KetQuaApi;
import vn.edu.vhu.ltdd.gugugaga.admin.data.NhaCungCapRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.data.VungNguyenLieuRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.model.NhaCungCap;
import vn.edu.vhu.ltdd.gugugaga.admin.model.VungNguyenLieu;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauTaoNhaCungCap;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.CoSoViewModel;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.SuKien;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.TrangThai;

/** ViewModel cho form tạo hồ sơ nhà cung cấp kèm chứng nhận (Issue #13). */
public class TaoNhaCungCapViewModel extends CoSoViewModel {
    public static final class LoiGui {
        public final String thongDiep;
        public final Map<String, String> loiTheoTruong;

        LoiGui(String thongDiep, Map<String, String> loiTheoTruong) {
            this.thongDiep = thongDiep;
            this.loiTheoTruong = loiTheoTruong == null ? Collections.emptyMap() : loiTheoTruong;
        }
    }

    private final VungNguyenLieuRepository vungRepo;
    private final NhaCungCapRepository nccRepo;
    private final MutableLiveData<TrangThai<List<VungNguyenLieu>>> dsVung = new MutableLiveData<>();
    private final MutableLiveData<SuKien<NhaCungCap>> daTao = new MutableLiveData<>();
    private final MutableLiveData<SuKien<LoiGui>> loiGui = new MutableLiveData<>();

    public TaoNhaCungCapViewModel(@NonNull Application app) {
        super(app);
        vungRepo = new VungNguyenLieuRepository(app);
        nccRepo = new NhaCungCapRepository(app);
    }

    public LiveData<TrangThai<List<VungNguyenLieu>>> getDsVung() { return dsVung; }
    public LiveData<SuKien<NhaCungCap>> getDaTao() { return daTao; }
    public LiveData<SuKien<LoiGui>> getLoiGui() { return loiGui; }

    public void taiVungLanDau() {
        if (dsVung.getValue() == null) taiVung();
    }

    public void taiVung() {
        dsVung.setValue(TrangThai.dangTai());
        vungRepo.danhSach(napVao(dsVung));
    }

    public void tao(YeuCauTaoNhaCungCap body) {
        nccRepo.tao(body, new KetQuaApi<NhaCungCap>() {
            @Override
            public void thanhCong(NhaCungCap dl) {
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
