package vn.edu.vhu.ltdd.gugugaga.admin.ui.chung;

import android.graphics.Bitmap;
import android.view.View;
import android.widget.ImageView;

import androidx.fragment.app.Fragment;

import com.google.android.material.snackbar.Snackbar;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.data.AnhRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.data.KetQuaApi;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.MainActivity;

/** Việc lặp lại ở mọi màn hình gọi API: Snackbar báo kết quả, 401 thì đăng xuất, hiện ảnh. */
public final class ManHinh {
    private ManHinh() { }

    /** Gọi trong onViewCreated, sau khi lấy ViewModel. */
    public static void quanSatChung(Fragment f, CoSoViewModel vm) {
        vm.getThongBao().observe(f.getViewLifecycleOwner(), sk -> {
            String tb = sk.layNeuChuaXuLy();
            if (tb != null) baoSnackbar(f, tb);
        });
        vm.getHetPhien().observe(f.getViewLifecycleOwner(), het -> {
            if (Boolean.TRUE.equals(het)) ((MainActivity) f.requireActivity()).dangXuat(true);
        });
    }

    /** Snackbar đặt trên thanh điều hướng dưới để không che các tab. */
    public static void baoSnackbar(Fragment f, String noiDung) {
        View goc = f.getView();
        if (goc == null) return;
        Snackbar s = Snackbar.make(goc, noiDung, Snackbar.LENGTH_LONG);
        View nav = f.requireActivity().findViewById(R.id.bottomNav);
        if (nav != null) s.setAnchorView(nav);
        s.show();
    }

    /** Tải ảnh từ URL vào ImageView; không có URL hoặc tải lỗi thì ẩn ImageView. */
    public static void hienAnh(Fragment f, ImageView iv, String url) {
        if (url == null || url.isEmpty()) {
            iv.setVisibility(View.GONE);
            return;
        }
        iv.setVisibility(View.VISIBLE);
        iv.setImageDrawable(null);
        new AnhRepository(f.requireContext()).tai(url, new KetQuaApi<Bitmap>() {
            @Override
            public void thanhCong(Bitmap anh) {
                if (f.getView() != null) iv.setImageBitmap(anh); // View có thể đã bị hủy khi ảnh về
            }

            @Override
            public void loi(String thongDiep) {
                if (f.getView() != null) iv.setVisibility(View.GONE);
            }

            @Override
            public void hetPhien() { }
        });
    }
}
