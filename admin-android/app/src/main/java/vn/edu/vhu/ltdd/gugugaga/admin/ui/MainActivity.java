package vn.edu.vhu.ltdd.gugugaga.admin.ui;

import android.content.Intent;
import android.os.Bundle;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.fragment.app.Fragment;

import com.google.android.material.bottomnavigation.BottomNavigationView;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.data.TokenStore;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.dangnhap.LoginActivity;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.sanpham.SanPhamFragment;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.taikhoan.TaiKhoanFragment;

/**
 * Một Activity chứa nhiều Fragment, chuyển tab bằng BottomNavigationView (Lab A8).
 * Chuyển tab dùng replace và KHÔNG addToBackStack, nên Back ở tab là thoát app.
 */
public class MainActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (!TokenStore.daDangNhap(this)) {
            dangXuat(false);
            return;
        }
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_main);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets bars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(bars.left, bars.top, bars.right, bars.bottom);
            return insets;
        });

        BottomNavigationView bottomNav = findViewById(R.id.bottomNav);
        bottomNav.setOnItemSelectedListener(item -> {
            int id = item.getItemId();
            // if-else thay cho switch: từ AGP 8, R.id không còn là hằng số (Lab A4, A8).
            if (id == R.id.tab_san_pham) doiTab(new SanPhamFragment());
            else if (id == R.id.tab_tai_khoan) doiTab(new TaiKhoanFragment());
            return true; // true = tô sáng tab vừa chọn
        });

        // Chỉ nạp Fragment mặc định lần đầu; khi xoay, FragmentManager tự khôi phục (Lab A8).
        if (savedInstanceState == null) {
            doiTab(new SanPhamFragment());
        }
    }

    private void doiTab(Fragment f) {
        getSupportFragmentManager()
                .beginTransaction()
                .replace(R.id.fragmentContainer, f)
                .setReorderingAllowed(true)
                .commit();
    }

    /**
     * Xóa phiên và về màn hình đăng nhập, xóa toàn bộ back stack để Back không quay lại.
     * @param hetPhien true khi bị đăng xuất do backend trả 401.
     */
    public void dangXuat(boolean hetPhien) {
        TokenStore.xoa(this);
        Intent i = new Intent(this, LoginActivity.class);
        i.putExtra(LoginActivity.EXTRA_HET_PHIEN, hetPhien);
        i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        startActivity(i);
        finish();
    }
}
