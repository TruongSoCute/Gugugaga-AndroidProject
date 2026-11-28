package vn.edu.vhu.ltdd.gugugaga.admin.ui.supplier;

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
import vn.edu.vhu.ltdd.gugugaga.admin.model.Supplier;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.Animations;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.LoadMoreScrollListener;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.StatusBadge;

/** Adapter + ViewHolder cho danh sách hồ sơ nhà cung cấp (C.1 #3). */
public class SupplierAdapter extends RecyclerView.Adapter<SupplierAdapter.ViewHolder> {

    public interface KhiChon {
        void chon(Supplier ncc);
    }

    private final List<Supplier> danhSach = new ArrayList<>();
    private final KhiChon khiChon;

    public SupplierAdapter(KhiChon khiChon) {
        this.khiChon = khiChon;
    }

    /** Trang sau thì chỉ chèn thêm các dòng mới; tải lại thì thay toàn bộ (LoadMoreScrollListener.capNhat). */
    public void capNhat(List<Supplier> moi) {
        LoadMoreScrollListener.capNhat(this, danhSach, moi);
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_supplier, parent, false);
        return new ViewHolder(v);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder h, int position) {
        Supplier n = danhSach.get(position);
        Context ctx = h.itemView.getContext();
        h.tvTen.setText(n.ten);
        StatusBadge.gan(h.tvTrangThai, n.trangThaiDuyet);
        h.tvVung.setText(ctx.getString(R.string.dai_dien_vung, n.nguoiDaiDien, n.tenVung));
        h.tvTuGui.setVisibility(n.tuGui ? View.VISIBLE : View.GONE);
        boolean coLyDo = n.lyDoTuChoi != null && !n.lyDoTuChoi.isEmpty();
        h.tvLyDo.setVisibility(coLyDo ? View.VISIBLE : View.GONE);
        if (coLyDo) h.tvLyDo.setText(ctx.getString(R.string.ly_do_tu_choi, n.lyDoTuChoi));
        h.itemView.setOnClickListener(v -> khiChon.chon(n));
    }

    @Override
    public int getItemCount() {
        return danhSach.size();
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        final TextView tvTen, tvTrangThai, tvVung, tvTuGui, tvLyDo;

        ViewHolder(@NonNull View v) {
            super(v);
            Animations.ganNhanNhe(v);
            tvTen = v.findViewById(R.id.tvTen);
            tvTrangThai = v.findViewById(R.id.tvTrangThai);
            tvVung = v.findViewById(R.id.tvVung);
            tvTuGui = v.findViewById(R.id.tvTuGui);
            tvLyDo = v.findViewById(R.id.tvLyDo);
        }
    }
}
