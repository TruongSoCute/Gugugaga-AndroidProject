package vn.edu.vhu.ltdd.gugugaga.admin.ui.batch;

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
import vn.edu.vhu.ltdd.gugugaga.admin.data.ImageRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.data.ApiResult;
import vn.edu.vhu.ltdd.gugugaga.admin.data.ProductionBatchRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.data.ProductRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.data.SourcingRegionRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.model.ProductionBatch;
import vn.edu.vhu.ltdd.gugugaga.admin.model.Product;
import vn.edu.vhu.ltdd.gugugaga.admin.model.SourcingRegion;
import vn.edu.vhu.ltdd.gugugaga.admin.model.CreateBatchRequest;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.BaseViewModel;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.Event;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.UiState;

/**
 * Form tạo lô: nạp danh sách sản phẩm cho Spinner (giữ qua xoay), tải ảnh hiện trường và gửi yêu cầu tạo lô.
 * Dữ liệu đang nhập dở KHÔNG nằm ở đây mà lưu bằng Bundle trong Fragment (Lab A2).
 */
public class CreateBatchViewModel extends BaseViewModel {
    private static final String MUC_DICH_ANH_LO = "lo";

    private final ProductRepository sanPhamRepo;
    private final SourcingRegionRepository vungRepo;
    private final ProductionBatchRepository loRepo;
    private final ImageRepository anhRepo;
    private final MutableLiveData<UiState<List<Product>>> sanPham = new MutableLiveData<>();
    private final MutableLiveData<UiState<List<SourcingRegion>>> vungNguyenLieu = new MutableLiveData<>();
    private final MutableLiveData<Boolean> dangGui = new MutableLiveData<>(false);
    private final MutableLiveData<Boolean> dangTaiAnh = new MutableLiveData<>(false);
    private final MutableLiveData<String> trangThaiAnh = new MutableLiveData<>();
    /** URL upload thành công được giữ lại để View mới nhận được sau khi xoay màn hình. */
    private final MutableLiveData<Event<String>> anhDaTai = new MutableLiveData<>();
    private final MutableLiveData<Event<ProductionBatch>> daTao = new MutableLiveData<>();
    private final MutableLiveData<Event<Map<String, String>>> loiTheoTruong = new MutableLiveData<>();

    public CreateBatchViewModel(@NonNull Application app) {
        super(app);
        sanPhamRepo = new ProductRepository(app);
        vungRepo = new SourcingRegionRepository(app);
        loRepo = new ProductionBatchRepository(app);
        anhRepo = new ImageRepository(app);
    }

    public LiveData<UiState<List<Product>>> getSanPham() { return sanPham; }
    public LiveData<UiState<List<SourcingRegion>>> getVungNguyenLieu() { return vungNguyenLieu; }
    public LiveData<Boolean> getDangGui() { return dangGui; }
    public LiveData<Boolean> getDangTaiAnh() { return dangTaiAnh; }
    public LiveData<String> getTrangThaiAnh() { return trangThaiAnh; }
    public LiveData<Event<String>> getAnhDaTai() { return anhDaTai; }
    public LiveData<Event<ProductionBatch>> getDaTao() { return daTao; }
    /** Lỗi 400 của backend theo từng ô (vd hanSuDung), để Fragment setError đúng ô. */
    public LiveData<Event<Map<String, String>>> getLoiTheoTruong() { return loiTheoTruong; }

    public void taiSanPhamLanDau() {
        if (sanPham.getValue() == null) taiSanPham();
        if (vungNguyenLieu.getValue() == null) taiVungNguyenLieu();
    }

    public void taiLaiDuLieu() {
        taiSanPham();
        taiVungNguyenLieu();
    }

    public void taiVungNguyenLieu() {
        vungNguyenLieu.setValue(UiState.dangTai());
        vungRepo.danhSach(new ApiResult<List<SourcingRegion>>() {
            @Override
            public void thanhCong(List<SourcingRegion> duLieu) {
                vungNguyenLieu.setValue(UiState.thanhCong(duLieu));
            }

            @Override
            public void loi(String thongDiep) {
                vungNguyenLieu.setValue(UiState.loi(thongDiep));
            }

            @Override
            public void hetPhien() {
                daHetPhien();
            }
        });
    }

    /** Không tạo lô cho sản phẩm bị từ chối (backend trả 409), nên bỏ khỏi Spinner cho gọn. */
    public void taiSanPham() {
        sanPham.setValue(UiState.dangTai());
        sanPhamRepo.danhSach(null, new ApiResult<List<Product>>() {
            @Override
            public void thanhCong(List<Product> duLieu) {
                List<Product> conDung = new ArrayList<>();
                if (duLieu != null) {
                    for (Product sp : duLieu) {
                        if (!AppConfig.TRANG_THAI_TU_CHOI.equals(sp.trangThaiDuyet)) conDung.add(sp);
                    }
                }
                sanPham.setValue(UiState.thanhCong(conDung));
            }

            @Override
            public void loi(String thongDiep) {
                sanPham.setValue(UiState.loi(thongDiep));
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
        anhRepo.taiLen(uri, MUC_DICH_ANH_LO, new ApiResult<String>() {
            @Override
            public void thanhCong(String url) {
                dangTaiAnh.setValue(false);
                trangThaiAnh.setValue(chuoi(R.string.da_tai_anh_len));
                anhDaTai.setValue(new Event<>(url));
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

    public void taoLo(CreateBatchRequest yeuCau) {
        if (Boolean.TRUE.equals(dangGui.getValue())) return; // chống bấm Lưu hai lần
        dangGui.setValue(true);
        loRepo.taoLo(yeuCau, new ApiResult<ProductionBatch>() {
            @Override
            public void thanhCong(ProductionBatch duLieu) {
                dangGui.setValue(false);
                daTao.setValue(new Event<>(duLieu));
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
                loiTheoTruong.setValue(new Event<>(theoTruong));
            }

            @Override
            public void hetPhien() {
                dangGui.setValue(false);
                daHetPhien();
            }
        });
    }
}
