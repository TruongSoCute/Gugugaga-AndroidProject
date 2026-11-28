package vn.edu.vhu.ltdd.gugugaga.admin.ui.product;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;

import java.util.Collections;
import java.util.List;
import java.util.Map;

import vn.edu.vhu.ltdd.gugugaga.admin.data.ApiResult;
import vn.edu.vhu.ltdd.gugugaga.admin.data.SupplierRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.data.ProductRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.model.Supplier;
import vn.edu.vhu.ltdd.gugugaga.admin.model.Product;
import vn.edu.vhu.ltdd.gugugaga.admin.model.CreateProductRequest;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.BaseViewModel;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.Event;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.UiState;

/** ViewModel cho form tạo sản phẩm mới cho một nhà cung cấp đã chọn (Issue #13). */
public class CreateProductViewModel extends BaseViewModel {
    public static final class LoiGui {
        public final String thongDiep;
        public final Map<String, String> loiTheoTruong;

        LoiGui(String thongDiep, Map<String, String> loiTheoTruong) {
            this.thongDiep = thongDiep;
            this.loiTheoTruong = loiTheoTruong == null ? Collections.emptyMap() : loiTheoTruong;
        }
    }

    private final SupplierRepository nccRepo;
    private final ProductRepository spRepo;
    private final MutableLiveData<UiState<List<Supplier>>> dsNcc = new MutableLiveData<>();
    private final MutableLiveData<Event<Product>> daTao = new MutableLiveData<>();
    private final MutableLiveData<Event<LoiGui>> loiGui = new MutableLiveData<>();

    public CreateProductViewModel(@NonNull Application app) {
        super(app);
        nccRepo = new SupplierRepository(app);
        spRepo = new ProductRepository(app);
    }

    public LiveData<UiState<List<Supplier>>> getDsNcc() { return dsNcc; }
    public LiveData<Event<Product>> getDaTao() { return daTao; }
    public LiveData<Event<LoiGui>> getLoiGui() { return loiGui; }

    public void taiNccLanDau() {
        if (dsNcc.getValue() == null) taiNcc();
    }

    public void taiNcc() {
        dsNcc.setValue(UiState.dangTai());
        nccRepo.danhSach(napVao(dsNcc));
    }

    public void tao(CreateProductRequest body) {
        spRepo.tao(body, new ApiResult<Product>() {
            @Override
            public void thanhCong(Product dl) {
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
