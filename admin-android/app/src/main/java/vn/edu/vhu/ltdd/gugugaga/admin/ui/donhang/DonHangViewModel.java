package vn.edu.vhu.ltdd.gugugaga.admin.ui.donhang;

import android.app.Application;

import androidx.annotation.NonNull;

import java.util.List;

import vn.edu.vhu.ltdd.gugugaga.admin.data.DonHangRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.data.KetQuaApi;
import vn.edu.vhu.ltdd.gugugaga.admin.model.DonHang;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.LocDanhSachViewModel;

/** Giữ danh sách đơn đã tải qua việc xoay màn hình. */
public class DonHangViewModel extends LocDanhSachViewModel<DonHang> {
    private final DonHangRepository repo;

    public DonHangViewModel(@NonNull Application app) {
        super(app);
        repo = new DonHangRepository(app);
    }

    @Override
    protected void goiDanhSach(String loc, KetQuaApi<List<DonHang>> kq) {
        repo.danhSach(loc, kq);
    }
}
