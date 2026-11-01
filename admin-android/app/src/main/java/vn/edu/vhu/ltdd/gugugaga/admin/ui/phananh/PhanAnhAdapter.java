package vn.edu.vhu.ltdd.gugugaga.admin.ui.phananh;

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
import vn.edu.vhu.ltdd.gugugaga.admin.model.PhanAnh;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.NhanTrangThai;
import vn.edu.vhu.ltdd.gugugaga.admin.util.DinhDang;

/** Adapter + ViewHolder cho danh sách phản ánh (C.1 #3). */
public class PhanAnhAdapter extends RecyclerView.Adapter<PhanAnhAdapter.ViewHolder> {

    public interface KhiChon {
        void chon(PhanAnh pa);
    }

    private final List<PhanAnh> danhSach = new ArrayList<>();
    private final KhiChon khiChon;

    public PhanAnhAdapter(KhiChon khiChon) {
        this.khiChon = khiChon;
    }

    public void capNhat(List<PhanAnh> moi) {
        danhSach.clear();
        if (moi != null) danhSach.addAll(moi);
        notifyDataSetChanged();
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_phan_anh, parent, false);
        return new ViewHolder(v);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder h, int position) {
        PhanAnh p = danhSach.get(position);
        Context ctx = h.itemView.getContext();
        h.tvLoai.setText(ctx.getString(R.string.loai_va_san_pham,
                ctx.getString(NhanTrangThai.loaiPhanAnh(p.loai)), p.tenSanPham));
        NhanTrangThai.gan(h.tvTrangThai, p.trangThai);
        h.tvNoiDung.setText(p.noiDung);
        h.tvNguoiBao.setText(ctx.getString(R.string.nguoi_bao_luc, p.tenNguoiBao, DinhDang.thoiDiem(p.taoLuc)));
        h.itemView.setOnClickListener(v -> khiChon.chon(p));
    }

    @Override
    public int getItemCount() {
        return danhSach.size();
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        final TextView tvLoai, tvTrangThai, tvNoiDung, tvNguoiBao;

        ViewHolder(@NonNull View v) {
            super(v);
            tvLoai = v.findViewById(R.id.tvLoai);
            tvTrangThai = v.findViewById(R.id.tvTrangThai);
            tvNoiDung = v.findViewById(R.id.tvNoiDung);
            tvNguoiBao = v.findViewById(R.id.tvNguoiBao);
        }
    }
}
