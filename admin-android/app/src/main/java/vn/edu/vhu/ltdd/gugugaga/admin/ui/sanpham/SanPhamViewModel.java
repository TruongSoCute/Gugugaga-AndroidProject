
package vn.edu.vhu.ltdd.gugugaga.admin.ui.sanpham;

import android.app.Application;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.lifecycle.AndroidViewModel;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.data.KetQuaApi;
import vn.edu.vhu.ltdd.gugugaga.admin.data.SanPhamRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.model.DanhSach;
import vn.edu.vhu.ltdd.gugugaga.admin.model.SanPham;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.SuKien;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.TrangThai;

public class SanPhamViewModel extends AndroidViewModel {

    private static final String TAG = "PHAN_TRANG";
    private static final int KICH_THUOC_TRANG = 100;

    private final SanPhamRepository repo;

    private final MutableLiveData<TrangThai<List<SanPham>>> danhSach =
            new MutableLiveData<>();

    private final MutableLiveData<SuKien<String>> thongBao =
            new MutableLiveData<>();

    private final MutableLiveData<Boolean> hetPhien =
            new MutableLiveData<>(false);

    private final MutableLiveData<Boolean> dangTaiThem =
            new MutableLiveData<>(false);

    private final MutableLiveData<String> loiTaiThem =
            new MutableLiveData<>();

    private int trangHienTai = 0;
    private int tongSoSanPham = 0;

    private boolean coTheTaiThem = true;
    private boolean dangTaiTrangThem = false;
    private boolean daChonLoc = false;

    private String locHienTai;

    private List<SanPham> danhSachHienTai = new ArrayList<>();

    private int maYeuCau = 0;

    public SanPhamViewModel(@NonNull Application app) {
        super(app);
        repo = new SanPhamRepository(app);
    }

    public LiveData<TrangThai<List<SanPham>>> getDanhSach() {
        return danhSach;
    }

    public LiveData<SuKien<String>> getThongBao() {
        return thongBao;
    }

    public LiveData<Boolean> getHetPhien() {
        return hetPhien;
    }

    public LiveData<Boolean> getDangTaiThem() {
        return dangTaiThem;
    }

    public LiveData<String> getLoiTaiThem() {
        return loiTaiThem;
    }

    /**
     * Chọn bộ lọc trạng thái sản phẩm.
     */
    public void chonLoc(String trangThai) {

        if (daChonLoc && Objects.equals(locHienTai, trangThai)) {
            return;
        }

        daChonLoc = true;
        locHienTai = trangThai;

        taiLai();
    }

    /**
     * Tải lại danh sách từ trang đầu tiên.
     */
    public void taiLai() {

        maYeuCau++;

        int maHienTai = maYeuCau;
        String loc = locHienTai;

        trangHienTai = 0;
        tongSoSanPham = 0;

        coTheTaiThem = true;
        dangTaiTrangThem = false;

        dangTaiThem.setValue(false);
        loiTaiThem.setValue(null);

        danhSachHienTai = new ArrayList<>();

        danhSach.setValue(TrangThai.dangTai());

        taiTrang(loc, 1, maHienTai, false);
    }

    /**
     * Tải trang tiếp theo khi người dùng cuộn gần cuối.
     */
    public void taiTrangTiepTheo() {

        if (!daChonLoc) return;

        if (dangTaiTrangThem) return;

        if (!coTheTaiThem) return;

        if (trangHienTai == 0) return;

        if (danhSachHienTai.size() >= tongSoSanPham) {
            coTheTaiThem = false;
            return;
        }

        int trangCanTai = trangHienTai + 1;

        dangTaiTrangThem = true;
        dangTaiThem.setValue(true);
        loiTaiThem.setValue(null);

        taiTrang(
                locHienTai,
                trangCanTai,
                maYeuCau,
                true
        );
    }

    /**
     * Gọi API lấy một trang sản phẩm.
     */
    private void taiTrang(
            String loc,
            int trang,
            int ma,
            boolean laTaiThem
    ) {

        repo.danhSach(
                loc,
                trang,
                new KetQuaApi<DanhSach<SanPham>>() {

                    @Override
                    public void thanhCong(DanhSach<SanPham> ketQua) {

                        if (ma != maYeuCau
                                || !Objects.equals(loc, locHienTai)) {
                            return;
                        }

                        if (ketQua == null || ketQua.duLieu == null) {
                            xuLyLoi(
                                    "Dữ liệu trả về không hợp lệ.",
                                    laTaiThem
                            );
                            return;
                        }

                        List<SanPham> duLieuMoi = ketQua.duLieu;

                        if (laTaiThem) {
                            danhSachHienTai.addAll(duLieuMoi);
                        } else {
                            danhSachHienTai =
                                    new ArrayList<>(duLieuMoi);
                        }

                        trangHienTai = trang;

                        // Lấy tổng số bản ghi từ Backend.
                        if (ketQua.phanTrang != null) {

                            int tongTuApi = ketQua.phanTrang.tong;

                            // Trang đầu tiên luôn cập nhật tổng.
                            // Trang sau chỉ cập nhật nếu API có tổng hợp lệ.
                            if (trang == 1 || tongTuApi > 0) {
                                tongSoSanPham = tongTuApi;
                            }

                        } else if (trang == 1) {

                            // Dự phòng nếu API không trả metadata.
                            tongSoSanPham = duLieuMoi.size();
                        }

                        // Chỉ dừng khi đã nhận đủ tổng số bản ghi.
                        coTheTaiThem =
                                danhSachHienTai.size() < tongSoSanPham;

                        dangTaiTrangThem = false;
                        dangTaiThem.setValue(false);
                        loiTaiThem.setValue(null);

                        Log.d(TAG,
                                "Trang: " + trang
                                        + " | Nhận được: " + duLieuMoi.size()
                                        + " | Đang có: " + danhSachHienTai.size()
                                        + " | Tổng từ API: " + tongSoSanPham
                                        + " | Còn dữ liệu: " + coTheTaiThem
                        );

                        danhSach.setValue(
                                TrangThai.thanhCong(
                                        new ArrayList<>(danhSachHienTai)
                                )
                        );
                    }

                    @Override
                    public void loi(String thongDiep) {

                        if (ma != maYeuCau
                                || !Objects.equals(loc, locHienTai)) {
                            return;
                        }

                        xuLyLoi(thongDiep, laTaiThem);
                    }

                    @Override
                    public void hetPhien() {

                        if (ma != maYeuCau) return;

                        dangTaiTrangThem = false;
                        dangTaiThem.setValue(false);

                        hetPhien.setValue(true);
                    }
                }
        );
    }

    /**
     * Xử lý lỗi khi tải trang.
     */
    private void xuLyLoi(
            String thongDiep,
            boolean laTaiThem
    ) {

        if (laTaiThem) {

            dangTaiTrangThem = false;
            dangTaiThem.setValue(false);

            loiTaiThem.setValue(thongDiep);

        } else {

            danhSach.setValue(
                    TrangThai.loi(thongDiep)
            );
        }
    }

    /**
     * Duyệt sản phẩm.
     */
    public void duyet(int id, String ten, int hangSao) {

        repo.duyet(
                id,
                hangSao,
                ketQuaThaoTac(
                        getApplication().getString(
                                R.string.da_duyet,
                                ten,
                                hangSao
                        )
                )
        );
    }

    /**
     * Từ chối sản phẩm.
     */
    public void tuChoi(int id, String ten, String lyDo) {

        repo.tuChoi(
                id,
                lyDo,
                ketQuaThaoTac(
                        getApplication().getString(
                                R.string.da_tu_choi,
                                ten
                        )
                )
        );
    }

    /**
     * Xử lý kết quả duyệt hoặc từ chối sản phẩm.
     */
    private KetQuaApi<SanPham> ketQuaThaoTac(
            String thongDiepThanhCong
    ) {

        return new KetQuaApi<SanPham>() {

            @Override
            public void thanhCong(SanPham duLieu) {

                thongBao.setValue(
                        new SuKien<>(thongDiepThanhCong)
                );

                taiLai();
            }

            @Override
            public void loi(String thongDiep) {

                thongBao.setValue(
                        new SuKien<>(thongDiep)
                );
            }

            @Override
            public void hetPhien() {

                hetPhien.setValue(true);
            }
        };
    }
}
