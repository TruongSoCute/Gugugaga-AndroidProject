package vn.edu.vhu.ltdd.gugugaga.admin.ui.chung;

import android.app.Dialog;
import android.os.Bundle;
import android.view.View;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.fragment.app.DialogFragment;

import com.google.android.material.dialog.MaterialAlertDialogBuilder;
import com.google.android.material.textfield.TextInputEditText;
import com.google.android.material.textfield.TextInputLayout;

import vn.edu.vhu.ltdd.gugugaga.admin.R;

/**
 * Hộp thoại xác nhận trước mỗi thao tác quan trọng (C.1 #6), có thể kèm ô nhập lý do/kết quả.
 * - Ô nhập bắt buộc: để trống thì setError ngay tại ô, không đóng hộp thoại (Lab A4).
 * - Kết quả trả về Fragment cha qua Fragment Result API (Lab A8), kèm Bundle "duLieuKem".
 * - DialogFragment tự tạo lại khi xoay; EditText có id nên chữ đang nhập vẫn còn (Lab A2).
 */
public class XacNhanDialog extends DialogFragment {
    public static final int KHONG_NHAP = 0;
    public static final int NHAP_TUY_CHON = 1;
    public static final int NHAP_BAT_BUOC = 2;

    /** Khóa trong Bundle kết quả: nội dung đã nhập (null nếu không nhập). */
    public static final String KEY_NOI_DUNG = "noi_dung";

    private static final String ARG_REQUEST_KEY = "request_key";
    private static final String ARG_TIEU_DE = "tieu_de";
    private static final String ARG_THONG_DIEP = "thong_diep";
    private static final String ARG_NUT = "nut";
    private static final String ARG_KIEU_NHAP = "kieu_nhap";
    private static final String ARG_GOI_Y = "goi_y";
    private static final String ARG_LOI_TRONG = "loi_trong";
    private static final String ARG_KEM = "kem";

    /**
     * @param kem dữ liệu gửi trả nguyên vẹn trong kết quả (vd trạng thái mới cần chuyển tới).
     */
    public static XacNhanDialog newInstance(String requestKey, String tieuDe, String thongDiep,
                                            String nutDongY, int kieuNhap, String goiY,
                                            String loiTrong, Bundle kem) {
        XacNhanDialog d = new XacNhanDialog();
        Bundle a = new Bundle();
        a.putString(ARG_REQUEST_KEY, requestKey);
        a.putString(ARG_TIEU_DE, tieuDe);
        a.putString(ARG_THONG_DIEP, thongDiep);
        a.putString(ARG_NUT, nutDongY);
        a.putInt(ARG_KIEU_NHAP, kieuNhap);
        a.putString(ARG_GOI_Y, goiY);
        a.putString(ARG_LOI_TRONG, loiTrong);
        a.putBundle(ARG_KEM, kem);
        d.setArguments(a);
        return d;
    }

    @NonNull
    @Override
    public Dialog onCreateDialog(@Nullable Bundle savedInstanceState) {
        Bundle a = requireArguments();
        View v = getLayoutInflater().inflate(R.layout.dialog_xac_nhan, null);
        TextView tvThongDiep = v.findViewById(R.id.tvThongDiep);
        TextInputLayout til = v.findViewById(R.id.tilNoiDung);
        String thongDiep = a.getString(ARG_THONG_DIEP);
        tvThongDiep.setText(thongDiep);
        tvThongDiep.setVisibility(thongDiep == null ? View.GONE : View.VISIBLE);
        int kieu = a.getInt(ARG_KIEU_NHAP, KHONG_NHAP);
        til.setVisibility(kieu == KHONG_NHAP ? View.GONE : View.VISIBLE);
        til.setHint(a.getString(ARG_GOI_Y));
        return new MaterialAlertDialogBuilder(requireContext())
                .setTitle(a.getString(ARG_TIEU_DE))
                .setView(v)
                .setPositiveButton(a.getString(ARG_NUT), null) // gán lại trong onStart để kiểm tra trước khi đóng
                .setNegativeButton(R.string.nut_huy, null)
                .create();
    }

    @Override
    public void onStart() {
        super.onStart();
        AlertDialog dialog = (AlertDialog) requireDialog();
        TextInputLayout til = dialog.findViewById(R.id.tilNoiDung);
        TextInputEditText edt = dialog.findViewById(R.id.edtNoiDung);
        Bundle a = requireArguments();
        int kieu = a.getInt(ARG_KIEU_NHAP, KHONG_NHAP);
        dialog.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener(btn -> {
            String noiDung = edt == null || edt.getText() == null ? "" : edt.getText().toString().trim();
            if (kieu == NHAP_BAT_BUOC && noiDung.isEmpty()) {
                til.setError(a.getString(ARG_LOI_TRONG));
                edt.requestFocus();
                return;
            }
            Bundle kem = a.getBundle(ARG_KEM);
            Bundle kq = kem == null ? new Bundle() : new Bundle(kem);
            kq.putString(KEY_NOI_DUNG, kieu == KHONG_NHAP || noiDung.isEmpty() ? null : noiDung);
            getParentFragmentManager().setFragmentResult(a.getString(ARG_REQUEST_KEY, ""), kq);
            dismiss();
        });
    }
}
