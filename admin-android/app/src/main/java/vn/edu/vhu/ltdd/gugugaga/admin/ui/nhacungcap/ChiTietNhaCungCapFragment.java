package vn.edu.vhu.ltdd.gugugaga.admin.ui.nhacungcap;

import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;
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
import androidx.core.content.ContextCompat;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.data.TokenStore;
import vn.edu.vhu.ltdd.gugugaga.admin.model.NhaCungCap;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.MainActivity;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.KhungTrangThai;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.ManHinh;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.NhanTrangThai;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.TrangThai;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.XacNhanDialog;
import vn.edu.vhu.ltdd.gugugaga.admin.util.DinhDang;
import vn.edu.vhu.ltdd.gugugaga.admin.util.PhanQuyen;
import vn.edu.vhu.ltdd.gugugaga.admin.util.QuyTacTrangThai;

/**
 * Chi tiết hồ sơ nhà cung cấp: ảnh cơ sở, chứng nhận, cờ "tự gửi từ app Client", lý do từ chối.
 * QUAN_TRI thấy nút Duyệt/Từ chối (C.1 #2); NHAN_VIEN chỉ xem. Backend vẫn chặn bằng 403.
 */
public class ChiTietNhaCungCapFragment extends Fragment {
    private static final String ARG_ID = "id";
    private static final String YC_DUYET = "duyet_ncc";
    private static final String YC_TU_CHOI = "tu_choi_ncc";

    private ChiTietNhaCungCapViewModel viewModel;
    private KhungTrangThai khung;
    private View noiDung, hangNut;
    private ImageView ivAnhCoSo;
    private TextView tvTen, tvTrangThai, tvTuGui, tvLyDo, tvDaiDien, tvSdt, tvDiaChi, tvVung, tvTaoLuc, tvDuyet;
    private TextView tvChiXem, tvKhongCoChungNhan;
    private LinearLayout dsChungNhan;
    private Button btnDuyet, btnTuChoi;
    private boolean quanTri;

    public static ChiTietNhaCungCapFragment newInstance(int id) {
        ChiTietNhaCungCapFragment f = new ChiTietNhaCungCapFragment();
        Bundle a = new Bundle();
        a.putInt(ARG_ID, id);
        f.setArguments(a);
        return f;
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_chi_tiet_nha_cung_cap, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        ((MainActivity) requireActivity()).datTieuDe(R.string.tieu_de_chi_tiet_ncc);
        quanTri = PhanQuyen.laQuanTri(TokenStore.layVaiTro(requireContext()));
        viewModel = new ViewModelProvider(this).get(ChiTietNhaCungCapViewModel.class);
        anhXa(view);
        khung = new KhungTrangThai(view, viewModel::taiLai);

        viewModel.getChiTiet().observe(getViewLifecycleOwner(), this::hienThi);
        viewModel.getDangGui().observe(getViewLifecycleOwner(), dangGui -> capNhatNut());
        viewModel.getDaThayDoi().observe(getViewLifecycleOwner(), sk -> {
            if (sk.layNeuChuaXuLy() != null) {
                getParentFragmentManager().setFragmentResult(NhaCungCapFragment.KET_QUA_CAP_NHAT, new Bundle());
            }
        });
        ManHinh.quanSatChung(this, viewModel);

        getChildFragmentManager().setFragmentResultListener(YC_DUYET, getViewLifecycleOwner(),
                (k, b) -> viewModel.duyet(tenHienTai()));
        getChildFragmentManager().setFragmentResultListener(YC_TU_CHOI, getViewLifecycleOwner(),
                (k, b) -> viewModel.tuChoi(tenHienTai(), b.getString(XacNhanDialog.KEY_NOI_DUNG)));

        btnDuyet.setOnClickListener(v -> XacNhanDialog.newInstance(YC_DUYET,
                getString(R.string.duyet_tieu_de, tenHienTai()), getString(R.string.xac_nhan_duyet_ncc),
                getString(R.string.nut_duyet), XacNhanDialog.KHONG_NHAP, null, null, null)
                .show(getChildFragmentManager(), "duyet_ncc"));
        btnTuChoi.setOnClickListener(v -> XacNhanDialog.newInstance(YC_TU_CHOI,
                getString(R.string.tu_choi_tieu_de, tenHienTai()), null,
                getString(R.string.nut_tu_choi), XacNhanDialog.NHAP_BAT_BUOC,
                getString(R.string.hint_ly_do), getString(R.string.loi_ly_do_trong), null)
                .show(getChildFragmentManager(), "tu_choi_ncc"));
        tvSdt.setOnClickListener(v -> goiDien(tvSdt.getText().toString()));

        viewModel.batDau(requireArguments().getInt(ARG_ID));
    }

    private void anhXa(View v) {
        noiDung = v.findViewById(R.id.noiDung);
        hangNut = v.findViewById(R.id.hangNut);
        ivAnhCoSo = v.findViewById(R.id.ivAnhCoSo);
        tvTen = v.findViewById(R.id.tvTen);
        tvTrangThai = v.findViewById(R.id.tvTrangThai);
        tvTuGui = v.findViewById(R.id.tvTuGui);
        tvLyDo = v.findViewById(R.id.tvLyDo);
        tvDaiDien = v.findViewById(R.id.tvDaiDien);
        tvSdt = v.findViewById(R.id.tvSdt);
        tvDiaChi = v.findViewById(R.id.tvDiaChi);
        tvVung = v.findViewById(R.id.tvVung);
        tvTaoLuc = v.findViewById(R.id.tvTaoLuc);
        tvDuyet = v.findViewById(R.id.tvDuyet);
        tvChiXem = v.findViewById(R.id.tvChiXem);
        tvKhongCoChungNhan = v.findViewById(R.id.tvKhongCoChungNhan);
        dsChungNhan = v.findViewById(R.id.dsChungNhan);
        btnDuyet = v.findViewById(R.id.btnDuyet);
        btnTuChoi = v.findViewById(R.id.btnTuChoi);
    }

    private String tenHienTai() {
        TrangThai<NhaCungCap> tt = viewModel.getChiTiet().getValue();
        return tt != null && tt.duLieu != null ? tt.duLieu.ten : "";
    }

    private void hienThi(TrangThai<NhaCungCap> tt) {
        khung.hien(tt, noiDung, false);
        if (tt.loai != TrangThai.Loai.THANH_CONG) return;
        NhaCungCap n = tt.duLieu;

        ManHinh.hienAnh(this, ivAnhCoSo, n.anhCoSoUrl);
        tvTen.setText(n.ten);
        NhanTrangThai.gan(tvTrangThai, n.trangThaiDuyet);
        tvTuGui.setVisibility(n.tuGui ? View.VISIBLE : View.GONE);
        boolean coLyDo = n.lyDoTuChoi != null && !n.lyDoTuChoi.isEmpty();
        tvLyDo.setVisibility(coLyDo ? View.VISIBLE : View.GONE);
        tvLyDo.setText(getString(R.string.ly_do_tu_choi, n.lyDoTuChoi));
        tvDaiDien.setText(getString(R.string.nguoi_dai_dien, n.nguoiDaiDien));
        tvSdt.setText(n.soDienThoai);
        tvDiaChi.setText(n.diaChi);
        tvVung.setText(getString(R.string.vung_nguyen_lieu, n.tenVung));
        tvTaoLuc.setText(getString(R.string.gui_luc, DinhDang.thoiDiem(n.taoLuc)));
        tvDuyet.setVisibility(n.duyetLuc == null ? View.GONE : View.VISIBLE);
        tvDuyet.setText(getString(R.string.xu_ly_boi, n.nguoiDuyet == null ? "" : n.nguoiDuyet,
                DinhDang.thoiDiem(n.duyetLuc)));

        veChungNhan(n);
        capNhatNut();
    }

    private void veChungNhan(NhaCungCap n) {
        dsChungNhan.removeAllViews();
        boolean co = n.chungNhan != null && !n.chungNhan.isEmpty();
        tvKhongCoChungNhan.setVisibility(co ? View.GONE : View.VISIBLE);
        if (!co) return;
        LayoutInflater inf = getLayoutInflater();
        for (NhaCungCap.ChungNhan c : n.chungNhan) {
            View v = inf.inflate(R.layout.item_chung_nhan, dsChungNhan, false);
            ((TextView) v.findViewById(R.id.tvLoaiChungNhan)).setText(getString(R.string.loai_so_hieu, c.loai, c.soHieu));
            ((TextView) v.findViewById(R.id.tvHanChungNhan)).setText(c.ngayHetHan == null
                    ? getString(R.string.cap_ngay, DinhDang.ngay(c.ngayCap))
                    : getString(R.string.cap_ngay_het_han, DinhDang.ngay(c.ngayCap), DinhDang.ngay(c.ngayHetHan)));
            TextView tvHieuLuc = v.findViewById(R.id.tvHieuLuc);
            tvHieuLuc.setText(c.conHieuLuc ? R.string.con_hieu_luc : R.string.het_hieu_luc);
            tvHieuLuc.setTextColor(ContextCompat.getColor(requireContext(),
                    c.conHieuLuc ? R.color.xanh_da_duyet : R.color.do_tu_choi));
            ManHinh.hienAnh(this, v.findViewById(R.id.ivAnhChungNhan), c.anhUrl);
            dsChungNhan.addView(v);
        }
    }

    /** Chỉ QUAN_TRI thấy nút; nút nào hiện tùy trạng thái hiện tại của hồ sơ. */
    private void capNhatNut() {
        TrangThai<NhaCungCap> tt = viewModel.getChiTiet().getValue();
        if (tt == null || tt.duLieu == null) return;
        String trangThai = tt.duLieu.trangThaiDuyet;
        boolean dangGui = Boolean.TRUE.equals(viewModel.getDangGui().getValue());
        hangNut.setVisibility(quanTri ? View.VISIBLE : View.GONE);
        tvChiXem.setVisibility(quanTri ? View.GONE : View.VISIBLE);
        btnDuyet.setVisibility(QuyTacTrangThai.coTheDuyetHoSo(trangThai) ? View.VISIBLE : View.GONE);
        btnTuChoi.setVisibility(QuyTacTrangThai.coTheTuChoiHoSo(trangThai) ? View.VISIBLE : View.GONE);
        btnTuChoi.setText(QuyTacTrangThai.HS_DA_DUYET.equals(trangThai) ? R.string.nut_thu_hoi : R.string.nut_tu_choi);
        btnDuyet.setEnabled(!dangGui);
        btnTuChoi.setEnabled(!dangGui);
    }

    private void goiDien(String sdt) {
        if (sdt == null || sdt.isEmpty()) return;
        try {
            startActivity(new Intent(Intent.ACTION_DIAL, Uri.parse("tel:" + sdt)));
        } catch (ActivityNotFoundException e) {
            ManHinh.baoSnackbar(this, getString(R.string.loi_khong_co_ung_dung));
        }
    }
}
