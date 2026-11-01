package vn.edu.vhu.ltdd.gugugaga.admin.ui.lo;

import android.app.DatePickerDialog;
import android.app.Dialog;
import android.app.TimePickerDialog;
import android.os.Bundle;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.fragment.app.DialogFragment;

import com.google.android.material.dialog.MaterialAlertDialogBuilder;
import com.google.android.material.textfield.TextInputEditText;
import com.google.android.material.textfield.TextInputLayout;

import java.util.Calendar;
import java.util.TimeZone;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.util.DinhDang;
import vn.edu.vhu.ltdd.gugugaga.admin.util.KiemTraForm;

/**
 * Form thêm một bước truy xuất (tên bước, thời điểm, mô tả, ảnh URL). Kiểm tra theo thứ tự trên
 * màn hình, sai ô nào báo tại ô đó (Lab A4, A6). Thời điểm đã chọn lưu bằng onSaveInstanceState
 * nên xoay màn hình không mất (Lab A2); các ô EditText có id tự khôi phục.
 */
public class ThemBuocDialog extends DialogFragment {
    public static final String REQUEST_KEY = "them_buoc";
    public static final String KEY_TEN_BUOC = "ten_buoc";
    public static final String KEY_THOI_DIEM = "thoi_diem";
    public static final String KEY_MO_TA = "mo_ta";
    public static final String KEY_ANH_URL = "anh_url";

    private static final TimeZone GIO_VN = TimeZone.getTimeZone("GMT+07:00");

    /** Thời điểm đã chọn, dạng ISO có múi giờ +07:00; null nếu chưa chọn. */
    private String thoiDiem;

    @NonNull
    @Override
    public Dialog onCreateDialog(@Nullable Bundle savedInstanceState) {
        if (savedInstanceState != null) thoiDiem = savedInstanceState.getString(KEY_THOI_DIEM);
        View v = getLayoutInflater().inflate(R.layout.dialog_them_buoc, null);
        return new MaterialAlertDialogBuilder(requireContext())
                .setTitle(R.string.tieu_de_them_buoc)
                .setView(v)
                .setPositiveButton(R.string.nut_them, null) // gán lại trong onStart để kiểm tra trước khi đóng
                .setNegativeButton(R.string.nut_huy, null)
                .create();
    }

    @Override
    public void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState); // luôn gọi super để EditText tự lưu (Lab A2)
        outState.putString(KEY_THOI_DIEM, thoiDiem);
    }

    @Override
    public void onStart() {
        super.onStart();
        AlertDialog d = (AlertDialog) requireDialog();
        TextInputLayout tilTen = d.findViewById(R.id.tilTenBuoc);
        TextInputEditText edtTen = d.findViewById(R.id.edtTenBuoc);
        TextInputLayout tilThoiDiem = d.findViewById(R.id.tilThoiDiem);
        TextInputEditText edtThoiDiem = d.findViewById(R.id.edtThoiDiem);
        TextInputEditText edtMoTa = d.findViewById(R.id.edtMoTa);
        TextInputLayout tilAnh = d.findViewById(R.id.tilAnhUrl);
        TextInputEditText edtAnh = d.findViewById(R.id.edtAnhUrl);

        edtThoiDiem.setText(DinhDang.thoiDiemDaChon(thoiDiem));
        edtThoiDiem.setOnClickListener(v -> chonThoiDiem(edtThoiDiem, tilThoiDiem));

        d.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener(btn -> {
            tilTen.setError(null);
            tilThoiDiem.setError(null);
            tilAnh.setError(null);
            String ten = chuoi(edtTen);
            String moTa = chuoi(edtMoTa);
            String anh = chuoi(edtAnh);
            // 1. rỗng → 2. định dạng; gặp lỗi thì return ngay (Lab A4).
            if (ten.isEmpty()) {
                tilTen.setError(getString(R.string.loi_ten_buoc_trong));
                edtTen.requestFocus();
                return;
            }
            if (thoiDiem == null) {
                tilThoiDiem.setError(getString(R.string.loi_thoi_diem_trong));
                return;
            }
            if (!anh.isEmpty() && !KiemTraForm.laUrlWeb(anh)) {
                tilAnh.setError(getString(R.string.loi_url_anh));
                edtAnh.requestFocus();
                return;
            }
            Bundle kq = new Bundle();
            kq.putString(KEY_TEN_BUOC, ten);
            kq.putString(KEY_THOI_DIEM, thoiDiem);
            kq.putString(KEY_MO_TA, moTa.isEmpty() ? null : moTa);
            kq.putString(KEY_ANH_URL, anh.isEmpty() ? null : anh);
            getParentFragmentManager().setFragmentResult(REQUEST_KEY, kq);
            dismiss();
        });
    }

    /** Chọn ngày (DatePickerDialog) rồi chọn giờ (TimePickerDialog), mặc định là lúc này. */
    private void chonThoiDiem(TextInputEditText edt, TextInputLayout til) {
        Calendar c = Calendar.getInstance(GIO_VN);
        new DatePickerDialog(requireContext(), (dp, nam, thang0, ngay) ->
                new TimePickerDialog(requireContext(), (tp, gio, phut) -> {
                    // Tháng của DatePicker tính từ 0 nên cộng 1.
                    thoiDiem = DinhDang.thoiDiemIso(nam, thang0 + 1, ngay, gio, phut);
                    edt.setText(DinhDang.thoiDiemDaChon(thoiDiem));
                    til.setError(null);
                }, c.get(Calendar.HOUR_OF_DAY), c.get(Calendar.MINUTE), true).show(),
                c.get(Calendar.YEAR), c.get(Calendar.MONTH), c.get(Calendar.DAY_OF_MONTH)).show();
    }

    private static String chuoi(TextInputEditText edt) {
        return edt.getText() == null ? "" : edt.getText().toString().trim();
    }
}
