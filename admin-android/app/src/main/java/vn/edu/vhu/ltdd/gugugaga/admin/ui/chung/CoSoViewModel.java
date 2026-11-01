package vn.edu.vhu.ltdd.gugugaga.admin.ui.chung;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.annotation.StringRes;
import androidx.lifecycle.AndroidViewModel;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;

import vn.edu.vhu.ltdd.gugugaga.admin.data.KetQuaApi;

/**
 * Phần chung của các ViewModel gọi API: thông báo một lần (Snackbar) và cờ hết phiên (401).
 * ViewModel chỉ giữ dữ liệu, không giữ View/Activity/Fragment (ArchUnit kiểm tra).
 */
public abstract class CoSoViewModel extends AndroidViewModel {
    private final MutableLiveData<SuKien<String>> thongBao = new MutableLiveData<>();
    private final MutableLiveData<Boolean> hetPhien = new MutableLiveData<>(false);

    protected CoSoViewModel(@NonNull Application app) {
        super(app);
    }

    public LiveData<SuKien<String>> getThongBao() { return thongBao; }
    public LiveData<Boolean> getHetPhien() { return hetPhien; }

    protected void baoTin(String noiDung) {
        thongBao.setValue(new SuKien<>(noiDung));
    }

    protected String chuoi(@StringRes int id, Object... thamSo) {
        return getApplication().getString(id, thamSo);
    }

    protected void daHetPhien() {
        hetPhien.setValue(true);
    }

    /** Callback đổ kết quả API vào LiveData theo đủ các trạng thái: thành công / lỗi / hết phiên. */
    protected <T> KetQuaApi<T> napVao(MutableLiveData<TrangThai<T>> dich) {
        return new KetQuaApi<T>() {
            @Override
            public void thanhCong(T duLieu) {
                dich.setValue(TrangThai.thanhCong(duLieu));
            }

            @Override
            public void loi(String thongDiep) {
                dich.setValue(TrangThai.loi(thongDiep));
            }

            @Override
            public void hetPhien() {
                daHetPhien();
            }
        };
    }
}
