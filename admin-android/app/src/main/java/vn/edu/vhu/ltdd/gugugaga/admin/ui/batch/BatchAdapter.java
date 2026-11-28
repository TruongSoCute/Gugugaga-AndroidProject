package vn.edu.vhu.ltdd.gugugaga.admin.ui.batch;

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
import vn.edu.vhu.ltdd.gugugaga.admin.model.ProductionBatch;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.Animations;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.LoadMoreScrollListener;
import vn.edu.vhu.ltdd.gugugaga.admin.util.Formatting;

/** Adapter + ViewHolder cho danh sách lô tinh gọn: 2 tag mã lô & số bước trên 1 hàng. */
public class BatchAdapter extends RecyclerView.Adapter<BatchAdapter.ViewHolder> {

    public interface KhiChon {
        void chon(ProductionBatch lo);
    }

    private final List<ProductionBatch> danhSach = new ArrayList<>();
    private final KhiChon khiChon;

    public BatchAdapter(KhiChon khiChon) {
        this.khiChon = khiChon;
    }

    /** Trang sau thì chỉ chèn thêm các dòng mới; tải lại thì thay toàn bộ (LoadMoreScrollListener.capNhat). */
    public void capNhat(List<ProductionBatch> moi) {
        LoadMoreScrollListener.capNhat(this, danhSach, moi);
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_batch, parent, false);
        return new ViewHolder(v);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder h, int position) {
        ProductionBatch lo = danhSach.get(position);
        Context ctx = h.itemView.getContext();
        h.tvTenSanPham.setText(lo.tenSanPham);
        h.tvTon.setText(ctx.getString(R.string.ton_ngan, lo.soLuongCon, lo.soLuong));
        h.tvMaTruyXuat.setText(lo.maTruyXuat);
        h.tvSoBuoc.setText(ctx.getString(R.string.so_buoc_ngan, lo.soBuoc));
        h.tvNgay.setText(ctx.getString(R.string.ngay_vung_lo,
                Formatting.ngay(lo.ngaySanXuat), Formatting.ngay(lo.hanSuDung), lo.tenVung));
        h.itemView.setOnClickListener(v -> khiChon.chon(lo));
    }

    @Override
    public int getItemCount() {
        return danhSach.size();
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        final TextView tvMaTruyXuat, tvTenSanPham, tvNgay, tvTon, tvSoBuoc;

        ViewHolder(@NonNull View v) {
            super(v);
            Animations.ganNhanNhe(v);
            tvMaTruyXuat = v.findViewById(R.id.tvMaTruyXuat);
            tvTenSanPham = v.findViewById(R.id.tvTenSanPham);
            tvNgay = v.findViewById(R.id.tvNgay);
            tvTon = v.findViewById(R.id.tvTon);
            tvSoBuoc = v.findViewById(R.id.tvSoBuoc);
        }
    }
}
