package vn.edu.vhu.ltdd.gugugaga.admin.ui.order;

import android.app.Application;

import androidx.annotation.NonNull;

import vn.edu.vhu.ltdd.gugugaga.admin.data.OrderRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.data.ApiResult;
import vn.edu.vhu.ltdd.gugugaga.admin.model.DataList;
import vn.edu.vhu.ltdd.gugugaga.admin.model.Order;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.FilteredListViewModel;

/** Giữ danh sách đơn đã tải qua việc xoay màn hình. */
public class OrderListViewModel extends FilteredListViewModel<Order> {
    private final OrderRepository repo;

    public OrderListViewModel(@NonNull Application app) {
        super(app);
        repo = new OrderRepository(app);
    }

    @Override
    protected void goiTrang(String loc, int trang, int kichThuoc, ApiResult<DataList<Order>> kq) {
        repo.danhSach(loc, trang, kichThuoc, kq);
    }
}
