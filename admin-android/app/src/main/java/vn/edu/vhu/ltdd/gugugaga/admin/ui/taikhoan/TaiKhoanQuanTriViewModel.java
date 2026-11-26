package vn.edu.vhu.ltdd.gugugaga.admin.ui.taikhoan;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;

import java.util.Collections;
import java.util.Map;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.data.KetQuaApi;
import vn.edu.vhu.ltdd.gugugaga.admin.data.TaiKhoanRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.model.DanhSach;
import vn.edu.vhu.ltdd.gugugaga.admin.model.NguoiDung;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauTaoNhanVien;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.LocDanhSachViewModel;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.SuKien;

/** ViewModel quản lý danh sách tài khoản nhân sự, tạo NHAN_VIEN và khóa/mở tài khoản. */
public class TaiKhoanQuanTriViewModel extends LocDanhSachViewModel<NguoiDung> {
    public static final class LoiTao {
        public final String thongDiep;
        public final Map<String, String> loiTheoTruong;

        LoiTao(String thongDiep, Map<String, String> loiTheoTruong) {
            this.thongDiep = thongDiep;
            this.loiTheoTruong = loiTheoTruong == null ? Collections.emptyMap() : loiTheoTruong;
        }
    }

    private final TaiKhoanRepository repo;
    private final MutableLiveData<SuKien<NguoiDung>> taoThanhCong = new MutableLiveData<>();
    private final MutableLiveData<SuKien<LoiTao>> loiTao = new MutableLiveData<>();

    public TaiKhoanQuanTriViewModel(@NonNull Application app) {
        super(app);
        repo = new TaiKhoanRepository(app);
    }

    public LiveData<SuKien<NguoiDung>> getTaoThanhCong() {
        return taoThanhCong;
    }

    public LiveData<SuKien<LoiTao>> getLoiTao() {
        return loiTao;
    }

    @Override
    protected void goiTrang(String loc, int trang, int kichThuoc, KetQuaApi<DanhSach<NguoiDung>> kq) {
        repo.danhSach(trang, kichThuoc, kq);
    }

    public void taoNhanVien(YeuCauTaoNhanVien body) {
        repo.taoNhanVien(body, new KetQuaApi<NguoiDung>() {
            @Override
            public void thanhCong(NguoiDung dl) {
                taoThanhCong.setValue(new SuKien<>(dl));
                baoTin(chuoi(R.string.da_tao_nhan_vien, dl.email));
                taiLai();
            }

            @Override
            public void hetPhien() {
                daHetPhien();
            }

            @Override
            public void loi(String thongDiep) {
                loiTao.setValue(new SuKien<>(new LoiTao(thongDiep, Collections.emptyMap())));
            }

            @Override
            public void loiDuLieu(String thongDiep, Map<String, String> loiTheoTruong) {
                loiTao.setValue(new SuKien<>(new LoiTao(thongDiep, loiTheoTruong)));
            }
        });
    }

    public void capNhatTrangThai(NguoiDung u, boolean dangHoatDong) {
        repo.capNhatTrangThai(u.id, dangHoatDong, new KetQuaApi<NguoiDung>() {
            @Override
            public void thanhCong(NguoiDung dl) {
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
