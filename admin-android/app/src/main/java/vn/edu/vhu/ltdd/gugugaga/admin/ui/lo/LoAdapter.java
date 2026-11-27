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
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.ChuyenDong;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.CuonTaiThem;
import vn.edu.vhu.ltdd.gugugaga.admin.util.DinhDang;

/** Adapter + ViewHolder cho danh sách lô tinh gọn: 2 tag mã lô & số bước trên 1 hàng. */
public class LoAdapter extends RecyclerView.Adapter<LoAdapter.ViewHolder> {

    public interface KhiChon {
        void chon(LoSanXuat lo);
    }

    private final List<LoSanXuat> danhSach = new ArrayList<>();
    private final KhiChon khiChon;

    public LoAdapter(KhiChon khiChon) {
        this.khiChon = khiChon;
    }

    /** Trang sau thì chỉ chèn thêm các dòng mới; tải lại thì thay toàn bộ (CuonTaiThem.capNhat). */
    public void capNhat(List<LoSanXuat> moi) {
        CuonTaiThem.capNhat(this, danhSach, moi);
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_lo, parent, false);
        return new ViewHolder(v);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder h, int position) {
        LoSanXuat lo = danhSach.get(position);
        Context ctx = h.itemView.getContext();
        h.tvTenSanPham.setText(lo.tenSanPham);
        h.tvTon.setText(ctx.getString(R.string.ton_ngan, lo.soLuongCon, lo.soLuong));
        h.tvMaTruyXuat.setText(lo.maTruyXuat);
        h.tvSoBuoc.setText(ctx.getString(R.string.so_buoc_ngan, lo.soBuoc));
        h.tvNgay.setText(ctx.getString(R.string.ngay_vung_lo,
                DinhDang.ngay(lo.ngaySanXuat), DinhDang.ngay(lo.hanSuDung), lo.tenVung));
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
            ChuyenDong.ganNhanNhe(v);
            tvMaTruyXuat = v.findViewById(R.id.tvMaTruyXuat);
            tvTenSanPham = v.findViewById(R.id.tvTenSanPham);
            tvNgay = v.findViewById(R.id.tvNgay);
            tvTon = v.findViewById(R.id.tvTon);
            tvSoBuoc = v.findViewById(R.id.tvSoBuoc);
        }
    }
}
