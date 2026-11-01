package vn.edu.vhu.ltdd.gugugaga.admin.ui.donhang;

import android.app.Application;

import androidx.annotation.NonNull;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.data.DonHangRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.data.KetQuaApi;
import vn.edu.vhu.ltdd.gugugaga.admin.model.DonHang;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.ChiTietViewModel;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.NhanTrangThai;

/** Tải chi tiết một đơn và gửi yêu cầu chuyển trạng thái. */
public class ChiTietDonHangViewModel extends ChiTietViewModel<DonHang> {
    private final DonHangRepository repo;

    public ChiTietDonHangViewModel(@NonNull Application app) {
        super(app);
        repo = new DonHangRepository(app);
    }

    @Override
    protected void goiChiTiet(int id, KetQuaApi<DonHang> kq) {
        repo.chiTiet(id, kq);
    }

    /** Backend trả về đơn sau khi đổi, nên hiện luôn mà không cần tải lại. */
    public void doiTrangThai(String trangThaiMoi, String ghiChu) {
        if (!batDauGui()) return;
        String xong = chuoi(R.string.da_doi_trang_thai_don, id, chuoi(NhanTrangThai.chu(trangThaiMoi)));
        repo.doiTrangThai(id, trangThaiMoi, ghiChu, ketQuaThaoTac(xong));
    }
}
