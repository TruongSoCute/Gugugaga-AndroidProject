package vn.edu.vhu.ltdd.gugugaga.admin.ui.issuereport;

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
import vn.edu.vhu.ltdd.gugugaga.admin.model.IssueReport;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.LoadMoreScrollListener;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.StatusBadge;
import vn.edu.vhu.ltdd.gugugaga.admin.util.Formatting;

/** Adapter + ViewHolder cho danh sách phản ánh (C.1 #3). */
public class IssueReportAdapter extends RecyclerView.Adapter<IssueReportAdapter.ViewHolder> {

    public interface KhiChon {
        void chon(IssueReport pa);
    }

    private final List<IssueReport> danhSach = new ArrayList<>();
    private final KhiChon khiChon;

    public IssueReportAdapter(KhiChon khiChon) {
        this.khiChon = khiChon;
    }

    /** Trang sau thì chỉ chèn thêm các dòng mới; tải lại thì thay toàn bộ (LoadMoreScrollListener.capNhat). */
    public void capNhat(List<IssueReport> moi) {
        LoadMoreScrollListener.capNhat(this, danhSach, moi);
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_issue_report, parent, false);
        return new ViewHolder(v);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder h, int position) {
        IssueReport p = danhSach.get(position);
        Context ctx = h.itemView.getContext();
        h.tvLoai.setText(ctx.getString(R.string.loai_va_san_pham,
                ctx.getString(StatusBadge.loaiPhanAnh(p.loai)), p.tenSanPham));
        StatusBadge.gan(h.tvTrangThai, p.trangThai);
        h.tvNoiDung.setText(p.noiDung);
        h.tvNguoiBao.setText(ctx.getString(R.string.nguoi_bao_luc, p.tenNguoiBao, Formatting.thoiDiem(p.taoLuc)));
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
