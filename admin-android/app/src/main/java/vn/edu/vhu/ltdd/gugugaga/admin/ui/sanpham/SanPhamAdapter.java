package vn.edu.vhu.ltdd.gugugaga.admin.ui.sanpham;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.RecyclerView;

import java.util.ArrayList;
import java.util.List;

import vn.edu.vhu.ltdd.gugugaga.admin.AppConfig;
import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.model.SanPham;
import vn.edu.vhu.ltdd.gugugaga.admin.util.DinhDang;

/**
 * Adapter + ViewHolder cho RecyclerView (C.1 #3, Lab A9/A10): đổ dữ liệu SanPham vào
 * layout một dòng item_san_pham.xml.
 */
public class SanPhamAdapter extends RecyclerView.Adapter<SanPhamAdapter.ViewHolder> {

    /** Hành động trên một dòng; Fragment xử lý (mở hộp thoại). */
    public interface HanhDong {
        void onDuyet(SanPham sp);
        void onTuChoi(SanPham sp);
    }

    private final List<SanPham> danhSach = new ArrayList<>();
    private final boolean coQuyenDuyet;
    private final HanhDong hanhDong;

    public SanPhamAdapter(boolean coQuyenDuyet, HanhDong hanhDong) {
        this.coQuyenDuyet = coQuyenDuyet;
        this.hanhDong = hanhDong;
    }

    public void capNhat(List<SanPham> moi) {
        danhSach.clear();
        if (moi != null) danhSach.addAll(moi);
        notifyDataSetChanged(); // sửa dữ liệu xong phải báo cho danh sách vẽ lại (Lab A9)
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        // Tham số thứ ba phải là false: RecyclerView tự gắn dòng vào (Lab A9).
        View v = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_san_pham, parent, false);
        return new ViewHolder(v);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder h, int position) {
        // Gán dữ liệu ở MỌI lần bind, vì ViewHolder được tái sử dụng khi cuộn.
        SanPham sp = danhSach.get(position);
        android.content.Context ctx = h.itemView.getContext();

        h.tvTen.setText(sp.ten);
        h.tvNhaCungCap.setText(ctx.getString(R.string.ncc_vung, sp.tenNhaCungCap, sp.tenVung));
        h.tvGia.setText(DinhDang.tien(sp.gia));
        h.tvHangSao.setText(sp.hangSao != null
                ? ctx.getString(R.string.hang_sao, sp.hangSao)
                : ctx.getString(R.string.chua_xep_hang));

        int nhan, mauChu, mauNen;
        if (AppConfig.TRANG_THAI_DA_DUYET.equals(sp.trangThaiDuyet)) {
            nhan = R.string.trang_thai_da_duyet; mauChu = R.color.xanh_da_duyet; mauNen = R.color.nen_da_duyet;
        } else if (AppConfig.TRANG_THAI_TU_CHOI.equals(sp.trangThaiDuyet)) {
            nhan = R.string.trang_thai_tu_choi; mauChu = R.color.do_tu_choi; mauNen = R.color.nen_tu_choi;
        } else {
            nhan = R.string.trang_thai_cho_duyet; mauChu = R.color.vang_cho_duyet; mauNen = R.color.nen_cho_duyet;
        }
        h.tvTrangThai.setText(nhan);
        h.tvTrangThai.setTextColor(ContextCompat.getColor(ctx, mauChu));
        h.tvTrangThai.setBackgroundColor(ContextCompat.getColor(ctx, mauNen));

        boolean coLyDo = sp.lyDoTuChoi != null && !sp.lyDoTuChoi.isEmpty();
        h.tvLyDo.setVisibility(coLyDo ? View.VISIBLE : View.GONE);
        if (coLyDo) h.tvLyDo.setText(ctx.getString(R.string.ly_do_tu_choi, sp.lyDoTuChoi));

        boolean nccChuaDuyet = !AppConfig.TRANG_THAI_DA_DUYET.equals(sp.trangThaiNhaCungCap);
        h.tvNccChuaDuyet.setVisibility(nccChuaDuyet ? View.VISIBLE : View.GONE);

        // Chỉ QUAN_TRI thấy nút; backend vẫn chặn NHAN_VIEN bằng 403 nếu gọi thẳng API.
        boolean hienNut = coQuyenDuyet && AppConfig.TRANG_THAI_CHO_DUYET.equals(sp.trangThaiDuyet);
        h.hangNut.setVisibility(hienNut ? View.VISIBLE : View.GONE);
        h.btnDuyet.setOnClickListener(v -> hanhDong.onDuyet(sp));
        h.btnTuChoi.setOnClickListener(v -> hanhDong.onTuChoi(sp));
    }

    @Override
    public int getItemCount() {
        return danhSach.size();
    }

    /** Giữ sẵn tham chiếu View để không phải findViewById mỗi lần cuộn (Lab A9). */
    static class ViewHolder extends RecyclerView.ViewHolder {
        final TextView tvTen, tvNhaCungCap, tvGia, tvHangSao, tvTrangThai, tvLyDo, tvNccChuaDuyet;
        final View hangNut;
        final Button btnDuyet, btnTuChoi;

        ViewHolder(@NonNull View v) {
            super(v);
            tvTen = v.findViewById(R.id.tvTen);
            tvNhaCungCap = v.findViewById(R.id.tvNhaCungCap);
            tvGia = v.findViewById(R.id.tvGia);
            tvHangSao = v.findViewById(R.id.tvHangSao);
            tvTrangThai = v.findViewById(R.id.tvTrangThai);
            tvLyDo = v.findViewById(R.id.tvLyDo);
            tvNccChuaDuyet = v.findViewById(R.id.tvNccChuaDuyet);
            hangNut = v.findViewById(R.id.hangNut);
            btnDuyet = v.findViewById(R.id.btnDuyet);
            btnTuChoi = v.findViewById(R.id.btnTuChoi);
        }
    }
}
