package vn.edu.vhu.ltdd.gugugaga.admin.ui.chung;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;

import java.util.List;
import java.util.Objects;

import vn.edu.vhu.ltdd.gugugaga.admin.data.KetQuaApi;

/**
 * ViewModel của một danh sách có bộ lọc (Spinner). Giữ dữ liệu đã tải để xoay màn hình không
 * gọi lại API (Lab A2); lớp con chỉ cần nói gọi repository nào.
 */
public abstract class LocDanhSachViewModel<T> extends CoSoViewModel {
    private final MutableLiveData<TrangThai<List<T>>> danhSach = new MutableLiveData<>();
    private boolean daChonLoc = false;
    private String locHienTai;

    protected LocDanhSachViewModel(@NonNull Application app) {
        super(app);
    }

    public LiveData<TrangThai<List<T>>> getDanhSach() { return danhSach; }

    /** Gọi repository tương ứng; loc = null nghĩa là không lọc. */
    protected abstract void goiDanhSach(String loc, KetQuaApi<List<T>> kq);

    /**
     * Spinner gọi lại listener khi mới gắn adapter và sau khi xoay màn hình (Lab A6), nên chỉ
     * tải khi bộ lọc thật sự đổi.
     */
    public void chonLoc(String loc) {
        if (daChonLoc && Objects.equals(locHienTai, loc)) return;
        daChonLoc = true;
        locHienTai = loc;
        taiLai();
    }

    /** Danh sách không có bộ lọc: chỉ tải lần đầu, các lần tạo lại View dùng dữ liệu đã có. */
    public void taiLanDau() {
        if (!daChonLoc) chonLoc(null);
    }

    public void taiLai() {
        danhSach.setValue(TrangThai.dangTai());
        String loc = locHienTai;
        goiDanhSach(loc, new KetQuaApi<List<T>>() {
            @Override
            public void thanhCong(List<T> duLieu) {
                // Bỏ kết quả cũ nếu người dùng đã đổi bộ lọc trong lúc chờ.
                if (Objects.equals(loc, locHienTai)) danhSach.setValue(TrangThai.thanhCong(duLieu));
            }

            @Override
            public void loi(String thongDiep) {
                if (Objects.equals(loc, locHienTai)) danhSach.setValue(TrangThai.loi(thongDiep));
            }

            @Override
            public void hetPhien() {
                daHetPhien();
            }
        });
    }
}
