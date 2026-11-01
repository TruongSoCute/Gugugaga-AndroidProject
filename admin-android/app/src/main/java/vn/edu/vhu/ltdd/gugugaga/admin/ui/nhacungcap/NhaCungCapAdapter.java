package vn.edu.vhu.ltdd.gugugaga.admin.ui.nhacungcap;

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
import vn.edu.vhu.ltdd.gugugaga.admin.model.NhaCungCap;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.NhanTrangThai;

/** Adapter + ViewHolder cho danh sách hồ sơ nhà cung cấp (C.1 #3). */
public class NhaCungCapAdapter extends RecyclerView.Adapter<NhaCungCapAdapter.ViewHolder> {

    public interface KhiChon {
        void chon(NhaCungCap ncc);
    }

    private final List<NhaCungCap> danhSach = new ArrayList<>();
    private final KhiChon khiChon;

    public NhaCungCapAdapter(KhiChon khiChon) {
        this.khiChon = khiChon;
    }

    public void capNhat(List<NhaCungCap> moi) {
        danhSach.clear();
        if (moi != null) danhSach.addAll(moi);
        notifyDataSetChanged();
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_nha_cung_cap, parent, false);
        return new ViewHolder(v);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder h, int position) {
        NhaCungCap n = danhSach.get(position);
        Context ctx = h.itemView.getContext();
        h.tvTen.setText(n.ten);
        NhanTrangThai.gan(h.tvTrangThai, n.trangThaiDuyet);
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
            tvTen = v.findViewById(R.id.tvTen);
            tvTrangThai = v.findViewById(R.id.tvTrangThai);
            tvVung = v.findViewById(R.id.tvVung);
            tvTuGui = v.findViewById(R.id.tvTuGui);
            tvLyDo = v.findViewById(R.id.tvLyDo);
        }
    }
}
