package vn.edu.vhu.ltdd.gugugaga.admin.ui.account;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;

import java.util.Collections;
import java.util.Map;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.data.ApiResult;
import vn.edu.vhu.ltdd.gugugaga.admin.data.AccountRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.model.DataList;
import vn.edu.vhu.ltdd.gugugaga.admin.model.User;
import vn.edu.vhu.ltdd.gugugaga.admin.model.CreateStaffRequest;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.FilteredListViewModel;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.Event;

/** ViewModel quản lý danh sách tài khoản nhân sự, tạo NHAN_VIEN và khóa/mở tài khoản. */
public class AccountManagementViewModel extends FilteredListViewModel<User> {
    public static final class LoiTao {
        public final String thongDiep;
        public final Map<String, String> loiTheoTruong;

        LoiTao(String thongDiep, Map<String, String> loiTheoTruong) {
            this.thongDiep = thongDiep;
            this.loiTheoTruong = loiTheoTruong == null ? Collections.emptyMap() : loiTheoTruong;
        }
    }

    private final AccountRepository repo;
    private final MutableLiveData<Event<User>> taoThanhCong = new MutableLiveData<>();
    private final MutableLiveData<Event<LoiTao>> loiTao = new MutableLiveData<>();

    public AccountManagementViewModel(@NonNull Application app) {
        super(app);
        repo = new AccountRepository(app);
    }

    public LiveData<Event<User>> getTaoThanhCong() {
        return taoThanhCong;
    }

    public LiveData<Event<LoiTao>> getLoiTao() {
        return loiTao;
    }

    @Override
    protected void goiTrang(String loc, int trang, int kichThuoc, ApiResult<DataList<User>> kq) {
        repo.danhSach(trang, kichThuoc, kq);
    }

    public void taoNhanVien(CreateStaffRequest body) {
        repo.taoNhanVien(body, new ApiResult<User>() {
            @Override
            public void thanhCong(User dl) {
                taoThanhCong.setValue(new Event<>(dl));
                baoTin(chuoi(R.string.da_tao_nhan_vien, dl.email));
                taiLai();
            }

            @Override
            public void hetPhien() {
                daHetPhien();
            }

            @Override
            public void loi(String thongDiep) {
                loiTao.setValue(new Event<>(new LoiTao(thongDiep, Collections.emptyMap())));
            }

            @Override
            public void loiDuLieu(String thongDiep, Map<String, String> loiTheoTruong) {
                loiTao.setValue(new Event<>(new LoiTao(thongDiep, loiTheoTruong)));
            }
        });
    }

    public void capNhatTrangThai(User u, boolean dangHoatDong) {
        repo.capNhatTrangThai(u.id, dangHoatDong, new ApiResult<User>() {
            @Override
            public void thanhCong(User dl) {
                baoTin(chuoi(dl.dangHoatDong ? R.string.da_mo_tai_khoan : R.string.da_khoa_tai_khoan, dl.email));
                taiLai();
            }

            @Override
            public void hetPhien() {
                daHetPhien();
            }

            @Override
            public void loi(String thongDiep) {
                baoTin(thongDiep);
            }
        });
    }
}
