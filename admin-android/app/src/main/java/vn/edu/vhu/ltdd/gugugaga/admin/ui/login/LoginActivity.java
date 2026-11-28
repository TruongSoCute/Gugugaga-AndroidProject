package vn.edu.vhu.ltdd.gugugaga.admin.ui.login;

import android.content.Intent;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.util.Log;
import android.util.Patterns;
import android.view.View;
import android.view.animation.DecelerateInterpolator;
import android.widget.Button;
import android.widget.ProgressBar;
import android.widget.TextView;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.lifecycle.ViewModelProvider;

import com.google.android.material.textfield.TextInputEditText;
import com.google.android.material.textfield.TextInputLayout;

import vn.edu.vhu.ltdd.gugugaga.admin.AppConfig;
import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.data.TokenStore;
import vn.edu.vhu.ltdd.gugugaga.admin.model.LoginResult;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.MainActivity;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.Animations;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.UiState;

/**
 * Màn hình 1: đăng nhập (C.1 #1). Kiểm tra form theo thứ tự trên màn hình, sai ô nào báo
 * ngay tại ô đó (Lab A4, A6). Thành công thì lưu token và mở MainActivity (Lab A5).
 */
public class LoginActivity extends AppCompatActivity {
    /** Extra báo cho màn hình biết người dùng bị đăng xuất vì token hết hạn. */
    public static final String EXTRA_HET_PHIEN = "extra_het_phien";

    private TextInputLayout tilEmail;
    private TextInputLayout tilMatKhau;
    private TextInputEditText edtEmail;
    private TextInputEditText edtMatKhau;
    private Button btnDangNhap;
    private ProgressBar progress;
    private TextView tvLoi;
    private LoginViewModel viewModel;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Đã có token thì vào thẳng màn hình chính; nếu token hết hạn, API đầu tiên trả 401
        // và app tự quay lại đây.
        if (TokenStore.daDangNhap(this)) {
            moManHinhChinh();
            return;
        }

        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_login);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets bars = insets.getInsets(WindowInsetsCompat.Type.systemBars() | WindowInsetsCompat.Type.ime());
            v.setPadding(bars.left, bars.top, bars.right, bars.bottom);
            return insets;
        });

        tilEmail = findViewById(R.id.tilEmail);
        tilMatKhau = findViewById(R.id.tilMatKhau);
        edtEmail = findViewById(R.id.edtEmail);
        edtMatKhau = findViewById(R.id.edtMatKhau);
        btnDangNhap = findViewById(R.id.btnDangNhap);
        progress = findViewById(R.id.progress);
        tvLoi = findViewById(R.id.tvLoi);
        TextView tvChaoPass = findViewById(R.id.tvChaoPass);
        View thePass = findViewById(R.id.thePassAdmin);
        View cardForm = findViewById(R.id.cardFormLogin);

        // Hiệu ứng nổi mượt cho thẻ định danh & tấm form khi mở màn đăng nhập.
        if (savedInstanceState == null) {
            float dich = 18 * getResources().getDisplayMetrics().density;
            thePass.setAlpha(0f);
            thePass.setTranslationY(dich);
            thePass.animate().alpha(1f).translationY(0f).setDuration(320)
                    .setInterpolator(new DecelerateInterpolator(1.8f)).start();
            cardForm.setAlpha(0f);
            cardForm.setTranslationY(dich);
            cardForm.animate().alpha(1f).translationY(0f).setStartDelay(90).setDuration(320)
                    .setInterpolator(new DecelerateInterpolator(1.8f)).start();
        }

        // Cập nhật tên định danh trên thẻ Pass theo phần đầu email đang nhập.
        edtEmail.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence s, int start, int count, int after) { }
            @Override public void onTextChanged(CharSequence s, int start, int before, int count) { }
            @Override
            public void afterTextChanged(Editable s) {
                String raw = s == null ? "" : s.toString().trim();
                int at = raw.indexOf('@');
                String ten = at > 0 ? raw.substring(0, at) : raw;
                tvChaoPass.setText(ten.isEmpty() ? getString(R.string.dang_nhap_tieu_de) : ten);
            }
        });

        if (savedInstanceState == null && getIntent().getBooleanExtra(EXTRA_HET_PHIEN, false)) {
            hienLoi(getString(R.string.thong_bao_het_phien));
        }

        btnDangNhap.setOnClickListener(v -> xuLyDangNhap());
        Animations.ganNhanNhe(btnDangNhap);

        viewModel = new ViewModelProvider(this).get(LoginViewModel.class);
        viewModel.getTrangThai().observe(this, this::hienThi);
    }

    /** Bốn lớp kiểm tra (Lab A4): rỗng -> định dạng; gặp lỗi thì return ngay. */
    private void xuLyDangNhap() {
        tilEmail.setError(null);
        tilMatKhau.setError(null);
        String email = chuoi(edtEmail).trim();
        String matKhau = chuoi(edtMatKhau);

        if (email.isEmpty()) {
            tilEmail.setError(getString(R.string.loi_email_trong));
            Animations.rungLoi(tilEmail);
            edtEmail.requestFocus();
            return;
        }
        if (!Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
            tilEmail.setError(getString(R.string.loi_email_sai));
            Animations.rungLoi(tilEmail);
            edtEmail.requestFocus();
            return;
        }
        if (matKhau.isEmpty()) {
            tilMatKhau.setError(getString(R.string.loi_mat_khau_trong));
            Animations.rungLoi(tilMatKhau);
            edtMatKhau.requestFocus();
            return;
        }
        viewModel.dangNhap(email, matKhau);
    }

    private void hienThi(UiState<LoginResult> tt) {
        boolean dangTai = tt.loai == UiState.Loai.DANG_TAI;
        progress.setVisibility(dangTai ? View.VISIBLE : View.GONE);
        btnDangNhap.setEnabled(!dangTai);
        switch (tt.loai) {
            case DANG_TAI:
                tvLoi.setVisibility(View.GONE);
                break;
            case THANH_CONG:
                Log.d(AppConfig.TAG, "Đăng nhập thành công, vai trò " + tt.duLieu.nguoiDung.vaiTro);
                moManHinhChinh();
                break;
            case LOI:
            case HET_PHIEN:
                hienLoi(tt.thongDiep);
                break;
        }
    }

    private void hienLoi(String thongDiep) {
        tvLoi.setText(thongDiep);
        tvLoi.setVisibility(View.VISIBLE);
        Animations.rungLoi(tvLoi);
    }

    private void moManHinhChinh() {
        startActivity(new Intent(this, MainActivity.class));
        finish(); // bấm Back ở màn hình chính không quay lại form đăng nhập
    }

    private static String chuoi(TextInputEditText edt) {
        return edt.getText() == null ? "" : edt.getText().toString();
    }
}
