package vn.edu.vhu.ltdd.gugugaga.admin.ui.sanpham;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.lifecycle.AndroidViewModel;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;

import java.util.List;
import java.util.Objects;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.data.KetQuaApi;
import vn.edu.vhu.ltdd.gugugaga.admin.data.SanPhamRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.model.SanPham;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.SuKien;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.TrangThai;

/**
 * Giữ danh sách tải từ API trong ViewModel để xoay màn hình không phải gọi lại API
 * (Lab A2 giới thiệu, docs/development/Architecture.md đề xuất).
 */
public class SanPhamViewModel extends AndroidViewModel {
    private final SanPhamRepository repo;
    private final MutableLiveData<TrangThai<List<SanPham>>> danhSach = new MutableLiveData<>();
    private final MutableLiveData<SuKien<String>> thongBao = new MutableLiveData<>();
    private final MutableLiveData<Boolean> hetPhien = new MutableLiveData<>(false);

    private boolean daChonLoc = false;
    private String locHienTai;

    public SanPhamViewModel(@NonNull Application app) {
        super(app);
        repo = new SanPhamRepository(app);
    }

    public LiveData<TrangThai<List<SanPham>>> getDanhSach() { return danhSach; }
    public LiveData<SuKien<String>> getThongBao() { return thongBao; }
    public LiveData<Boolean> getHetPhien() { return hetPhien; }

    /**
     * Gọi khi Spinner chọn trạng thái. Spinner gọi lại listener khi mới gắn adapter và sau khi
     * xoay màn hình (Lab A6) nên chỉ tải khi bộ lọc thật sự đổi.
     */
    public void chonLoc(String trangThai) {
        if (daChonLoc && Objects.equals(locHienTai, trangThai)) return;
        daChonLoc = true;
        locHienTai = trangThai;
        taiLai();
    }

    public void taiLai() {
        danhSach.setValue(TrangThai.dangTai());
        String loc = locHienTai;
        repo.danhSach(loc, new KetQuaApi<List<SanPham>>() {
            @Override
            public void thanhCong(List<SanPham> duLieu) {
                if (Objects.equals(loc, locHienTai)) danhSach.setValue(TrangThai.thanhCong(duLieu));
            }

            @Override
            public void loi(String thongDiep) {
                if (Objects.equals(loc, locHienTai)) danhSach.setValue(TrangThai.loi(thongDiep));
            }

            @Override
            public void hetPhien() {
                hetPhien.setValue(true);
            }
        });
    }

    public void duyet(int id, String ten, int hangSao) {
        repo.duyet(id, hangSao, ketQuaThaoTac(getApplication().getString(R.string.da_duyet, ten, hangSao)));
    }

    public void tuChoi(int id, String ten, String lyDo) {
        repo.tuChoi(id, lyDo, ketQuaThaoTac(getApplication().getString(R.string.da_tu_choi, ten)));
    }

    /** Thao tác xong thì báo kết quả và tải lại danh sách; lỗi (vd 409) hiện thông điệp của backend. */
    private KetQuaApi<SanPham> ketQuaThaoTac(String thongDiepThanhCong) {
        return new KetQuaApi<SanPham>() {
            @Override
            public void thanhCong(SanPham duLieu) {
                thongBao.setValue(new SuKien<>(thongDiepThanhCong));
                taiLai();
            }

            @Override
            public void loi(String thongDiep) {
                thongBao.setValue(new SuKien<>(thongDiep));
            }

            @Override
            public void hetPhien() {
                hetPhien.setValue(true);
            }
        };
    }
}
