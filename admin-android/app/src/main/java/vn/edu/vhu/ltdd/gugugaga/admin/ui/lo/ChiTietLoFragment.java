package vn.edu.vhu.ltdd.gugugaga.admin.ui.lo;

import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.graphics.Bitmap;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.model.BuocTruyXuat;
import vn.edu.vhu.ltdd.gugugaga.admin.model.LoSanXuat;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauThemBuoc;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.MainActivity;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.KhungTrangThai;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.ManHinh;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.NhanTrangThai;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.TrangThai;
import vn.edu.vhu.ltdd.gugugaga.admin.util.DinhDang;

/**
 * Chi tiết lô: ảnh QR vẽ từ duongDanTruyXuat để in lên bao bì, thông tin lô, ảnh hiện trường và
 * các bước truy xuất. Nút "Thêm bước" mở ThemBuocDialog; nút "Chia sẻ" gửi đường dẫn (Lab A5).
 */
public class ChiTietLoFragment extends Fragment {
    private static final String ARG_ID = "id";

    private ChiTietLoViewModel viewModel;
    private KhungTrangThai khung;
    private View noiDung;
    private ImageView ivQr, ivAnhHienTruong;
    private TextView tvMa, tvDuongDan, tvTenSanPham, tvTrangThaiSanPham, tvNgay, tvSoLuong, tvVung,
            tvNguoiSanXuat, tvGhiChu, tvChuaCoBuoc;
    private LinearLayout dsBuoc;
    private Button btnThemBuoc;

    public static ChiTietLoFragment newInstance(int id) {
        ChiTietLoFragment f = new ChiTietLoFragment();
        Bundle a = new Bundle();
        a.putInt(ARG_ID, id);
        f.setArguments(a);
        return f;
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_chi_tiet_lo, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        ((MainActivity) requireActivity()).datTieuDe(R.string.tieu_de_chi_tiet_lo);
        viewModel = new ViewModelProvider(this).get(ChiTietLoViewModel.class);
        anhXa(view);
        khung = new KhungTrangThai(view, viewModel::taiLai);

        viewModel.getChiTiet().observe(getViewLifecycleOwner(), this::hienThi);
        viewModel.getDangGui().observe(getViewLifecycleOwner(), dangGui ->
                btnThemBuoc.setEnabled(!Boolean.TRUE.equals(dangGui)));
        viewModel.getDaThayDoi().observe(getViewLifecycleOwner(), sk -> {
            if (sk.layNeuChuaXuLy() != null) {
                getParentFragmentManager().setFragmentResult(LoFragment.KET_QUA_CAP_NHAT, new Bundle());
            }
        });
        ManHinh.quanSatChung(this, viewModel);

        getChildFragmentManager().setFragmentResultListener(ThemBuocDialog.REQUEST_KEY, getViewLifecycleOwner(),
                (k, b) -> viewModel.themBuoc(new YeuCauThemBuoc(b.getString(ThemBuocDialog.KEY_TEN_BUOC),
                        b.getString(ThemBuocDialog.KEY_THOI_DIEM), b.getString(ThemBuocDialog.KEY_MO_TA),
                        b.getString(ThemBuocDialog.KEY_ANH_URL))));
        btnThemBuoc.setOnClickListener(v -> new ThemBuocDialog().show(getChildFragmentManager(), "them_buoc"));
        view.findViewById(R.id.btnChiaSe).setOnClickListener(v -> chiaSe());

        viewModel.batDau(requireArguments().getInt(ARG_ID));
    }

    private void anhXa(View v) {
        noiDung = v.findViewById(R.id.noiDung);
        ivQr = v.findViewById(R.id.ivQr);
        ivAnhHienTruong = v.findViewById(R.id.ivAnhHienTruong);
        tvMa = v.findViewById(R.id.tvMaTruyXuat);
        tvDuongDan = v.findViewById(R.id.tvDuongDan);
        tvTenSanPham = v.findViewById(R.id.tvTenSanPham);
        tvTrangThaiSanPham = v.findViewById(R.id.tvTrangThaiSanPham);
        tvNgay = v.findViewById(R.id.tvNgay);
        tvSoLuong = v.findViewById(R.id.tvSoLuong);
        tvVung = v.findViewById(R.id.tvVung);
        tvNguoiSanXuat = v.findViewById(R.id.tvNguoiSanXuat);
        tvGhiChu = v.findViewById(R.id.tvGhiChu);
        tvChuaCoBuoc = v.findViewById(R.id.tvChuaCoBuoc);
        dsBuoc = v.findViewById(R.id.dsBuoc);
        btnThemBuoc = v.findViewById(R.id.btnThemBuoc);
    }

    private void hienThi(TrangThai<LoSanXuat> tt) {
        khung.hien(tt, noiDung, false);
        if (tt.loai != TrangThai.Loai.THANH_CONG) return;
        LoSanXuat lo = tt.duLieu;

        // Vẽ QR theo kích thước thật của ImageView (dp -> px) để ảnh nét.
        Bitmap qr = MaQr.tao(lo.duongDanTruyXuat, getResources().getDimensionPixelSize(R.dimen.kich_thuoc_qr));
        ivQr.setImageBitmap(qr);
        ivQr.setContentDescription(getString(R.string.mo_ta_qr, lo.maTruyXuat));
        tvMa.setText(lo.maTruyXuat);
        tvDuongDan.setText(lo.duongDanTruyXuat);

        tvTenSanPham.setText(lo.tenSanPham);
        NhanTrangThai.gan(tvTrangThaiSanPham, lo.trangThaiSanPham);
        tvNgay.setText(getString(R.string.nsx_hsd, DinhDang.ngay(lo.ngaySanXuat), DinhDang.ngay(lo.hanSuDung)));
        tvSoLuong.setText(getString(R.string.so_luong_con, lo.soLuongCon, lo.soLuong));
        tvVung.setText(getString(R.string.vung_nguyen_lieu, lo.tenVung));
        tvNguoiSanXuat.setText(getString(R.string.nguoi_san_xuat, lo.nguoiSanXuat));
        boolean coGhiChu = lo.ghiChu != null && !lo.ghiChu.isEmpty();
        tvGhiChu.setVisibility(coGhiChu ? View.VISIBLE : View.GONE);
        tvGhiChu.setText(getString(R.string.ghi_chu_lo, lo.ghiChu));
        ManHinh.hienAnh(this, ivAnhHienTruong, lo.anhHienTruongUrl);

        veBuoc(lo);
    }

    private void veBuoc(LoSanXuat lo) {
        dsBuoc.removeAllViews();
        boolean co = lo.cacBuoc != null && !lo.cacBuoc.isEmpty();
        tvChuaCoBuoc.setVisibility(co ? View.GONE : View.VISIBLE);
        if (!co) return;
        LayoutInflater inf = getLayoutInflater();
        for (BuocTruyXuat b : lo.cacBuoc) {
            View v = inf.inflate(R.layout.item_buoc, dsBuoc, false);
            ((TextView) v.findViewById(R.id.tvThuTu)).setText(String.valueOf(b.thuTu));
            ((TextView) v.findViewById(R.id.tvTenBuoc)).setText(b.tenBuoc);
            ((TextView) v.findViewById(R.id.tvThoiDiemBuoc)).setText(DinhDang.thoiDiem(b.thoiDiem));
            TextView tvMoTa = v.findViewById(R.id.tvMoTaBuoc);
            tvMoTa.setVisibility(b.moTa == null ? View.GONE : View.VISIBLE);
            tvMoTa.setText(b.moTa);
            dsBuoc.addView(v);
        }
    }

    /** Intent ngầm định ACTION_SEND bọc createChooser và try-catch (Lab A5). */
    private void chiaSe() {
        TrangThai<LoSanXuat> tt = viewModel.getChiTiet().getValue();
        if (tt == null || tt.duLieu == null) return;
        Intent i = new Intent(Intent.ACTION_SEND);
        i.setType("text/plain");
        i.putExtra(Intent.EXTRA_TEXT, getString(R.string.noi_dung_chia_se_lo,
                tt.duLieu.tenSanPham, tt.duLieu.duongDanTruyXuat));
        try {
            startActivity(Intent.createChooser(i, getString(R.string.nut_chia_se)));
        } catch (ActivityNotFoundException e) {
            ManHinh.baoSnackbar(this, getString(R.string.loi_khong_co_ung_dung));
        }
    }
}
