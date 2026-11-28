package vn.edu.vhu.ltdd.gugugaga.admin.ui.product;

import android.content.Context;
import android.graphics.Bitmap;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.RecyclerView;

import java.util.ArrayList;
import java.util.List;

import vn.edu.vhu.ltdd.gugugaga.admin.AppConfig;
import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.data.ImageRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.data.ApiResult;
import vn.edu.vhu.ltdd.gugugaga.admin.model.Product;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.Animations;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.LoadMoreScrollListener;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.StatusBadge;
import vn.edu.vhu.ltdd.gugugaga.admin.util.Formatting;

/**
 * Adapter + ViewHolder cho RecyclerView (C.1 #3, Lab A9/A10): thẻ sản phẩm trực quan kèm ảnh
 * (tải qua ImageRepository có bộ nhớ đệm), giá và 2 tag (hạng sao + trạng thái) gọn trên 1 hàng.
 */
public class ProductAdapter extends RecyclerView.Adapter<ProductAdapter.ViewHolder> {

    /** Hành động trên một dòng; Fragment xử lý (mở hộp thoại). */
    public interface HanhDong {
        void onDuyet(Product sp);
        void onTuChoi(Product sp);
    }

    private final List<Product> danhSach = new ArrayList<>();
    private final boolean coQuyenDuyet;
    private final HanhDong hanhDong;
    private ImageRepository anhRepo;

    public ProductAdapter(boolean coQuyenDuyet, HanhDong hanhDong) {
        this.coQuyenDuyet = coQuyenDuyet;
        this.hanhDong = hanhDong;
    }

    /** Trang sau thì chỉ chèn thêm các dòng mới; tải lại thì thay toàn bộ (LoadMoreScrollListener.capNhat). */
    public void capNhat(List<Product> moi) {
        LoadMoreScrollListener.capNhat(this, danhSach, moi);
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        if (anhRepo == null) anhRepo = new ImageRepository(parent.getContext());
        // Tham số thứ ba phải là false: RecyclerView tự gắn dòng vào (Lab A9).
        View v = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_product, parent, false);
        return new ViewHolder(v);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder h, int position) {
        // Gán dữ liệu ở MỌI lần bind, vì ViewHolder được tái sử dụng khi cuộn.
        Product sp = danhSach.get(position);
        Context ctx = h.itemView.getContext();

        h.tvTen.setText(sp.ten);
        h.tvNhaCungCap.setText(ctx.getString(R.string.ncc_vung, sp.tenVung, sp.tenNhaCungCap));
        h.tvGia.setText(Formatting.tien(sp.gia));

        // Tải ảnh sản phẩm qua bộ nhớ đệm; kiểm tra tag để tránh nhảy ảnh khi cuộn nhanh.
        String url = sp.anhUrl;
        h.ivAnh.setTag(url);
        h.ivAnh.setImageResource(R.drawable.ic_launcher_foreground);
        if (url != null && !url.isEmpty() && anhRepo != null) {
            anhRepo.tai(url, new ApiResult<Bitmap>() {
                @Override
                public void thanhCong(Bitmap bmp) {
                    if (url.equals(h.ivAnh.getTag())) {
                        h.ivAnh.setImageBitmap(bmp);
                    }
                }

                @Override
                public void loi(String thongDiep) {
                    // Giữ ảnh mặc định gọn nhẹ.
                }

                @Override
                public void hetPhien() {
                    // Ảnh công khai không đổi phiên.
                }
            });
        }

        if (sp.hangSao != null) {
            h.tvHangSao.setVisibility(View.VISIBLE);
            h.tvHangSao.setText(ctx.getString(R.string.hang_sao, sp.hangSao));
            h.tvHangSao.setTextColor(ContextCompat.getColor(ctx, R.color.vang_cho_duyet));
        } else {
            h.tvHangSao.setVisibility(View.GONE);
        }

        StatusBadge.gan(h.tvTrangThai, sp.trangThaiDuyet);

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
        final ImageView ivAnh;
        final TextView tvTen, tvNhaCungCap, tvGia, tvHangSao, tvTrangThai, tvLyDo, tvNccChuaDuyet;
        final View hangNut;
        final Button btnDuyet, btnTuChoi;

        ViewHolder(@NonNull View v) {
            super(v);
            Animations.ganNhanNhe(v);
            ivAnh = v.findViewById(R.id.ivAnh);
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
