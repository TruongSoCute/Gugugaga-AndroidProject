package vn.edu.vhu.ltdd.gugugaga.admin.ui.sanpham;

import android.app.Dialog;
import android.os.Bundle;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.fragment.app.DialogFragment;

import com.google.android.material.dialog.MaterialAlertDialogBuilder;
import com.google.android.material.textfield.TextInputEditText;
import com.google.android.material.textfield.TextInputLayout;

import vn.edu.vhu.ltdd.gugugaga.admin.R;

/** Hộp thoại xác nhận từ chối, bắt buộc nhập lý do (backend cũng bắt buộc — trả 400 nếu thiếu). */
public class TuChoiSanPhamDialog extends DialogFragment {
    public static final String REQUEST_KEY = "tu_choi_san_pham";
    public static final String KEY_ID = "id";
    public static final String KEY_TEN = "ten";
    public static final String KEY_LY_DO = "ly_do";

    public static TuChoiSanPhamDialog newInstance(int id, String ten) {
        TuChoiSanPhamDialog d = new TuChoiSanPhamDialog();
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
        View v = getLayoutInflater().inflate(R.layout.dialog_tu_choi, null);
        return new MaterialAlertDialogBuilder(requireContext())
                .setTitle(getString(R.string.tu_choi_tieu_de, ten))
                .setView(v)
                .setPositiveButton(R.string.nut_tu_choi, null)
                .setNegativeButton(R.string.nut_huy, null)
                .create();
    }

    @Override
    public void onStart() {
        super.onStart();
        AlertDialog dialog = (AlertDialog) requireDialog();
        TextInputLayout til = dialog.findViewById(R.id.tilLyDo);
        TextInputEditText edt = dialog.findViewById(R.id.edtLyDo);
        dialog.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener(btn -> {
            String lyDo = edt.getText() == null ? "" : edt.getText().toString().trim();
            if (lyDo.isEmpty()) {
                til.setError(getString(R.string.loi_ly_do_trong));
                edt.requestFocus();
                return;
            }
            Bundle kq = new Bundle();
            kq.putInt(KEY_ID, requireArguments().getInt(KEY_ID));
            kq.putString(KEY_TEN, requireArguments().getString(KEY_TEN, ""));
            kq.putString(KEY_LY_DO, lyDo);
            getParentFragmentManager().setFragmentResult(REQUEST_KEY, kq);
            dismiss();
        });
    }
}
