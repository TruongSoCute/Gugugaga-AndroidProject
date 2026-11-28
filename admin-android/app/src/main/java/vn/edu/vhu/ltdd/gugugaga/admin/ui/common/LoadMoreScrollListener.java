package vn.edu.vhu.ltdd.gugugaga.admin.ui.common;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import java.util.List;

/**
 * Phân trang khi cuộn: lắng nghe RecyclerView, khi người dùng cuộn xuống và còn ít hơn
 * NGUONG dòng chưa hiện thì gọi taiThem (thường là viewModel::taiThem). ViewModel tự bỏ qua
 * lời gọi thừa khi đang tải hoặc đã hết dữ liệu.
 */
public class LoadMoreScrollListener extends RecyclerView.OnScrollListener {
    /** Còn 5 dòng nữa là tới cuối thì bắt đầu tải trang sau, để người dùng ít phải chờ. */
    private static final int NGUONG = 5;

    private final Runnable taiThem;

    public LoadMoreScrollListener(Runnable taiThem) {
        this.taiThem = taiThem;
    }

    @Override
    public void onScrolled(@NonNull RecyclerView rv, int dx, int dy) {
        if (dy <= 0) return; // chỉ xét khi cuộn xuống
        RecyclerView.LayoutManager lm = rv.getLayoutManager();
        if (!(lm instanceof LinearLayoutManager)) return;
        int tong = lm.getItemCount();
        int dongCuoi = ((LinearLayoutManager) lm).findLastVisibleItemPosition();
        if (tong > 0 && dongCuoi >= tong - NGUONG) taiThem.run();
    }

    /**
     * Đổ danh sách mới vào adapter. Nếu danh sách mới chỉ là danh sách cũ nối thêm trang sau
     * (dòng cuối cũ vẫn ở đúng chỗ) thì chỉ báo phần chèn thêm bằng notifyItemRangeInserted để
     * không vẽ lại và không nhảy vị trí cuộn; các trường hợp khác (tải lại, đổi bộ lọc) thay
     * toàn bộ bằng notifyDataSetChanged (Lab A9).
     *
     * @param hienCo danh sách adapter đang giữ (sẽ được sửa).
     */
    public static <T> void capNhat(RecyclerView.Adapter<?> adapter, List<T> hienCo, List<T> moi) {
        int cu = hienCo.size();
        if (moi != null && cu > 0 && moi.size() > cu && moi.get(cu - 1) == hienCo.get(cu - 1)) {
            hienCo.addAll(moi.subList(cu, moi.size()));
            adapter.notifyItemRangeInserted(cu, moi.size() - cu);
            return;
        }
        hienCo.clear();
        if (moi != null) hienCo.addAll(moi);
        adapter.notifyDataSetChanged(); // sửa dữ liệu xong phải báo cho danh sách vẽ lại (Lab A9)
    }
}
