package vn.edu.vhu.ltdd.gugugaga.admin.ui;

import android.content.Intent;
import android.os.Bundle;
import android.view.HapticFeedbackConstants;

import androidx.activity.EdgeToEdge;
import androidx.annotation.StringRes;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;

import com.google.android.material.appbar.MaterialToolbar;
import com.google.android.material.bottomnavigation.BottomNavigationView;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.data.TokenStore;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.login.LoginActivity;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.order.OrderListFragment;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.batch.BatchListFragment;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.issuereport.IssueReportListFragment;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.product.ProductListFragment;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.account.AccountFragment;

/**
 * Một Activity chứa nhiều Fragment, chuyển tab bằng BottomNavigationView (Lab A8).
 * - Chuyển tab: replace, KHÔNG addToBackStack, nên Back ở tab là thoát app.
 * - Mở chi tiết: replace + addToBackStack (moManHinh), Back quay về danh sách.
 */
public class MainActivity extends AppCompatActivity {
    private MaterialToolbar toolbar;

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

        toolbar = findViewById(R.id.toolbar);
        // Nút mũi tên trên toolbar làm giống nút Back của hệ thống.
        toolbar.setNavigationOnClickListener(v -> getOnBackPressedDispatcher().onBackPressed());
        getSupportFragmentManager().addOnBackStackChangedListener(this::capNhatNutQuayLai);
        capNhatNutQuayLai();

        BottomNavigationView bottomNav = findViewById(R.id.bottomNav);
        // R.id.main đã xử lý padding thanh hệ thống; tắt inset lặp để icon nằm chính giữa viên nổi.
        ViewCompat.setOnApplyWindowInsetsListener(bottomNav, (v, insets) -> insets);
        bottomNav.setOnItemSelectedListener(item -> {
            bottomNav.performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK);
            int id = item.getItemId();
            // if-else thay cho switch: từ AGP 8, R.id không còn là hằng số (Lab A4, A8).
            if (id == R.id.tab_products) doiTab(new ProductListFragment(), true);
            else if (id == R.id.tab_batches) doiTab(new BatchListFragment(), true);
            else if (id == R.id.tab_orders) doiTab(new OrderListFragment(), true);
            else if (id == R.id.tab_issue_reports) doiTab(new IssueReportListFragment(), true);
            else if (id == R.id.tab_accounts) doiTab(new AccountFragment(), true);
            return true; // true = tô sáng tab vừa chọn
        });

        // Chỉ nạp Fragment mặc định lần đầu; khi xoay, FragmentManager tự khôi phục (Lab A8).
        if (savedInstanceState == null) {
            doiTab(new ProductListFragment(), false);
        }
    }

    private void doiTab(Fragment f, boolean coHieuUng) {
        FragmentManager fm = getSupportFragmentManager();
        // Đang ở màn hình chi tiết mà bấm tab khác: bỏ các màn hình chi tiết trước.
        fm.popBackStack(null, FragmentManager.POP_BACK_STACK_INCLUSIVE);
        androidx.fragment.app.FragmentTransaction tx = fm.beginTransaction();
        if (coHieuUng) {
            tx.setCustomAnimations(R.anim.tab_enter, R.anim.tab_exit);
        }
        tx.replace(R.id.fragmentContainer, f)
                .setReorderingAllowed(true)
                .commit();
    }

    /** Mở màn hình chi tiết/form: replace + addToBackStack kèm hiệu ứng trượt mượt (Lab A8). */
    public void moManHinh(Fragment f) {
        getSupportFragmentManager()
                .beginTransaction()
                .setCustomAnimations(R.anim.screen_enter, R.anim.screen_exit, R.anim.screen_pop_enter, R.anim.screen_pop_exit)
                .replace(R.id.fragmentContainer, f)
                .setReorderingAllowed(true)
                .addToBackStack(null)
                .commit();
    }

    /** Mỗi Fragment đặt tiêu đề của mình trong onViewCreated. */
    public void datTieuDe(@StringRes int tieuDe) {
        if (toolbar != null) toolbar.setTitle(tieuDe);
    }

    private void capNhatNutQuayLai() {
        boolean coManHinhTruoc = getSupportFragmentManager().getBackStackEntryCount() > 0;
        if (coManHinhTruoc) {
            toolbar.setNavigationIcon(R.drawable.ic_back);
            toolbar.setNavigationContentDescription(R.string.quay_lai);
        } else {
            toolbar.setNavigationIcon(null);
        }
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
