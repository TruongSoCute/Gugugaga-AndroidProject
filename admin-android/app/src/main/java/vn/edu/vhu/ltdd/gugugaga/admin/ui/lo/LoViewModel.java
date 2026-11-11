
package vn.edu.vhu.ltdd.gugugaga.admin.ui.lo;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;

import java.util.ArrayList;
import java.util.List;

import vn.edu.vhu.ltdd.gugugaga.admin.data.KetQuaApi;
import vn.edu.vhu.ltdd.gugugaga.admin.data.LoSanXuatRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.model.DanhSach;
import vn.edu.vhu.ltdd.gugugaga.admin.model.LoSanXuat;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.CoSoViewModel;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.TrangThai;

/**
 * ViewModel danh sách lô sản xuất có phân trang.
 */
public class LoViewModel extends CoSoViewModel {

    private static final int KICH_THUOC_TRANG = 100;

    private final LoSanXuatRepository repo;

    private final MutableLiveData<TrangThai<List<LoSanXuat>>> danhSach =
            new MutableLiveData<>();

    private final MutableLiveData<Boolean> dangTaiThem =
            new MutableLiveData<>(false);

    private final MutableLiveData<String> loiTaiThem =
            new MutableLiveData<>();

    private final List<LoSanXuat> danhSachHienTai = new ArrayList<>();

    private int trangHienTai = 0;
    private int tongSoLo = 0;

    private boolean dangTaiTrangThem = false;
    private boolean coTheTaiThem = true;
    private boolean daTaiLanDau = false;

    private int maYeuCau = 0;

    public LoViewModel(@NonNull Application app) {
        super(app);
        repo = new LoSanXuatRepository(app);
    }

    public LiveData<TrangThai<List<LoSanXuat>>> getDanhSach() {
        return danhSach;
    }

    public LiveData<Boolean> getDangTaiThem() {
        return dangTaiThem;
    }

    public LiveData<String> getLoiTaiThem() {
        return loiTaiThem;
    }

    /**
     * Chỉ tải lần đầu, tránh gọi API lại khi xoay màn hình.
     */
    public void taiLanDau() {
        if (daTaiLanDau) return;

        daTaiLanDau = true;
        taiLai();
    }

    /**
     * Tải lại danh sách từ trang đầu tiên.
     */
    public void taiLai() {
        maYeuCau++;

        int maHienTai = maYeuCau;

        trangHienTai = 0;
        tongSoLo = 0;

        coTheTaiThem = true;
        dangTaiTrangThem = false;

        dangTaiThem.setValue(false);
        loiTaiThem.setValue(null);

        danhSachHienTai.clear();

        danhSach.setValue(TrangThai.dangTai());

        taiTrang(1, maHienTai, false);
    }

    /**
     * Tải trang tiếp theo khi người dùng cuộn gần cuối.
     */
    public void taiTrangTiepTheo() {
        if (!daTaiLanDau) return;
        if (dangTaiTrangThem) return;
        if (!coTheTaiThem) return;
        if (trangHienTai == 0) return;

        if (danhSachHienTai.size() >= tongSoLo) {
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
     * Gọi API lấy một trang lô sản xuất.
     */
    private void taiTrang(
            int trang,
            int ma,
            boolean laTaiThem
    ) {
        repo.danhSach(
                trang,
                new KetQuaApi<DanhSach<LoSanXuat>>() {

                    @Override
                    public void thanhCong(DanhSach<LoSanXuat> ketQua) {

                        if (ma != maYeuCau) return;

                        if (ketQua == null || ketQua.duLieu == null) {
                            xuLyLoi("Dữ liệu trả về không hợp lệ.", laTaiThem);
                            return;
                        }

                        List<LoSanXuat> duLieuMoi = ketQua.duLieu;

                        if (laTaiThem) {
                            danhSachHienTai.addAll(duLieuMoi);
                        } else {
                            danhSachHienTai.clear();
                            danhSachHienTai.addAll(duLieuMoi);
                        }

                        trangHienTai = trang;

                        if (ketQua.phanTrang != null) {
                            tongSoLo = ketQua.phanTrang.tong;
                        } else if (trang == 1) {
                            tongSoLo = duLieuMoi.size();
                        }

                        coTheTaiThem =
                                !duLieuMoi.isEmpty()
                                        && danhSachHienTai.size() < tongSoLo;

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
