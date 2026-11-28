package vn.edu.vhu.ltdd.gugugaga.admin.ui.product;

import android.app.Application;

import androidx.annotation.NonNull;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.data.ApiResult;
import vn.edu.vhu.ltdd.gugugaga.admin.data.ProductRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.model.DataList;
import vn.edu.vhu.ltdd.gugugaga.admin.model.Product;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.FilteredListViewModel;

/**
 * Giữ danh sách tải từ API trong ViewModel để xoay màn hình không phải gọi lại API
 * (Lab A2 giới thiệu, docs/development/Architecture.md đề xuất). Bộ lọc trạng thái và phân trang
 * dùng chung FilteredListViewModel; lớp này thêm hai thao tác duyệt / từ chối.
 */
public class ProductListViewModel extends FilteredListViewModel<Product> {
    private final ProductRepository repo;

    public ProductListViewModel(@NonNull Application app) {
        super(app);
        repo = new ProductRepository(app);
    }

    @Override
    protected void goiTrang(String loc, int trang, int kichThuoc, ApiResult<DataList<Product>> kq) {
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
    private ApiResult<Product> ketQuaThaoTac(String thongDiepThanhCong) {
        return new ApiResult<Product>() {
            @Override
            public void thanhCong(Product duLieu) {
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
