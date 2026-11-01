package vn.edu.vhu.ltdd.gugugaga.admin.ui.sanpham;

import android.app.Dialog;
import android.os.Bundle;
import android.view.View;
import android.widget.RadioGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.fragment.app.DialogFragment;

import com.google.android.material.dialog.MaterialAlertDialogBuilder;

import vn.edu.vhu.ltdd.gugugaga.admin.R;

/**
 * Hộp thoại xác nhận duyệt và chọn hạng OCOP (RadioGroup: chọn đúng một trong ít phương án — Lab A6).
 * Kết quả trả về Fragment cha qua Fragment Result API (Lab A8). DialogFragment tự khôi phục khi xoay.
 */
public class DuyetSanPhamDialog extends DialogFragment {
    public static final String REQUEST_KEY = "duyet_san_pham";
    public static final String KEY_ID = "id";
    public static final String KEY_TEN = "ten";
    public static final String KEY_HANG_SAO = "hang_sao";

    /** Truyền dữ liệu qua arguments, không qua constructor (Lab A8). */
    public static DuyetSanPhamDialog newInstance(int id, String ten) {
        DuyetSanPhamDialog d = new DuyetSanPhamDialog();
        Bundle args = new Bundle();
        args.putInt(KEY_ID, id);
        args.putString(KEY_TEN, ten);
        d.setArguments(args);
        return d;
    }

    @NonNull
    @Override
    public Dialog onCreateDialog(@Nullable Bundle savedInstanceState) {
        String ten = requireArguments().getString(KEY_TEN, "");
        View v = getLayoutInflater().inflate(R.layout.dialog_duyet, null);
        return new MaterialAlertDialogBuilder(requireContext())
                .setTitle(getString(R.string.duyet_tieu_de, ten))
                .setView(v)
                .setPositiveButton(R.string.nut_duyet, null) // gán lại trong onStart để kiểm tra trước khi đóng
                .setNegativeButton(R.string.nut_huy, null)
                .create();
    }

    @Override
    public void onStart() {
        super.onStart();
        AlertDialog dialog = (AlertDialog) requireDialog();
        RadioGroup rg = dialog.findViewById(R.id.rgHangSao);
        TextView tvLoi = dialog.findViewById(R.id.tvLoiDuyet);
        dialog.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener(btn -> {
            int chon = rg.getCheckedRadioButtonId();
            if (chon == -1) { // -1 = chưa chọn (Lab A6)
                tvLoi.setVisibility(View.VISIBLE);
                return;
            }
            int hangSao;
            if (chon == R.id.rbSao3) hangSao = 3;
            else if (chon == R.id.rbSao4) hangSao = 4;
            else hangSao = 5;

            Bundle kq = new Bundle();
            kq.putInt(KEY_ID, requireArguments().getInt(KEY_ID));
            kq.putString(KEY_TEN, requireArguments().getString(KEY_TEN, ""));
            kq.putInt(KEY_HANG_SAO, hangSao);
            getParentFragmentManager().setFragmentResult(REQUEST_KEY, kq);
            dismiss();
        });
    }
}
