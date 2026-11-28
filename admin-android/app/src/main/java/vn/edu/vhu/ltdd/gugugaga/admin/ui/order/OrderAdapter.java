package vn.edu.vhu.ltdd.gugugaga.admin.ui.order;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import java.util.ArrayList;
import java.util.List;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.model.Order;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.Animations;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.LoadMoreScrollListener;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.StatusBadge;
import vn.edu.vhu.ltdd.gugugaga.admin.util.Formatting;

/** Adapter + ViewHolder cho danh sách đơn hàng tinh gọn (C.1 #3, Lab A9/A10). */
public class OrderAdapter extends RecyclerView.Adapter<OrderAdapter.ViewHolder> {

    public interface KhiChon {
        void chon(Order don);
    }

    private final List<Order> danhSach = new ArrayList<>();
    private final KhiChon khiChon;

    public OrderAdapter(KhiChon khiChon) {
        this.khiChon = khiChon;
    }

    /** Trang sau thì chỉ chèn thêm các dòng mới; tải lại thì thay toàn bộ (LoadMoreScrollListener.capNhat). */
    public void capNhat(List<Order> moi) {
        LoadMoreScrollListener.capNhat(this, danhSach, moi);
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_order, parent, false);
        return new ViewHolder(v);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder h, int position) {
        Order d = danhSach.get(position);
        Context ctx = h.itemView.getContext();
        h.tvMaDon.setText(ctx.getString(R.string.ma_don_ngan, d.id));
        h.tvTaoLuc.setText(Formatting.thoiDiem(d.taoLuc));
        StatusBadge.gan(h.tvTrangThai, d.trangThai);

        h.tvSanPham.setText(d.tenSanPhamDau != null ? d.tenSanPhamDau : "");
        if (d.soSanPham > 1) {
            h.tvThemSanPham.setVisibility(View.VISIBLE);
            h.tvThemSanPham.setText(ctx.getString(R.string.them_san_pham_ngan, d.soSanPham - 1));
        } else {
            h.tvThemSanPham.setVisibility(View.GONE);
        }

        // Gộp gọn tên khách & người nhận khi trùng nhau, tránh lặp chữ dư thừa.
        String nhan = d.tenNguoiNhan == null ? "" : d.tenNguoiNhan.trim();
        String khach = d.tenKhach == null ? "" : d.tenKhach.trim();
        if (nhan.isEmpty()) {
            h.tvNguoiNhan.setText(khach);
        } else if (khach.isEmpty() || nhan.equalsIgnoreCase(khach)) {
            h.tvNguoiNhan.setText(nhan);
        } else {
            h.tvNguoiNhan.setText(ctx.getString(R.string.ncc_vung, nhan, khach));
        }

        h.tvTongTien.setText(Formatting.tien(d.tongTien));
        h.itemView.setOnClickListener(v -> khiChon.chon(d));
    }

    @Override
    public int getItemCount() {
        return danhSach.size();
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        final TextView tvMaDon, tvTrangThai, tvNguoiNhan, tvSanPham, tvThemSanPham, tvTongTien, tvTaoLuc;

        ViewHolder(@NonNull View v) {
            super(v);
            Animations.ganNhanNhe(v);
            tvMaDon = v.findViewById(R.id.tvMaDon);
            tvTrangThai = v.findViewById(R.id.tvTrangThai);
            tvNguoiNhan = v.findViewById(R.id.tvNguoiNhan);
            tvSanPham = v.findViewById(R.id.tvSanPham);
            tvThemSanPham = v.findViewById(R.id.tvThemSanPham);
            tvTongTien = v.findViewById(R.id.tvTongTien);
            tvTaoLuc = v.findViewById(R.id.tvTaoLuc);
        }
    }
}
