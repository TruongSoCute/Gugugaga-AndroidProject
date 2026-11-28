package vn.edu.vhu.ltdd.gugugaga.admin.ui.sales;

import android.animation.ValueAnimator;
import android.app.DatePickerDialog;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.model.SalesReport;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.MainActivity;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.Animations;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.StatePanel;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.ScreenLayout;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.UiState;
import vn.edu.vhu.ltdd.gugugaga.admin.util.Formatting;
import vn.edu.vhu.ltdd.gugugaga.admin.util.FormValidation;

/**
 * Báo cáo doanh số (chỉ QUAN_TRI, C.1 #7): tổng, biểu đồ cột tự vẽ theo vùng và theo hạng sao,
 * 5 nhà cung cấp bán chạy. Lọc từ ngày/đến ngày bằng DatePickerDialog; khoảng ngày đã chọn lưu
 * bằng onSaveInstanceState (Lab A2), báo cáo đã tải giữ trong ViewModel.
 */
public class SalesReportFragment extends Fragment {
    private static final String KEY_TU = "tu";
    private static final String KEY_DEN = "den";

    private SalesReportViewModel viewModel;
    private StatePanel khung;
    private View noiDung;
    private Button btnTu, btnDen;
    private TextView tvLoiLoc, tvTongDoanhSo, tvTongDon, tvTongSanPham, tvTrongTop;
    private BarChartView bdVung, bdHangSao;
    private LinearLayout dsTop;
    @Nullable
    private ValueAnimator animDoanhSo;
    private String tu;
    private String den;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_sales_report, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        ((MainActivity) requireActivity()).datTieuDe(R.string.tieu_de_bao_cao);
        if (savedInstanceState != null) {
            tu = savedInstanceState.getString(KEY_TU);
            den = savedInstanceState.getString(KEY_DEN);
        }
        viewModel = new ViewModelProvider(this).get(SalesReportViewModel.class);
        noiDung = view.findViewById(R.id.noiDung);
        btnTu = view.findViewById(R.id.btnTuNgay);
        btnDen = view.findViewById(R.id.btnDenNgay);
        tvLoiLoc = view.findViewById(R.id.tvLoiLoc);
        tvTongDoanhSo = view.findViewById(R.id.tvTongDoanhSo);
        tvTongDon = view.findViewById(R.id.tvTongDon);
        tvTongSanPham = view.findViewById(R.id.tvTongSanPham);
        tvTrongTop = view.findViewById(R.id.tvTrongTop);
        bdVung = view.findViewById(R.id.bdVung);
        bdHangSao = view.findViewById(R.id.bdHangSao);
        bdHangSao.datTongVang(true);
        dsTop = view.findViewById(R.id.dsTop);
        khung = new StatePanel(view, viewModel::taiLai);

        btnTu.setOnClickListener(v -> chonNgay(true));
        btnDen.setOnClickListener(v -> chonNgay(false));
        view.findViewById(R.id.btnXoaLoc).setOnClickListener(v -> {
            tu = null;
            den = null;
            apDungLoc();
        });

        viewModel.getBaoCao().observe(getViewLifecycleOwner(), this::hienThi);
        ScreenLayout.quanSatChung(this, viewModel);
        apDungLoc();
    }

    @Override
    public void onDestroyView() {
        if (animDoanhSo != null) animDoanhSo.cancel();
        super.onDestroyView();
    }

    @Override
    public void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);
        outState.putString(KEY_TU, tu);
        outState.putString(KEY_DEN, den);
    }

    private void chonNgay(boolean laTu) {
        String daChon = laTu ? tu : den;
        Calendar c = Calendar.getInstance();
        if (daChon != null) {
            c.set(Integer.parseInt(daChon.substring(0, 4)), Integer.parseInt(daChon.substring(5, 7)) - 1,
                    Integer.parseInt(daChon.substring(8, 10)));
        }
        new DatePickerDialog(requireContext(), (p, nam, thang0, ngay) -> {
            String iso = Formatting.ngayIso(nam, thang0 + 1, ngay);
            if (laTu) tu = iso;
            else den = iso;
            apDungLoc();
        }, c.get(Calendar.YEAR), c.get(Calendar.MONTH), c.get(Calendar.DAY_OF_MONTH)).show();
    }

    /** Kiểm tra "từ ngày" không sau "đến ngày" trước khi gọi API (backend cũng trả 400). */
    private void apDungLoc() {
        btnTu.setText(tu == null ? getString(R.string.tu_ngay_trong) : getString(R.string.tu_ngay_x, Formatting.ngay(tu)));
        btnDen.setText(den == null ? getString(R.string.den_ngay_trong) : getString(R.string.den_ngay_x, Formatting.ngay(den)));
        boolean sai = tu != null && den != null && FormValidation.sauNgay(tu, den);
        tvLoiLoc.setVisibility(sai ? View.VISIBLE : View.GONE);
        if (sai) return;
        viewModel.tai(tu, den);
    }

    private void hienThi(UiState<SalesReport> tt) {
        khung.hien(tt, noiDung, false);
        if (tt.loai != UiState.Loai.THANH_CONG) return;
        SalesReport bc = tt.duLieu;

        if (animDoanhSo != null) animDoanhSo.cancel();
        animDoanhSo = Animations.chaySoTien(tvTongDoanhSo, bc.tong.doanhSo);
        tvTongDon.setText(getString(R.string.so_don_ngan, bc.tong.soDon));
        tvTongSanPham.setText(getString(R.string.so_sp_da_ban_ngan, bc.tong.soLuong));

        List<String> nhanVung = new ArrayList<>();
        long[] dsVung = new long[bc.theoVung.size()];
        for (int i = 0; i < bc.theoVung.size(); i++) {
            nhanVung.add(bc.theoVung.get(i).tenVung);
            dsVung[i] = bc.theoVung.get(i).doanhSo;
        }
        bdVung.datDuLieu(nhanVung, dsVung);
        bdVung.setContentDescription(moTaBieuDo(nhanVung, dsVung));

        List<String> nhanSao = new ArrayList<>();
        long[] dsSao = new long[bc.theoHangSao.size()];
        for (int i = 0; i < bc.theoHangSao.size(); i++) {
            nhanSao.add(getString(R.string.hang_sao_ngan, bc.theoHangSao.get(i).hangSao));
            dsSao[i] = bc.theoHangSao.get(i).doanhSo;
        }
        bdHangSao.datDuLieu(nhanSao, dsSao);
        bdHangSao.setContentDescription(moTaBieuDo(nhanSao, dsSao));

        veTop(bc.nhaCungCapBanChay);
    }

    /** Biểu đồ tự vẽ không có chữ cho trình đọc màn hình, nên ghép mô tả từ số liệu. */
    private String moTaBieuDo(List<String> nhan, long[] giaTri) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < nhan.size(); i++) {
            if (i > 0) sb.append("; ");
            sb.append(nhan.get(i)).append(": ").append(Formatting.tien(giaTri[i]));
        }
        return sb.toString();
    }

    private void veTop(List<SalesReport.NhaCungCapBanChay> top) {
        dsTop.removeAllViews();
        boolean co = top != null && !top.isEmpty();
        tvTrongTop.setVisibility(co ? View.GONE : View.VISIBLE);
        if (!co) return;
        LayoutInflater inf = getLayoutInflater();
        for (int i = 0; i < top.size(); i++) {
            SalesReport.NhaCungCapBanChay n = top.get(i);
            View v = inf.inflate(R.layout.item_top_supplier, dsTop, false);
            TextView tvHang = v.findViewById(R.id.tvHang);
            tvHang.setText(String.valueOf(i + 1));
            int mauHang = i == 0 ? R.color.huy_chuong_vang
                    : (i == 1 ? R.color.huy_chuong_bac
                    : (i == 2 ? R.color.huy_chuong_dong : R.color.xanh_ocop));
            androidx.core.view.ViewCompat.setBackgroundTintList(tvHang,
                    android.content.res.ColorStateList.valueOf(
                            androidx.core.content.ContextCompat.getColor(requireContext(), mauHang)));
            ((TextView) v.findViewById(R.id.tvTenNcc)).setText(n.ten);
            ((TextView) v.findViewById(R.id.tvVungNcc)).setText(getString(R.string.vung_don_so_luong,
                    n.tenVung, n.soDon, n.soLuong));
            ((TextView) v.findViewById(R.id.tvDoanhSoNcc)).setText(Formatting.tien(n.doanhSo));
            dsTop.addView(v);
        }
    }
}
