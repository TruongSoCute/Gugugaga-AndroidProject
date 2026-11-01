package vn.edu.vhu.ltdd.gugugaga.admin.ui.chung;

import android.content.Context;
import android.view.ViewGroup;
import android.widget.LinearLayout;

import com.google.android.material.button.MaterialButton;

import java.util.List;

/**
 * Vẽ các nút chuyển trạng thái hợp lệ (danh sách lấy từ util/QuyTacTrangThai). Chỉ hiện bước
 * được phép cho gọn; backend vẫn chặn bằng 403/409 nếu bước chuyển sai.
 */
public final class NutThaoTac {
    public interface KhiBam {
        void bam(String trangThaiMoi);
    }

    private NutThaoTac() { }

    public static void ve(LinearLayout hang, List<String> cacTrangThaiMoi, boolean khoa, KhiBam khiBam) {
        hang.removeAllViews();
        Context ctx = hang.getContext();
        for (String moi : cacTrangThaiMoi) {
            MaterialButton b = NhanTrangThai.laThaoTacPhu(moi)
                    ? new MaterialButton(ctx, null, com.google.android.material.R.attr.materialButtonOutlinedStyle)
                    : new MaterialButton(ctx);
            b.setText(NhanTrangThai.nut(moi));
            b.setEnabled(!khoa);
            b.setOnClickListener(v -> khiBam.bam(moi));
            hang.addView(b, new LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        }
    }
}
