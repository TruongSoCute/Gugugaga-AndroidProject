package vn.edu.vhu.ltdd.gugugaga.admin.ui.donhang;

import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;

import java.util.List;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.model.DonHang;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.MainActivity;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.KhungTrangThai;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.ManHinh;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.NhanTrangThai;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.NutThaoTac;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.TrangThai;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.XacNhanDialog;
import vn.edu.vhu.ltdd.gugugaga.admin.util.DinhDang;
import vn.edu.vhu.ltdd.gugugaga.admin.util.QuyTacTrangThai;

/**
 * Chi tiết đơn: người nhận, tổng tiền, các dòng hàng kèm mã truy xuất của lô đã giao, lịch sử
 * trạng thái và các nút chuyển trạng thái hợp lệ cho nhân sự. Mỗi thao tác đều qua hộp thoại
 * xác nhận; hủy đơn bắt buộc ghi lý do.
 */
public class ChiTietDonHangFragment extends Fragment {
    private static final String ARG_ID = "id";
    private static final String YC_DOI_TRANG_THAI = "doi_trang_thai_don";
    private static final String KEY_TRANG_THAI_MOI = "trang_thai_moi";

    private ChiTietDonHangViewModel viewModel;
    private KhungTrangThai khung;
    private View noiDung;
    private TextView tvMaDon, tvTrangThai, tvTaoLuc, tvHinhThuc, tvTienHang, tvTongTien;
    private TextView tvNguoiNhan, tvSdt, tvDiaChi, tvKhach, tvGhiChu, tvKhongConBuoc;
    private LinearLayout dsDong, dsLichSu, hangNut;

    /** Truyền id qua arguments, không qua constructor (Lab A8). */
    public static ChiTietDonHangFragment newInstance(int id) {
        ChiTietDonHangFragment f = new ChiTietDonHangFragment();
        Bundle a = new Bundle();
        a.putInt(ARG_ID, id);
        f.setArguments(a);
        return f;
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_chi_tiet_don_hang, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        ((MainActivity) requireActivity()).datTieuDe(R.string.tieu_de_chi_tiet_don);
        viewModel = new ViewModelProvider(this).get(ChiTietDonHangViewModel.class);
        anhXa(view);
        khung = new KhungTrangThai(view, viewModel::taiLai);

        viewModel.getChiTiet().observe(getViewLifecycleOwner(), this::hienThi);
        viewModel.getDangGui().observe(getViewLifecycleOwner(), dangGui -> veNut());
        viewModel.getDaThayDoi().observe(getViewLifecycleOwner(), sk -> {
            if (sk.layNeuChuaXuLy() != null) {
                getParentFragmentManager().setFragmentResult(DonHangFragment.KET_QUA_CAP_NHAT, new Bundle());
            }
        });
        ManHinh.quanSatChung(this, viewModel);

        getChildFragmentManager().setFragmentResultListener(YC_DOI_TRANG_THAI, getViewLifecycleOwner(),
                (k, b) -> viewModel.doiTrangThai(b.getString(KEY_TRANG_THAI_MOI),
                        b.getString(XacNhanDialog.KEY_NOI_DUNG)));

        tvSdt.setOnClickListener(v -> goiDien(tvSdt.getText().toString()));
        viewModel.batDau(requireArguments().getInt(ARG_ID));
    }

    private void anhXa(View v) {
        noiDung = v.findViewById(R.id.noiDung);
        tvMaDon = v.findViewById(R.id.tvMaDon);
        tvTrangThai = v.findViewById(R.id.tvTrangThai);
        tvTaoLuc = v.findViewById(R.id.tvTaoLuc);
        tvHinhThuc = v.findViewById(R.id.tvHinhThuc);
        tvTienHang = v.findViewById(R.id.tvTienHang);
        tvTongTien = v.findViewById(R.id.tvTongTien);
        tvNguoiNhan = v.findViewById(R.id.tvNguoiNhan);
        tvSdt = v.findViewById(R.id.tvSdt);
        tvDiaChi = v.findViewById(R.id.tvDiaChi);
        tvKhach = v.findViewById(R.id.tvKhach);
        tvGhiChu = v.findViewById(R.id.tvGhiChu);
        tvKhongConBuoc = v.findViewById(R.id.tvKhongConBuoc);
        dsDong = v.findViewById(R.id.dsDong);
        dsLichSu = v.findViewById(R.id.dsLichSu);
        hangNut = v.findViewById(R.id.hangNut);
    }

    private void hienThi(TrangThai<DonHang> tt) {
        khung.hien(tt, noiDung, false);
        if (tt.loai != TrangThai.Loai.THANH_CONG) return;
        DonHang d = tt.duLieu;

        tvMaDon.setText(getString(R.string.ma_don, d.id));
        NhanTrangThai.gan(tvTrangThai, d.trangThai);
        tvTaoLuc.setText(getString(R.string.dat_luc, DinhDang.thoiDiem(d.taoLuc)));
        tvHinhThuc.setText(getString(R.string.hinh_thuc_va_phi,
                getString(NhanTrangThai.hinhThucGiao(d.hinhThucGiao)), DinhDang.tien(d.phiGiao)));
        tvTienHang.setText(getString(R.string.tien_hang, DinhDang.tien(d.tienHang)));
        tvTongTien.setText(getString(R.string.tong_tien, DinhDang.tien(d.tongTien)));

        tvNguoiNhan.setText(d.tenNguoiNhan);
        tvSdt.setText(d.sdtNguoiNhan);
        tvDiaChi.setText(d.diaChiGiao);
        tvKhach.setText(getString(R.string.khach_dat, d.tenKhach, d.emailKhach));
        tvGhiChu.setVisibility(d.ghiChu == null ? View.GONE : View.VISIBLE);
        tvGhiChu.setText(getString(R.string.ghi_chu_khach, d.ghiChu));

        veDongHang(d.chiTiet);
        veLichSu(d.lichSu);
        veNut();
    }

    /** Danh sách ngắn trong màn hình cuộn: inflate từng dòng vào LinearLayout. */
    private void veDongHang(List<DonHang.DongDon> dong) {
        dsDong.removeAllViews();
        if (dong == null) return;
        LayoutInflater inf = getLayoutInflater();
        for (DonHang.DongDon x : dong) {
            View v = inf.inflate(R.layout.item_dong_don, dsDong, false);
            ((TextView) v.findViewById(R.id.tvTenSanPham)).setText(
                    getString(R.string.so_luong_x_ten, x.soLuong, x.donViTinh, x.tenSanPham));
            ((TextView) v.findViewById(R.id.tvGiaDong)).setText(
                    getString(R.string.don_gia_thanh_tien, DinhDang.tien(x.donGia), DinhDang.tien(x.thanhTien)));
            ((TextView) v.findViewById(R.id.tvLoDong)).setText(getString(R.string.lo_da_giao,
                    x.maTruyXuat, DinhDang.ngay(x.ngaySanXuat), x.vungNguyenLieu));
            dsDong.addView(v);
        }
    }

    private void veLichSu(List<DonHang.LichSuDon> lichSu) {
        dsLichSu.removeAllViews();
        if (lichSu == null) return;
        LayoutInflater inf = getLayoutInflater();
        for (DonHang.LichSuDon x : lichSu) {
            View v = inf.inflate(R.layout.item_lich_su, dsLichSu, false);
            TextView tvTt = v.findViewById(R.id.tvTrangThaiLichSu);
            tvTt.setText(NhanTrangThai.chu(x.trangThai));
            tvTt.setTextColor(androidx.core.content.ContextCompat.getColor(requireContext(),
                    NhanTrangThai.mauChu(x.trangThai)));
            ((TextView) v.findViewById(R.id.tvThoiDiemLichSu)).setText(getString(R.string.thoi_diem_nguoi,
                    DinhDang.thoiDiem(x.thoiDiem), x.nguoiThucHien == null ? "" : x.nguoiThucHien));
            TextView tvGc = v.findViewById(R.id.tvGhiChuLichSu);
            tvGc.setVisibility(x.ghiChu == null ? View.GONE : View.VISIBLE);
            tvGc.setText(x.ghiChu);
            dsLichSu.addView(v);
        }
    }

    /** Chỉ hiện bước hợp lệ cho nhân sự; khóa nút trong lúc đang gửi. */
    private void veNut() {
        TrangThai<DonHang> tt = viewModel.getChiTiet().getValue();
        if (tt == null || tt.duLieu == null) return;
        List<String> buoc = QuyTacTrangThai.buocTiepDonHang(tt.duLieu.trangThai);
        boolean dangGui = Boolean.TRUE.equals(viewModel.getDangGui().getValue());
        NutThaoTac.ve(hangNut, buoc, dangGui, this::xacNhan);
        tvKhongConBuoc.setVisibility(buoc.isEmpty() ? View.VISIBLE : View.GONE);
    }

    /** Hộp thoại xác nhận trước khi chuyển (C.1 #6); hủy thì bắt buộc lý do. */
    private void xacNhan(String trangThaiMoi) {
        TrangThai<DonHang> tt = viewModel.getChiTiet().getValue();
        if (tt == null || tt.duLieu == null) return;
        boolean huy = QuyTacTrangThai.donCanGhiChu(trangThaiMoi);
        Bundle kem = new Bundle();
        kem.putString(KEY_TRANG_THAI_MOI, trangThaiMoi);
        XacNhanDialog.newInstance(YC_DOI_TRANG_THAI,
                getString(NhanTrangThai.nut(trangThaiMoi)),
                getString(R.string.xac_nhan_doi_trang_thai_don, tt.duLieu.id,
                        getString(NhanTrangThai.chu(tt.duLieu.trangThai)), getString(NhanTrangThai.chu(trangThaiMoi))),
                getString(R.string.nut_dong_y),
                huy ? XacNhanDialog.NHAP_BAT_BUOC : XacNhanDialog.NHAP_TUY_CHON,
                getString(huy ? R.string.hint_ly_do_huy : R.string.hint_ghi_chu),
                getString(R.string.loi_ly_do_huy_trong),
                kem).show(getChildFragmentManager(), "xac_nhan_don");
    }

    /** Intent ngầm định ACTION_DIAL: không cần quyền gọi điện (Lab A5). */
    private void goiDien(String sdt) {
        if (sdt == null || sdt.isEmpty()) return;
        try {
            startActivity(new Intent(Intent.ACTION_DIAL, Uri.parse("tel:" + sdt)));
        } catch (ActivityNotFoundException e) {
            ManHinh.baoSnackbar(this, getString(R.string.loi_khong_co_ung_dung));
        }
    }
}
