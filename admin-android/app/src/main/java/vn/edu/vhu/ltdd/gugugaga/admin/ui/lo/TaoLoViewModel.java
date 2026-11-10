package vn.edu.vhu.ltdd.gugugaga.admin.ui.lo;

import android.app.Application;
import android.net.Uri;

import androidx.annotation.NonNull;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import vn.edu.vhu.ltdd.gugugaga.admin.AppConfig;
import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.data.AnhRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.data.KetQuaApi;
import vn.edu.vhu.ltdd.gugugaga.admin.data.LoSanXuatRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.data.SanPhamRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.data.VungNguyenLieuRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.model.LoSanXuat;
import vn.edu.vhu.ltdd.gugugaga.admin.model.SanPham;
import vn.edu.vhu.ltdd.gugugaga.admin.model.VungNguyenLieu;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauTaoLo;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.CoSoViewModel;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.SuKien;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.TrangThai;

/**
 * Form tạo lô: nạp danh sách sản phẩm cho Spinner (giữ qua xoay), tải ảnh hiện trường và gửi yêu cầu tạo lô.
 * Dữ liệu đang nhập dở KHÔNG nằm ở đây mà lưu bằng Bundle trong Fragment (Lab A2).
 */
public class TaoLoViewModel extends CoSoViewModel {
    private static final String MUC_DICH_ANH_LO = "lo";

    private final SanPhamRepository sanPhamRepo;
    private final VungNguyenLieuRepository vungRepo;
    private final LoSanXuatRepository loRepo;
    private final AnhRepository anhRepo;
    private final MutableLiveData<TrangThai<List<SanPham>>> sanPham = new MutableLiveData<>();
    private final MutableLiveData<TrangThai<List<VungNguyenLieu>>> vungNguyenLieu = new MutableLiveData<>();
    private final MutableLiveData<Boolean> dangGui = new MutableLiveData<>(false);
    private final MutableLiveData<Boolean> dangTaiAnh = new MutableLiveData<>(false);
    private final MutableLiveData<String> trangThaiAnh = new MutableLiveData<>();
    /** URL upload thành công được giữ lại để View mới nhận được sau khi xoay màn hình. */
    private final MutableLiveData<String> anhDaTai = new MutableLiveData<>();
    private final MutableLiveData<SuKien<LoSanXuat>> daTao = new MutableLiveData<>();
    private final MutableLiveData<SuKien<Map<String, String>>> loiTheoTruong = new MutableLiveData<>();

    public TaoLoViewModel(@NonNull Application app) {
        super(app);
        sanPhamRepo = new SanPhamRepository(app);
        vungRepo = new VungNguyenLieuRepository(app);
        loRepo = new LoSanXuatRepository(app);
        anhRepo = new AnhRepository(app);
    }

    public LiveData<TrangThai<List<SanPham>>> getSanPham() { return sanPham; }
    public LiveData<TrangThai<List<VungNguyenLieu>>> getVungNguyenLieu() { return vungNguyenLieu; }
    public LiveData<Boolean> getDangGui() { return dangGui; }
    public LiveData<Boolean> getDangTaiAnh() { return dangTaiAnh; }
    public LiveData<String> getTrangThaiAnh() { return trangThaiAnh; }
    public LiveData<String> getAnhDaTai() { return anhDaTai; }
    public LiveData<SuKien<LoSanXuat>> getDaTao() { return daTao; }
    /** Lỗi 400 của backend theo từng ô (vd hanSuDung), để Fragment setError đúng ô. */
    public LiveData<SuKien<Map<String, String>>> getLoiTheoTruong() { return loiTheoTruong; }

    public void taiSanPhamLanDau() {
        if (sanPham.getValue() == null) taiSanPham();
        if (vungNguyenLieu.getValue() == null) taiVungNguyenLieu();
    }

    public void taiLaiDuLieu() {
        taiSanPham();
        taiVungNguyenLieu();
    }

    public void taiVungNguyenLieu() {
        vungNguyenLieu.setValue(TrangThai.dangTai());
        vungRepo.danhSach(new KetQuaApi<List<VungNguyenLieu>>() {
            @Override
            public void thanhCong(List<VungNguyenLieu> duLieu) {
                vungNguyenLieu.setValue(TrangThai.thanhCong(duLieu));
            }

            @Override
            public void loi(String thongDiep) {
                vungNguyenLieu.setValue(TrangThai.loi(thongDiep));
            }

            @Override
            public void hetPhien() {
                daHetPhien();
            }
        });
    }

    /** Không tạo lô cho sản phẩm bị từ chối (backend trả 409), nên bỏ khỏi Spinner cho gọn. */
    public void taiSanPham() {
        sanPham.setValue(TrangThai.dangTai());
        sanPhamRepo.danhSach(null, new KetQuaApi<List<SanPham>>() {
            @Override
            public void thanhCong(List<SanPham> duLieu) {
                List<SanPham> conDung = new ArrayList<>();
                if (duLieu != null) {
                    for (SanPham sp : duLieu) {
                        if (!AppConfig.TRANG_THAI_TU_CHOI.equals(sp.trangThaiDuyet)) conDung.add(sp);
                    }
                }
                sanPham.setValue(TrangThai.thanhCong(conDung));
            }

            @Override
            public void loi(String thongDiep) {
                sanPham.setValue(TrangThai.loi(thongDiep));
            }

            @Override
            public void hetPhien() {
                daHetPhien();
            }
        });
    }

    public void taiAnh(Uri uri) {
        if (uri == null || Boolean.TRUE.equals(dangTaiAnh.getValue())) return;
        anhDaTai.setValue(null);
        dangTaiAnh.setValue(true);
        trangThaiAnh.setValue(chuoi(R.string.dang_tai_anh_len));
        anhRepo.taiLen(uri, MUC_DICH_ANH_LO, new KetQuaApi<String>() {
            @Override
            public void thanhCong(String url) {
                dangTaiAnh.setValue(false);
                trangThaiAnh.setValue(chuoi(R.string.da_tai_anh_len));
                anhDaTai.setValue(url);
            }

            @Override
            public void loi(String thongDiep) {
                dangTaiAnh.setValue(false);
                trangThaiAnh.setValue(thongDiep);
                baoTin(thongDiep);
            }

            @Override
            public void hetPhien() {
                dangTaiAnh.setValue(false);
                daHetPhien();
            }
        });
    }

    public void taoLo(YeuCauTaoLo yeuCau) {
        if (Boolean.TRUE.equals(dangGui.getValue())) return; // chống bấm Lưu hai lần
        dangGui.setValue(true);
        loRepo.taoLo(yeuCau, new KetQuaApi<LoSanXuat>() {
            @Override
            public void thanhCong(LoSanXuat duLieu) {
                dangGui.setValue(false);
                daTao.setValue(new SuKien<>(duLieu));
            }

            @Override
            public void loi(String thongDiep) {
                dangGui.setValue(false);
                baoTin(thongDiep); // vd 409 "sản phẩm bị từ chối"
            }

            @Override
            public void loiDuLieu(String thongDiep, Map<String, String> theoTruong) {
                dangGui.setValue(false);
                baoTin(thongDiep);
                loiTheoTruong.setValue(new SuKien<>(theoTruong));
            }

            @Override
            public void hetPhien() {
                dangGui.setValue(false);
                daHetPhien();
            }
        });
    }
}
