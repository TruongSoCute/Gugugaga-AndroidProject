package vn.edu.vhu.ltdd.gugugaga.admin.ui.taikhoan;

import android.content.Context;
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
import vn.edu.vhu.ltdd.gugugaga.admin.model.NguoiDung;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.CuonTaiThem;

/** Adapter danh sách tài khoản cho quản trị (Issue #12). */
public class TaiKhoanAdapter extends RecyclerView.Adapter<TaiKhoanAdapter.ViewHolder> {

    public interface KhiKhoaMo {
        void thucHien(NguoiDung u);
    }

    private final List<NguoiDung> danhSach = new ArrayList<>();
    private final String emailHienTai;
    private final KhiKhoaMo khiKhoaMo;

    public TaiKhoanAdapter(String emailHienTai, KhiKhoaMo khiKhoaMo) {
        this.emailHienTai = emailHienTai == null ? "" : emailHienTai;
        this.khiKhoaMo = khiKhoaMo;
    }

    public void capNhat(List<NguoiDung> moi) {
        CuonTaiThem.capNhat(this, danhSach, moi);
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_tai_khoan, parent, false);
        return new ViewHolder(v);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder h, int position) {
        NguoiDung u = danhSach.get(position);
        Context ctx = h.itemView.getContext();
        h.tvHoTen.setText(u.hoTen);
        h.tvEmail.setText(u.email);

        String vaiTroText = tenVaiTro(ctx, u.vaiTro);
        String moTa = (u.soDienThoai != null && !u.soDienThoai.isEmpty())
                ? vaiTroText + " · " + u.soDienThoai
                : vaiTroText;
        h.tvVaiTroSdt.setText(moTa);

        h.tvTrangThai.setText(u.dangHoatDong ? R.string.trang_thai_hoat_dong : R.string.trang_thai_da_khoa);
        h.tvTrangThai.setTextColor(ContextCompat.getColor(ctx,
                u.dangHoatDong ? R.color.xanh_da_duyet : R.color.do_tu_choi));
        h.tvTrangThai.setBackgroundColor(ContextCompat.getColor(ctx,
                u.dangHoatDong ? R.color.nen_da_duyet : R.color.nen_tu_choi));

        boolean laChinhMinh = emailHienTai.equalsIgnoreCase(u.email);
        h.btnKhoaMo.setVisibility(laChinhMinh ? View.GONE : View.VISIBLE);
        h.btnKhoaMo.setText(u.dangHoatDong ? R.string.nut_khoa_tai_khoan : R.string.nut_mo_tai_khoan);
        h.btnKhoaMo.setOnClickListener(v -> khiKhoaMo.thucHien(u));
    }

    private String tenVaiTro(Context ctx, String vaiTro) {
        if (AppConfig.VAI_TRO_QUAN_TRI.equals(vaiTro)) return ctx.getString(R.string.vai_tro_quan_tri);
        if (AppConfig.VAI_TRO_NHAN_VIEN.equals(vaiTro)) return ctx.getString(R.string.vai_tro_nhan_vien);
        if ("NHA_CUNG_CAP".equals(vaiTro)) return ctx.getString(R.string.vai_tro_nha_cung_cap);
        return ctx.getString(R.string.vai_tro_khach);
    }

    @Override
    public int getItemCount() {
        return danhSach.size();
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        final TextView tvHoTen, tvTrangThai, tvEmail, tvVaiTroSdt;
        final Button btnKhoaMo;

        ViewHolder(@NonNull View v) {
            super(v);
            tvHoTen = v.findViewById(R.id.tvHoTen);
            tvTrangThai = v.findViewById(R.id.tvTrangThai);
            tvEmail = v.findViewById(R.id.tvEmail);
            tvVaiTroSdt = v.findViewById(R.id.tvVaiTroSdt);
            btnKhoaMo = v.findViewById(R.id.btnKhoaMo);
        }
    }
}
