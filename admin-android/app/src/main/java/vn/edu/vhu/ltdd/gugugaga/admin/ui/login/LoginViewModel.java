package vn.edu.vhu.ltdd.gugugaga.admin.ui.login;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.lifecycle.AndroidViewModel;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;

import vn.edu.vhu.ltdd.gugugaga.admin.data.AuthRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.data.ApiResult;
import vn.edu.vhu.ltdd.gugugaga.admin.model.LoginResult;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.UiState;

/**
 * Giữ trạng thái đăng nhập qua việc xoay màn hình (Lab A2): kết quả API trả về sau khi
 * Activity bị tạo lại vẫn tới được Activity mới thay vì Activity cũ đã bị hủy.
 */
public class LoginViewModel extends AndroidViewModel {
    private final AuthRepository repo;
    private final MutableLiveData<UiState<LoginResult>> trangThai = new MutableLiveData<>();

    public LoginViewModel(@NonNull Application app) {
        super(app);
        repo = new AuthRepository(app);
    }

    public LiveData<UiState<LoginResult>> getTrangThai() {
        return trangThai;
    }

    public void dangNhap(String email, String matKhau) {
        UiState<LoginResult> hienTai = trangThai.getValue();
        if (hienTai != null && hienTai.loai == UiState.Loai.DANG_TAI) return; // chống bấm hai lần
        trangThai.setValue(UiState.dangTai());
        repo.dangNhap(email, matKhau, new ApiResult<LoginResult>() {
            @Override
            public void thanhCong(LoginResult duLieu) {
                trangThai.setValue(UiState.thanhCong(duLieu));
            }

            @Override
            public void loi(String thongDiep) {
                trangThai.setValue(UiState.loi(thongDiep));
            }

            @Override
            public void hetPhien() {
                trangThai.setValue(UiState.hetPhien());
            }
        });
    }
}
