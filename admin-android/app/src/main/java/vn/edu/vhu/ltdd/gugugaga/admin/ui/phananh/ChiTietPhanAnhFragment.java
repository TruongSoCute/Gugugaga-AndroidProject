package vn.edu.vhu.ltdd.gugugaga.admin.ui.phananh;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;

import java.util.List;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.model.PhanAnh;
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
 * Chi tiết phản ánh và xử lý: chỉ đi tới MOI → DANG_XU_LY → DA_XU_LY/BAC_BO. Kết thúc (đã xử lý
 * hoặc bác bỏ) bắt buộc ghi kết quả; backend vẫn kiểm tra lại (400/409).
 */
public class ChiTietPhanAnhFragment extends Fragment {
    private static final String ARG_ID = "id";
    private static final String YC_XU_LY = "xu_ly_phan_anh";
    private static final String KEY_TRANG_THAI_MOI = "trang_thai_moi";

    private ChiTietPhanAnhViewModel viewModel;
    private KhungTrangThai khung;
    private View noiDung;
    private ImageView ivAnh;
    private TextView tvLoai, tvTrangThai, tvSanPham, tvNhaCungCap, tvLo, tvNoiDung, tvNguoiBao, tvKetQua,
            tvKhongConBuoc;
    private LinearLayout hangNut;

    public static ChiTietPhanAnhFragment newInstance(int id) {
        ChiTietPhanAnhFragment f = new ChiTietPhanAnhFragment();
        Bundle a = new Bundle();
        a.putInt(ARG_ID, id);
        f.setArguments(a);
        return f;
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_chi_tiet_phan_anh, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        ((MainActivity) requireActivity()).datTieuDe(R.string.tieu_de_chi_tiet_phan_anh);
        viewModel = new ViewModelProvider(this).get(ChiTietPhanAnhViewModel.class);
        noiDung = view.findViewById(R.id.noiDung);
        ivAnh = view.findViewById(R.id.ivAnh);
        tvLoai = view.findViewById(R.id.tvLoai);
        tvTrangThai = view.findViewById(R.id.tvTrangThai);
        tvSanPham = view.findViewById(R.id.tvSanPham);
        tvNhaCungCap = view.findViewById(R.id.tvNhaCungCap);
        tvLo = view.findViewById(R.id.tvLo);
        tvNoiDung = view.findViewById(R.id.tvNoiDung);
        tvNguoiBao = view.findViewById(R.id.tvNguoiBao);
        tvKetQua = view.findViewById(R.id.tvKetQua);
        tvKhongConBuoc = view.findViewById(R.id.tvKhongConBuoc);
        hangNut = view.findViewById(R.id.hangNut);
        khung = new KhungTrangThai(view, viewModel::taiLai);

        viewModel.getChiTiet().observe(getViewLifecycleOwner(), this::hienThi);
        viewModel.getDangGui().observe(getViewLifecycleOwner(), dangGui -> veNut());
        viewModel.getDaThayDoi().observe(getViewLifecycleOwner(), sk -> {
            if (sk.layNeuChuaXuLy() != null) {
                getParentFragmentManager().setFragmentResult(PhanAnhFragment.KET_QUA_CAP_NHAT, new Bundle());
            }
        });
        ManHinh.quanSatChung(this, viewModel);
        getChildFragmentManager().setFragmentResultListener(YC_XU_LY, getViewLifecycleOwner(),
                (k, b) -> viewModel.xuLy(b.getString(KEY_TRANG_THAI_MOI), b.getString(XacNhanDialog.KEY_NOI_DUNG)));

        viewModel.batDau(requireArguments().getInt(ARG_ID));
    }

    private void hienThi(TrangThai<PhanAnh> tt) {
        khung.hien(tt, noiDung, false);
        if (tt.loai != TrangThai.Loai.THANH_CONG) return;
        PhanAnh p = tt.duLieu;

        tvLoai.setText(NhanTrangThai.loaiPhanAnh(p.loai));
        NhanTrangThai.gan(tvTrangThai, p.trangThai);
        tvSanPham.setText(getString(R.string.san_pham_x, p.tenSanPham));
        tvNhaCungCap.setText(getString(R.string.nha_cung_cap_x, p.tenNhaCungCap));
        tvLo.setText(p.maTruyXuat == null ? getString(R.string.khong_ghi_ma_lo)
                : getString(R.string.lo_x, p.maTruyXuat));
        tvNoiDung.setText(p.noiDung);
        tvNguoiBao.setText(getString(R.string.nguoi_bao_chi_tiet, p.tenNguoiBao,
                p.emailNguoiBao == null ? "" : p.emailNguoiBao, DinhDang.thoiDiem(p.taoLuc)));
        ManHinh.hienAnh(this, ivAnh, p.anhUrl);

        boolean daXuLy = p.ketQuaXuLy != null || p.tenNguoiXuLy != null;
        tvKetQua.setVisibility(daXuLy ? View.VISIBLE : View.GONE);
        tvKetQua.setText(getString(R.string.ket_qua_xu_ly_chi_tiet,
                p.ketQuaXuLy == null ? getString(R.string.chua_co_ket_qua) : p.ketQuaXuLy,
                p.tenNguoiXuLy == null ? "" : p.tenNguoiXuLy, DinhDang.thoiDiem(p.xuLyLuc)));
        veNut();
    }

    private void veNut() {
        TrangThai<PhanAnh> tt = viewModel.getChiTiet().getValue();
        if (tt == null || tt.duLieu == null) return;
        List<String> buoc = QuyTacTrangThai.buocTiepPhanAnh(tt.duLieu.trangThai);
        NutThaoTac.ve(hangNut, buoc, Boolean.TRUE.equals(viewModel.getDangGui().getValue()), this::xacNhan);
        tvKhongConBuoc.setVisibility(buoc.isEmpty() ? View.VISIBLE : View.GONE);
    }

    /** Hộp thoại xác nhận; đã xử lý hoặc bác bỏ thì bắt buộc ghi kết quả. */
    private void xacNhan(String trangThaiMoi) {
        boolean batBuoc = QuyTacTrangThai.phanAnhCanKetQua(trangThaiMoi);
        Bundle kem = new Bundle();
        kem.putString(KEY_TRANG_THAI_MOI, trangThaiMoi);
        XacNhanDialog.newInstance(YC_XU_LY, getString(NhanTrangThai.nut(trangThaiMoi)),
                getString(R.string.xac_nhan_xu_ly_phan_anh, getString(NhanTrangThai.chu(trangThaiMoi))),
                getString(R.string.nut_dong_y),
                batBuoc ? XacNhanDialog.NHAP_BAT_BUOC : XacNhanDialog.NHAP_TUY_CHON,
                getString(R.string.hint_ket_qua_xu_ly), getString(R.string.loi_ket_qua_trong), kem)
                .show(getChildFragmentManager(), "xu_ly_phan_anh");
    }
}
