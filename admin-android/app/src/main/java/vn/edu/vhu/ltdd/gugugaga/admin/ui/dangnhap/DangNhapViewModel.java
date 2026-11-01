package vn.edu.vhu.ltdd.gugugaga.admin.ui.dangnhap;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.lifecycle.AndroidViewModel;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;

import vn.edu.vhu.ltdd.gugugaga.admin.data.AuthRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.data.KetQuaApi;
import vn.edu.vhu.ltdd.gugugaga.admin.model.KetQuaDangNhap;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.TrangThai;

/**
 * Giữ trạng thái đăng nhập qua việc xoay màn hình (Lab A2): kết quả API trả về sau khi
 * Activity bị tạo lại vẫn tới được Activity mới thay vì Activity cũ đã bị hủy.
 */
public class DangNhapViewModel extends AndroidViewModel {
    private final AuthRepository repo;
    private final MutableLiveData<TrangThai<KetQuaDangNhap>> trangThai = new MutableLiveData<>();

    public DangNhapViewModel(@NonNull Application app) {
        super(app);
        repo = new AuthRepository(app);
    }

    public LiveData<TrangThai<KetQuaDangNhap>> getTrangThai() {
        return trangThai;
    }

    public void dangNhap(String email, String matKhau) {
        TrangThai<KetQuaDangNhap> hienTai = trangThai.getValue();
        if (hienTai != null && hienTai.loai == TrangThai.Loai.DANG_TAI) return; // chống bấm hai lần
        trangThai.setValue(TrangThai.dangTai());
        repo.dangNhap(email, matKhau, new KetQuaApi<KetQuaDangNhap>() {
            @Override
            public void thanhCong(KetQuaDangNhap duLieu) {
                trangThai.setValue(TrangThai.thanhCong(duLieu));
            }

            @Override
            public void loi(String thongDiep) {
                trangThai.setValue(TrangThai.loi(thongDiep));
            }

            @Override
            public void hetPhien() {
                trangThai.setValue(TrangThai.hetPhien());
            }
        });
    }
}
