
package vn.edu.vhu.ltdd.gugugaga.admin.ui.phananh;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

import vn.edu.vhu.ltdd.gugugaga.admin.data.KetQuaApi;
import vn.edu.vhu.ltdd.gugugaga.admin.data.PhanAnhRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.model.DanhSach;
import vn.edu.vhu.ltdd.gugugaga.admin.model.PhanAnh;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.CoSoViewModel;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.TrangThai;

/**
 * ViewModel danh sách phản ánh có bộ lọc và phân trang.
 * Giữ dữ liệu đã tải khi xoay màn hình.
 */
public class PhanAnhViewModel extends CoSoViewModel {

    private final PhanAnhRepository repo;

    private final MutableLiveData<TrangThai<List<PhanAnh>>> danhSach =
            new MutableLiveData<>();

    private final MutableLiveData<Boolean> dangTaiThem =
            new MutableLiveData<>(false);

    private final MutableLiveData<String> loiTaiThem =
            new MutableLiveData<>();

    private final List<PhanAnh> danhSachHienTai = new ArrayList<>();

    private String locHienTai;

    private int trangHienTai = 0;
    private int tongSoPhanAnh = 0;
    private int maYeuCau = 0;

    private boolean daChonLoc = false;
    private boolean dangTaiTrangThem = false;
    private boolean coTheTaiThem = true;

    public PhanAnhViewModel(@NonNull Application app) {
        super(app);
        repo = new PhanAnhRepository(app);
    }

    public LiveData<TrangThai<List<PhanAnh>>> getDanhSach() {
        return danhSach;
    }

    public LiveData<Boolean> getDangTaiThem() {
        return dangTaiThem;
    }

    public LiveData<String> getLoiTaiThem() {
        return loiTaiThem;
    }

    /**
     * Nhận bộ lọc từ Spinner.
     */
    public void chonLoc(String loc) {
        if (daChonLoc && Objects.equals(locHienTai, loc)) {
            return;
        }

        daChonLoc = true;
        locHienTai = loc;

        taiLai();
    }

    /**
     * Tải lần đầu nếu chưa chọn bộ lọc.
     */
    public void taiLanDau() {
        if (!daChonLoc) {
            chonLoc(null);
        }
    }

    /**
     * Tải lại từ trang đầu tiên.
     */
    public void taiLai() {
        maYeuCau++;

        int maHienTai = maYeuCau;

        trangHienTai = 0;
        tongSoPhanAnh = 0;

        coTheTaiThem = true;
        dangTaiTrangThem = false;

        dangTaiThem.setValue(false);
        loiTaiThem.setValue(null);

        danhSachHienTai.clear();

        danhSach.setValue(TrangThai.dangTai());

        taiTrang(1, maHienTai, false);
    }

    /**
     * Tải trang tiếp theo khi cuộn gần cuối.
     */
    public void taiTrangTiepTheo() {

        if (!daChonLoc) return;
        if (dangTaiTrangThem) return;
        if (!coTheTaiThem) return;
        if (trangHienTai == 0) return;

        if (danhSachHienTai.size() >= tongSoPhanAnh) {
            coTheTaiThem = false;
            return;
        }

        int trangCanTai = trangHienTai + 1;

        dangTaiTrangThem = true;
        dangTaiThem.setValue(true);
        loiTaiThem.setValue(null);

        taiTrang(trangCanTai, maYeuCau, true);
    }

    /**
     * Gọi API lấy một trang phản ánh.
     */
    private void taiTrang(
            int trang,
            int ma,
            boolean laTaiThem
    ) {
        repo.danhSach(
                locHienTai,
                trang,
                new KetQuaApi<DanhSach<PhanAnh>>() {

                    @Override
                    public void thanhCong(DanhSach<PhanAnh> ketQua) {

                        if (ma != maYeuCau) return;

                        if (ketQua == null || ketQua.duLieu == null) {
                            xuLyLoi(
                                    "Dữ liệu phản ánh trả về không hợp lệ.",
                                    laTaiThem
                            );
                            return;
                        }

                        List<PhanAnh> duLieuMoi = ketQua.duLieu;

                        if (laTaiThem) {
                            danhSachHienTai.addAll(duLieuMoi);
                        } else {
                            danhSachHienTai.clear();
                            danhSachHienTai.addAll(duLieuMoi);
                        }

                        trangHienTai = trang;

                        if (ketQua.phanTrang != null) {
                            tongSoPhanAnh = ketQua.phanTrang.tong;
                        } else if (trang == 1) {
                            tongSoPhanAnh = duLieuMoi.size();
                        }

                        coTheTaiThem =
                                !duLieuMoi.isEmpty()
                                        && danhSachHienTai.size() < tongSoPhanAnh;

                        dangTaiTrangThem = false;
                        dangTaiThem.setValue(false);
                        loiTaiThem.setValue(null);

                        danhSach.setValue(
                                TrangThai.thanhCong(
                                        new ArrayList<>(danhSachHienTai)
                                )
                        );
                    }

                    @Override
                    public void loi(String thongDiep) {
                        if (ma != maYeuCau) return;

                        xuLyLoi(thongDiep, laTaiThem);
                    }

                    @Override
                    public void hetPhien() {
                        if (ma != maYeuCau) return;

                        dangTaiTrangThem = false;
                        dangTaiThem.setValue(false);

                        if (laTaiThem) {
                            loiTaiThem.setValue(
                                    "Phiên đăng nhập đã hết hạn."
                            );
                        }

                        daHetPhien();
                    }
                }
        );
    }

    /**
     * Xử lý lỗi khi tải dữ liệu.
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
            danhSach.setValue(TrangThai.loi(thongDiep));
        }
    }
}
