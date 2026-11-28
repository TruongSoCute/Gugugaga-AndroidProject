package vn.edu.vhu.ltdd.gugugaga.admin.data;

import android.content.Context;

import java.util.List;

import vn.edu.vhu.ltdd.gugugaga.admin.model.DataList;
import vn.edu.vhu.ltdd.gugugaga.admin.model.Product;
import vn.edu.vhu.ltdd.gugugaga.admin.model.ReviewRequest;
import vn.edu.vhu.ltdd.gugugaga.admin.model.CreateProductRequest;

/** Truy cập API sản phẩm cho màn hình quản trị. Màn hình không gọi Retrofit trực tiếp. */
public class ProductRepository {
    /** Form tạo lô cần đủ sản phẩm trong một lần gọi: lấy trang lớn nhất backend cho (100 dòng). */
    private static final int KICH_THUOC_TRANG_CHON = 100;

    private final Context app;

    public ProductRepository(Context ctx) {
        this.app = ctx.getApplicationContext();
    }

    /**
     * Một trang sản phẩm cho danh sách quản trị, kèm phanTrang.
     *
     * @param trangThai CHO_DUYET / DA_DUYET / TU_CHOI, hoặc null để lấy tất cả.
     */
    public void danhSach(String trangThai, int trang, int kichThuoc, ApiResult<DataList<Product>> kq) {
        ApiCall.goi(app, ApiClient.get(app).dsSanPhamQuanTri(trangThai, trang, kichThuoc), true, kq);
    }

    /** Tối đa 100 sản phẩm trong một lần, chỉ phần duLieu (Spinner chọn sản phẩm khi tạo lô). */
    public void danhSach(String trangThai, ApiResult<List<Product>> kq) {
        ApiCall.goi(app, ApiClient.get(app).dsSanPhamQuanTri(trangThai, 1, KICH_THUOC_TRANG_CHON), true,
                ApiCall.chiLayDuLieu(kq));
    }

    public void duyet(int id, int hangSao, ApiResult<Product> kq) {
        ApiCall.goi(app, ApiClient.get(app).duyetSanPham(id, ReviewRequest.duyet(hangSao)), true, kq);
    }

    public void tao(CreateProductRequest body, ApiResult<Product> kq) {
        ApiCall.goi(app, ApiClient.get(app).taoSanPham(body), true, kq);
    }

    public void tuChoi(int id, String lyDo, ApiResult<Product> kq) {
        ApiCall.goi(app, ApiClient.get(app).duyetSanPham(id, ReviewRequest.tuChoi(lyDo)), true, kq);
    }
}
