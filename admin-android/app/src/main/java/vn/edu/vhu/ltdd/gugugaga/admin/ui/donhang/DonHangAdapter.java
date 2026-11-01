package vn.edu.vhu.ltdd.gugugaga.admin.ui.donhang;

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
import vn.edu.vhu.ltdd.gugugaga.admin.model.DonHang;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.NhanTrangThai;
import vn.edu.vhu.ltdd.gugugaga.admin.util.DinhDang;

/** Adapter + ViewHolder cho danh sách đơn hàng (C.1 #3, Lab A9/A10). */
public class DonHangAdapter extends RecyclerView.Adapter<DonHangAdapter.ViewHolder> {

    public interface KhiChon {
        void chon(DonHang don);
    }

    private final List<DonHang> danhSach = new ArrayList<>();
    private final KhiChon khiChon;

    public DonHangAdapter(KhiChon khiChon) {
        this.khiChon = khiChon;
    }

    public void capNhat(List<DonHang> moi) {
        danhSach.clear();
        if (moi != null) danhSach.addAll(moi);
        notifyDataSetChanged(); // sửa dữ liệu xong phải báo cho danh sách vẽ lại (Lab A9)
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_don_hang, parent, false);
        return new ViewHolder(v);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder h, int position) {
        DonHang d = danhSach.get(position);
        Context ctx = h.itemView.getContext();
        h.tvMaDon.setText(ctx.getString(R.string.ma_don, d.id));
        NhanTrangThai.gan(h.tvTrangThai, d.trangThai);
        h.tvNguoiNhan.setText(ctx.getString(R.string.nguoi_nhan_khach, d.tenNguoiNhan, d.tenKhach));
        h.tvSanPham.setText(d.soSanPham > 1
                ? ctx.getString(R.string.san_pham_va_khac, d.tenSanPhamDau, d.soSanPham - 1)
                : d.tenSanPhamDau);
        h.tvTongTien.setText(DinhDang.tien(d.tongTien));
        h.tvTaoLuc.setText(DinhDang.thoiDiem(d.taoLuc));
        h.itemView.setOnClickListener(v -> khiChon.chon(d));
    }

    @Override
    public int getItemCount() {
        return danhSach.size();
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        final TextView tvMaDon, tvTrangThai, tvNguoiNhan, tvSanPham, tvTongTien, tvTaoLuc;

        ViewHolder(@NonNull View v) {
            super(v);
            tvMaDon = v.findViewById(R.id.tvMaDon);
            tvTrangThai = v.findViewById(R.id.tvTrangThai);
            tvNguoiNhan = v.findViewById(R.id.tvNguoiNhan);
            tvSanPham = v.findViewById(R.id.tvSanPham);
            tvTongTien = v.findViewById(R.id.tvTongTien);
            tvTaoLuc = v.findViewById(R.id.tvTaoLuc);
        }
    }
}
