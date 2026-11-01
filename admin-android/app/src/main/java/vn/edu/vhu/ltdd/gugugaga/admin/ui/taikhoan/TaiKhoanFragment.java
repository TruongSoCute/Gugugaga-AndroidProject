package vn.edu.vhu.ltdd.gugugaga.admin.ui.taikhoan;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import com.google.android.material.dialog.MaterialAlertDialogBuilder;

import vn.edu.vhu.ltdd.gugugaga.admin.AppConfig;
import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.data.TokenStore;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.MainActivity;

/** Tab Tài khoản: thông tin người đang đăng nhập và nút đăng xuất có xác nhận. */
public class TaiKhoanFragment extends Fragment {

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        // onCreateView chỉ inflate; ánh xạ View làm trong onViewCreated (Lab A8).
        return inflater.inflate(R.layout.fragment_tai_khoan, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        String vaiTro = TokenStore.layVaiTro(requireContext());
        boolean quanTri = AppConfig.VAI_TRO_QUAN_TRI.equals(vaiTro);

        ((TextView) view.findViewById(R.id.tvHoTen)).setText(TokenStore.layHoTen(requireContext()));
        ((TextView) view.findViewById(R.id.tvEmail)).setText(TokenStore.layEmail(requireContext()));
        ((TextView) view.findViewById(R.id.tvVaiTro)).setText(getString(R.string.tai_khoan_vai_tro,
                getString(quanTri ? R.string.vai_tro_quan_tri : R.string.vai_tro_nhan_vien)));
        ((TextView) view.findViewById(R.id.tvMayChu)).setText(getString(R.string.tai_khoan_may_chu, AppConfig.API_BASE_URL));
        view.findViewById(R.id.tvGhiChuNhanVien).setVisibility(quanTri ? View.GONE : View.VISIBLE);

        view.findViewById(R.id.btnDangXuat).setOnClickListener(v ->
                new MaterialAlertDialogBuilder(requireContext())
                        .setMessage(R.string.xac_nhan_dang_xuat)
                        .setPositiveButton(R.string.nut_dang_xuat, (d, w) -> ((MainActivity) requireActivity()).dangXuat(false))
                        .setNegativeButton(R.string.nut_huy, null)
                        .show());
    }
}
