package vn.edu.vhu.ltdd.gugugaga.admin.ui.order;

import android.app.Application;

import androidx.annotation.NonNull;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.data.OrderRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.data.ApiResult;
import vn.edu.vhu.ltdd.gugugaga.admin.model.Order;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.DetailsViewModel;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.StatusBadge;

/** Tải chi tiết một đơn và gửi yêu cầu chuyển trạng thái. */
public class OrderDetailsViewModel extends DetailsViewModel<Order> {
    private final OrderRepository repo;

    public OrderDetailsViewModel(@NonNull Application app) {
        super(app);
        repo = new OrderRepository(app);
    }

    @Override
    protected void goiChiTiet(int id, ApiResult<Order> kq) {
        repo.chiTiet(id, kq);
    }

    /** Backend trả về đơn sau khi đổi, nên hiện luôn mà không cần tải lại. */
    public void doiTrangThai(String trangThaiMoi, String ghiChu) {
        if (!batDauGui()) return;
        String xong = chuoi(R.string.da_doi_trang_thai_don, id, chuoi(StatusBadge.chu(trangThaiMoi)));
        repo.doiTrangThai(id, trangThaiMoi, ghiChu, ketQuaThaoTac(xong));
    }
}
