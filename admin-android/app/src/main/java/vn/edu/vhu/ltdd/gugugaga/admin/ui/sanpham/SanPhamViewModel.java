package vn.edu.vhu.ltdd.gugugaga.admin.ui.sanpham;

import android.app.Application;

import androidx.annotation.NonNull;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.data.KetQuaApi;
import vn.edu.vhu.ltdd.gugugaga.admin.data.SanPhamRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.model.DanhSach;
import vn.edu.vhu.ltdd.gugugaga.admin.model.SanPham;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.LocDanhSachViewModel;

/**
 * Giữ danh sách tải từ API trong ViewModel để xoay màn hình không phải gọi lại API
 * (Lab A2 giới thiệu, docs/development/Architecture.md đề xuất). Bộ lọc trạng thái và phân trang
 * dùng chung LocDanhSachViewModel; lớp này thêm hai thao tác duyệt / từ chối.
 */
public class SanPhamViewModel extends LocDanhSachViewModel<SanPham> {
    private final SanPhamRepository repo;

    public SanPhamViewModel(@NonNull Application app) {
        super(app);
        repo = new SanPhamRepository(app);
    }

    @Override
    protected void goiTrang(String loc, int trang, int kichThuoc, KetQuaApi<DanhSach<SanPham>> kq) {
        repo.danhSach(loc, trang, kichThuoc, kq);
    }

    public void duyet(int id, String ten, int hangSao) {
        repo.duyet(id, hangSao, ketQuaThaoTac(chuoi(R.string.da_duyet, ten, hangSao)));
    }

    public void tuChoi(int id, String ten, String lyDo) {
        repo.tuChoi(id, lyDo, ketQuaThaoTac(chuoi(R.string.da_tu_choi, ten)));
    }

    /**
     * Thao tác xong thì báo kết quả và tải lại danh sách từ trang 1 (sản phẩm có thể đã ra khỏi
     * bộ lọc đang chọn); lỗi (vd 409) hiện thông điệp của backend.
     */
    private KetQuaApi<SanPham> ketQuaThaoTac(String thongDiepThanhCong) {
        return new KetQuaApi<SanPham>() {
            @Override
            public void thanhCong(SanPham duLieu) {
                baoTin(thongDiepThanhCong);
                taiLai();
            }

            @Override
            public void loi(String thongDiep) {
                baoTin(thongDiep);
            }

            @Override
            public void hetPhien() {
                daHetPhien();
            }
        };
    }
}
