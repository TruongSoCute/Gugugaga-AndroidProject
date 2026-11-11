
package vn.edu.vhu.ltdd.gugugaga.admin.ui.lo;

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
import vn.edu.vhu.ltdd.gugugaga.admin.model.LoSanXuat;
import vn.edu.vhu.ltdd.gugugaga.admin.util.DinhDang;

/**
 * Adapter + ViewHolder cho danh sách lô sản xuất.
 */
public class LoAdapter extends RecyclerView.Adapter<LoAdapter.ViewHolder> {

    public interface KhiChon {
        void chon(LoSanXuat lo);
    }

    private final List<LoSanXuat> danhSach = new ArrayList<>();
    private final KhiChon khiChon;

    public LoAdapter(KhiChon khiChon) {
        this.khiChon = khiChon;
    }

    /**
     * Thay thế toàn bộ danh sách khi tải lại trang đầu.
     */
    public void capNhat(List<LoSanXuat> moi) {
        danhSach.clear();

        if (moi != null) {
            danhSach.addAll(moi);
        }

        notifyDataSetChanged();
    }

    /**
     * Nối dữ liệu trang tiếp theo vào cuối danh sách.
     */
    public void themNhieu(List<LoSanXuat> moi) {
        if (moi == null || moi.isEmpty()) return;

        int viTriBatDau = danhSach.size();

        danhSach.addAll(moi);

        notifyItemRangeInserted(viTriBatDau, moi.size());
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(
            @NonNull ViewGroup parent,
            int viewType
    ) {
        View v = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_lo, parent, false);

        return new ViewHolder(v);
    }

    @Override
    public void onBindViewHolder(
            @NonNull ViewHolder h,
            int position
    ) {
        LoSanXuat lo = danhSach.get(position);

        Context ctx = h.itemView.getContext();

        h.tvMa.setText(lo.maTruyXuat);
        h.tvTenSanPham.setText(lo.tenSanPham);

        h.tvNgay.setText(ctx.getString(
                R.string.nsx_hsd,
                DinhDang.ngay(lo.ngaySanXuat),
                DinhDang.ngay(lo.hanSuDung)
        ));

        h.tvTon.setText(ctx.getString(
                R.string.ton_vung_buoc,
                lo.soLuongCon,
                lo.soLuong,
                lo.tenVung,
                lo.soBuoc
        ));

        h.itemView.setOnClickListener(v -> khiChon.chon(lo));
    }

    @Override
    public int getItemCount() {
        return danhSach.size();
    }

    static class ViewHolder extends RecyclerView.ViewHolder {

        final TextView tvMa;
        final TextView tvTenSanPham;
        final TextView tvNgay;
        final TextView tvTon;

        ViewHolder(@NonNull View v) {
            super(v);

            tvMa = v.findViewById(R.id.tvMaTruyXuat);
            tvTenSanPham = v.findViewById(R.id.tvTenSanPham);
            tvNgay = v.findViewById(R.id.tvNgay);
            tvTon = v.findViewById(R.id.tvTon);
        }
    }
}
