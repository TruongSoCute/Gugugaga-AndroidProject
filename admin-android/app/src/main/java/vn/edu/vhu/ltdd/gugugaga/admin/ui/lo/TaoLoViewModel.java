package vn.edu.vhu.ltdd.gugugaga.admin.ui.lo;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import vn.edu.vhu.ltdd.gugugaga.admin.AppConfig;
import vn.edu.vhu.ltdd.gugugaga.admin.data.KetQuaApi;
import vn.edu.vhu.ltdd.gugugaga.admin.data.LoSanXuatRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.data.SanPhamRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.model.LoSanXuat;
import vn.edu.vhu.ltdd.gugugaga.admin.model.SanPham;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauTaoLo;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.CoSoViewModel;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.SuKien;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.TrangThai;

/**
 * Form tạo lô: nạp danh sách sản phẩm cho Spinner (giữ qua xoay) và gửi yêu cầu tạo lô.
 * Dữ liệu đang nhập dở KHÔNG nằm ở đây mà lưu bằng Bundle trong Fragment (Lab A2).
 */
public class TaoLoViewModel extends CoSoViewModel {
    private final SanPhamRepository sanPhamRepo;
    private final LoSanXuatRepository loRepo;
    private final MutableLiveData<TrangThai<List<SanPham>>> sanPham = new MutableLiveData<>();
    private final MutableLiveData<Boolean> dangGui = new MutableLiveData<>(false);
    private final MutableLiveData<SuKien<LoSanXuat>> daTao = new MutableLiveData<>();
    private final MutableLiveData<SuKien<Map<String, String>>> loiTheoTruong = new MutableLiveData<>();

    public TaoLoViewModel(@NonNull Application app) {
        super(app);
        sanPhamRepo = new SanPhamRepository(app);
        loRepo = new LoSanXuatRepository(app);
    }

    public LiveData<TrangThai<List<SanPham>>> getSanPham() { return sanPham; }
    public LiveData<Boolean> getDangGui() { return dangGui; }
    public LiveData<SuKien<LoSanXuat>> getDaTao() { return daTao; }
    /** Lỗi 400 của backend theo từng ô (vd hanSuDung), để Fragment setError đúng ô. */
    public LiveData<SuKien<Map<String, String>>> getLoiTheoTruong() { return loiTheoTruong; }

    public void taiSanPhamLanDau() {
        if (sanPham.getValue() == null) taiSanPham();
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
