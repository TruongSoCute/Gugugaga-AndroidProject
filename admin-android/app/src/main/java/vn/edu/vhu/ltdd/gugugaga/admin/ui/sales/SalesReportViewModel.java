package vn.edu.vhu.ltdd.gugugaga.admin.ui.sales;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;

import java.util.Objects;

import vn.edu.vhu.ltdd.gugugaga.admin.data.SalesReportRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.model.SalesReport;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.BaseViewModel;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.UiState;

/** Giữ báo cáo đã tải qua việc xoay màn hình; chỉ gọi lại API khi khoảng ngày đổi. */
public class SalesReportViewModel extends BaseViewModel {
    private final SalesReportRepository repo;
    private final MutableLiveData<UiState<SalesReport>> baoCao = new MutableLiveData<>();
    private boolean daTai = false;
    private String tu;
    private String den;

    public SalesReportViewModel(@NonNull Application app) {
        super(app);
        repo = new SalesReportRepository(app);
    }

    public LiveData<UiState<SalesReport>> getBaoCao() { return baoCao; }

    /** @param tu, den yyyy-MM-dd hoặc null (không giới hạn). */
    public void tai(String tu, String den) {
        if (daTai && Objects.equals(this.tu, tu) && Objects.equals(this.den, den)) return;
        daTai = true;
        this.tu = tu;
        this.den = den;
        taiLai();
    }

    public void taiLai() {
        baoCao.setValue(UiState.dangTai());
        repo.doanhSo(tu, den, napVao(baoCao));
    }
}
