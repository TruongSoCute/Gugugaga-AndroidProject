package vn.edu.vhu.ltdd.gugugaga.admin.ui.supplier;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;

import java.util.Collections;
import java.util.List;
import java.util.Map;

import vn.edu.vhu.ltdd.gugugaga.admin.data.ApiResult;
import vn.edu.vhu.ltdd.gugugaga.admin.data.SupplierRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.data.SourcingRegionRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.model.Supplier;
import vn.edu.vhu.ltdd.gugugaga.admin.model.SourcingRegion;
import vn.edu.vhu.ltdd.gugugaga.admin.model.CreateSupplierRequest;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.BaseViewModel;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.Event;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.UiState;

/** ViewModel cho form tạo hồ sơ nhà cung cấp kèm chứng nhận (Issue #13). */
public class CreateSupplierViewModel extends BaseViewModel {
    public static final class LoiGui {
        public final String thongDiep;
        public final Map<String, String> loiTheoTruong;

        LoiGui(String thongDiep, Map<String, String> loiTheoTruong) {
            this.thongDiep = thongDiep;
            this.loiTheoTruong = loiTheoTruong == null ? Collections.emptyMap() : loiTheoTruong;
        }
    }

    private final SourcingRegionRepository vungRepo;
    private final SupplierRepository nccRepo;
    private final MutableLiveData<UiState<List<SourcingRegion>>> dsVung = new MutableLiveData<>();
    private final MutableLiveData<Event<Supplier>> daTao = new MutableLiveData<>();
    private final MutableLiveData<Event<LoiGui>> loiGui = new MutableLiveData<>();

    public CreateSupplierViewModel(@NonNull Application app) {
        super(app);
        vungRepo = new SourcingRegionRepository(app);
        nccRepo = new SupplierRepository(app);
    }

    public LiveData<UiState<List<SourcingRegion>>> getDsVung() { return dsVung; }
    public LiveData<Event<Supplier>> getDaTao() { return daTao; }
    public LiveData<Event<LoiGui>> getLoiGui() { return loiGui; }

    public void taiVungLanDau() {
        if (dsVung.getValue() == null) taiVung();
    }

    public void taiVung() {
        dsVung.setValue(UiState.dangTai());
        vungRepo.danhSach(napVao(dsVung));
    }

    public void tao(CreateSupplierRequest body) {
        nccRepo.tao(body, new ApiResult<Supplier>() {
            @Override
            public void thanhCong(Supplier dl) {
                daTao.setValue(new Event<>(dl));
            }

            @Override
            public void hetPhien() {
                daHetPhien();
            }

            @Override
            public void loi(String thongDiep) {
                loiGui.setValue(new Event<>(new LoiGui(thongDiep, Collections.emptyMap())));
            }

            @Override
            public void loiDuLieu(String thongDiep, Map<String, String> loiTheoTruong) {
                loiGui.setValue(new Event<>(new LoiGui(thongDiep, loiTheoTruong)));
            }
        });
    }
}
