
package vn.edu.vhu.ltdd.gugugaga.admin.ui.donhang;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

import vn.edu.vhu.ltdd.gugugaga.admin.data.DonHangRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.data.KetQuaApi;
import vn.edu.vhu.ltdd.gugugaga.admin.model.DanhSach;
import vn.edu.vhu.ltdd.gugugaga.admin.model.DonHang;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.CoSoViewModel;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.TrangThai;

/**
 * ViewModel danh sách đơn hàng có bộ lọc và phân trang.
 * Giữ dữ liệu đã tải khi xoay màn hình.
 */
public class DonHangViewModel extends CoSoViewModel {

    private static final int KICH_THUOC_TRANG = 100;

    private final DonHangRepository repo;

    private final MutableLiveData<TrangThai<List<DonHang>>> danhSach =
            new MutableLiveData<>();

    private final MutableLiveData<Boolean> dangTaiThem =
            new MutableLiveData<>(false);

    private final MutableLiveData<String> loiTaiThem =
            new MutableLiveData<>();

    private final List<DonHang> danhSachHienTai = new ArrayList<>();

    private String locHienTai;

    private int trangHienTai = 0;
    private int tongSoDon = 0;
    private int maYeuCau = 0;

    private boolean daChonLoc = false;
    private boolean dangTaiTrangThem = false;
    private boolean coTheTaiThem = true;

    public DonHangViewModel(@NonNull Application app) {
        super(app);
        repo = new DonHangRepository(app);
    }

    public LiveData<TrangThai<List<DonHang>>> getDanhSach() {
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
     * Không tải lại nếu trạng thái không thay đổi.
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
     * Chỉ tải lần đầu nếu chưa có bộ lọc.
     */
    public void taiLanDau() {
        if (!daChonLoc) {
            chonLoc(null);
        }
    }

    /**
     * Tải lại danh sách từ trang đầu tiên.
     */
    public void taiLai() {
        maYeuCau++;

        int maHienTai = maYeuCau;

        trangHienTai = 0;
        tongSoDon = 0;

        coTheTaiThem = true;
        dangTaiTrangThem = false;

        dangTaiThem.setValue(false);
        loiTaiThem.setValue(null);

        danhSachHienTai.clear();

        danhSach.setValue(TrangThai.dangTai());

        taiTrang(1, maHienTai, false);
    }

    /**
     * Tải trang tiếp theo khi cuộn gần cuối danh sách.
     */
    public void taiTrangTiepTheo() {

        if (!daChonLoc) return;
        if (dangTaiTrangThem) return;
        if (!coTheTaiThem) return;
        if (trangHienTai == 0) return;

        if (danhSachHienTai.size() >= tongSoDon) {
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
     * Gọi API lấy một trang đơn hàng.
     */
    private void taiTrang(
            int trang,
            int ma,
            boolean laTaiThem
    ) {
        repo.danhSach(
                locHienTai,
                trang,
                new KetQuaApi<DanhSach<DonHang>>() {

                    @Override
                    public void thanhCong(DanhSach<DonHang> ketQua) {

                        if (ma != maYeuCau) return;

                        if (ketQua == null || ketQua.duLieu == null) {
                            xuLyLoi(
                                    "Dữ liệu đơn hàng trả về không hợp lệ.",
                                    laTaiThem
                            );
                            return;
                        }

                        List<DonHang> duLieuMoi = ketQua.duLieu;

                        if (laTaiThem) {
                            danhSachHienTai.addAll(duLieuMoi);
                        } else {
                            danhSachHienTai.clear();
                            danhSachHienTai.addAll(duLieuMoi);
                        }

                        trangHienTai = trang;

                        if (ketQua.phanTrang != null) {
                            tongSoDon = ketQua.phanTrang.tong;
                        } else if (trang == 1) {
                            tongSoDon = duLieuMoi.size();
                        }

                        coTheTaiThem =
                                !duLieuMoi.isEmpty()
                                        && danhSachHienTai.size() < tongSoDon;

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
