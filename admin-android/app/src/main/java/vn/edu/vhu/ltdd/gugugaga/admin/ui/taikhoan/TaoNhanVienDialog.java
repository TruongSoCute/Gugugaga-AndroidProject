package vn.edu.vhu.ltdd.gugugaga.admin.ui.taikhoan;

import android.app.Dialog;
import android.os.Bundle;
import android.util.Patterns;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.fragment.app.DialogFragment;
import androidx.lifecycle.ViewModelProvider;

import com.google.android.material.dialog.MaterialAlertDialogBuilder;
import com.google.android.material.textfield.TextInputEditText;
import com.google.android.material.textfield.TextInputLayout;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauTaoNhanVien;

/** Hộp thoại tạo tài khoản nhân viên (chỉ QUAN_TRI). Giữ input khi xoay nhờ DialogFragment + View IDs. */
public class TaoNhanVienDialog extends DialogFragment {
    private TaiKhoanQuanTriViewModel viewModel;
    private TextInputLayout tilHoTen, tilEmail, tilMatKhau, tilSoDienThoai;
    private TextInputEditText edtHoTen, edtEmail, edtMatKhau, edtSoDienThoai;
    private boolean daGanQuanSat = false;

    @NonNull
    @Override
    public Dialog onCreateDialog(@Nullable Bundle savedInstanceState) {
        View v = getLayoutInflater().inflate(R.layout.dialog_tao_nhan_vien, null);
        return new MaterialAlertDialogBuilder(requireContext())
                .setTitle(R.string.tieu_de_tao_nhan_vien)
                .setView(v)
                .setPositiveButton(R.string.nut_tao_nhan_vien, null)
                .setNegativeButton(R.string.nut_huy, null)
                .create();
    }

    @Override
    public void onStart() {
        super.onStart();
        viewModel = new ViewModelProvider(requireParentFragment()).get(TaiKhoanQuanTriViewModel.class);
        AlertDialog dialog = (AlertDialog) requireDialog();
        tilHoTen = dialog.findViewById(R.id.tilHoTen);
        tilEmail = dialog.findViewById(R.id.tilEmail);
        tilMatKhau = dialog.findViewById(R.id.tilMatKhau);
        tilSoDienThoai = dialog.findViewById(R.id.tilSoDienThoai);
        edtHoTen = dialog.findViewById(R.id.edtHoTen);
        edtEmail = dialog.findViewById(R.id.edtEmail);
        edtMatKhau = dialog.findViewById(R.id.edtMatKhau);
        edtSoDienThoai = dialog.findViewById(R.id.edtSoDienThoai);

        if (!daGanQuanSat) {
            daGanQuanSat = true;
            viewModel.getTaoThanhCong().observe(this, sk -> {
                if (sk != null && sk.layNeuChuaXuLy() != null) dismiss();
            });
            viewModel.getLoiTao().observe(this, sk -> {
                TaiKhoanQuanTriViewModel.LoiTao loi = sk == null ? null : sk.layNeuChuaXuLy();
                if (loi == null) return;
                hienLoiBackend(loi);
            });
        }

        dialog.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener(btn -> gui());
    }

    private void gui() {
        tilHoTen.setError(null);
        tilEmail.setError(null);
        tilMatKhau.setError(null);
        tilSoDienThoai.setError(null);

        String hoTen = chuoi(edtHoTen);
        String email = chuoi(edtEmail);
        String matKhau = edtMatKhau.getText() == null ? "" : edtMatKhau.getText().toString();
        String sdt = chuoi(edtSoDienThoai);

        if (hoTen.isEmpty()) {
            tilHoTen.setError(getString(R.string.loi_ho_ten_trong));
            edtHoTen.requestFocus();
            return;
        }
        if (email.isEmpty()) {
            tilEmail.setError(getString(R.string.loi_email_trong));
            edtEmail.requestFocus();
            return;
        }
        if (!Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
            tilEmail.setError(getString(R.string.loi_email_sai));
            edtEmail.requestFocus();
            return;
        }
        if (matKhau.length() < 8) {
            tilMatKhau.setError(getString(R.string.loi_mat_khau_ngan));
            edtMatKhau.requestFocus();
            return;
        }

        viewModel.taoNhanVien(new YeuCauTaoNhanVien(email, matKhau, hoTen, sdt));
    }

    private void hienLoiBackend(TaiKhoanQuanTriViewModel.LoiTao loi) {
        if (!loi.loiTheoTruong.isEmpty()) {
            if (loi.loiTheoTruong.containsKey("hoTen")) tilHoTen.setError(loi.loiTheoTruong.get("hoTen"));
            if (loi.loiTheoTruong.containsKey("email")) tilEmail.setError(loi.loiTheoTruong.get("email"));
            if (loi.loiTheoTruong.containsKey("matKhau")) tilMatKhau.setError(loi.loiTheoTruong.get("matKhau"));
            if (loi.loiTheoTruong.containsKey("soDienThoai")) tilSoDienThoai.setError(loi.loiTheoTruong.get("soDienThoai"));
            return;
        }
        if (loi.thongDiep != null) {
            tilEmail.setError(loi.thongDiep);
        }
    }

    private String chuoi(TextInputEditText edt) {
        return edt.getText() == null ? "" : edt.getText().toString().trim();
    }
}
