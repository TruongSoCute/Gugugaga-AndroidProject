package vn.edu.vhu.ltdd.gugugaga.admin.ui.chung;

import android.app.Application;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Objects;

import vn.edu.vhu.ltdd.gugugaga.admin.AppConfig;
import vn.edu.vhu.ltdd.gugugaga.admin.data.KetQuaApi;
import vn.edu.vhu.ltdd.gugugaga.admin.model.DanhSach;

/**
 * ViewModel của một danh sách có bộ lọc (Spinner) và phân trang. Giữ dữ liệu đã tải để xoay màn
 * hình không gọi lại API (Lab A2); lớp con chỉ cần nói gọi repository nào cho một trang.
 *
 * Phân trang: tải trang 1 khi mở hoặc đổi bộ lọc; khi người dùng cuộn gần cuối, Fragment gọi
 * taiThem() để nối trang tiếp theo vào danh sách đã có (xem CuonTaiThem, ChanTaiThem).
 */
public abstract class LocDanhSachViewModel<T> extends CoSoViewModel {
    /** Số dòng mỗi trang, dùng chung cho mọi danh sách (backend cho tối đa 100). */
    public static final int KICH_THUOC_TRANG = 20;

    private final MutableLiveData<TrangThai<List<T>>> danhSach = new MutableLiveData<>();
    private final MutableLiveData<Boolean> dangTaiThem = new MutableLiveData<>(false);
    private final MutableLiveData<SuKien<String>> loiTaiThem = new MutableLiveData<>();

    /** Các dòng đã tải của mọi trang, theo đúng thứ tự backend trả về. */
    private final List<T> daTai = new ArrayList<>();
    private boolean daChonLoc = false;
    private String locHienTai;
    private int trangDaTai = 0;
    private boolean dangGoi = false;
    private boolean daHet = true;
    /**
     * Tăng mỗi lần tải lại từ trang 1. Kết quả mang mã cũ (vd người dùng đổi bộ lọc trong lúc
     * chờ) bị bỏ qua để không trộn dữ liệu của hai bộ lọc.
     */
    private int maYeuCau = 0;

    protected LocDanhSachViewModel(@NonNull Application app) {
        super(app);
    }

    /** Toàn bộ các dòng đã tải (trang 1 đến trang hiện tại). */
    public LiveData<TrangThai<List<T>>> getDanhSach() { return danhSach; }

    /** true khi đang tải trang thứ 2 trở đi: Fragment hiện dòng "Đang tải thêm…". */
    public LiveData<Boolean> getDangTaiThem() { return dangTaiThem; }

    /** Lỗi khi tải thêm: báo một lần, danh sách đã có vẫn giữ nguyên. */
    public LiveData<SuKien<String>> getLoiTaiThem() { return loiTaiThem; }

    /**
     * Gọi repository lấy một trang; loc = null nghĩa là không lọc.
     *
     * @param trang     số trang, bắt đầu từ 1.
     * @param kichThuoc số dòng mỗi trang.
     */
    protected abstract void goiTrang(String loc, int trang, int kichThuoc, KetQuaApi<DanhSach<T>> kq);

    /**
     * Spinner gọi lại listener khi mới gắn adapter và sau khi xoay màn hình (Lab A6), nên chỉ
     * tải khi bộ lọc thật sự đổi.
     */
    public void chonLoc(String loc) {
        if (daChonLoc && Objects.equals(locHienTai, loc)) return;
        daChonLoc = true;
        locHienTai = loc;
        taiLai();
    }

    /** Danh sách không có bộ lọc: chỉ tải lần đầu, các lần tạo lại View dùng dữ liệu đã có. */
    public void taiLanDau() {
        if (!daChonLoc) chonLoc(null);
    }

    /** Bỏ các trang đã tải và tải lại từ trang 1 (nút Thử lại, sau khi thêm/sửa dữ liệu). */
    public void taiLai() {
        maYeuCau++;
        daTai.clear();
        trangDaTai = 0;
        daHet = false;
        dangGoi = true;
        dangTaiThem.setValue(false);
        danhSach.setValue(TrangThai.dangTai());
        goi(1);
    }

    /** Tải trang tiếp theo; bỏ qua nếu đang tải, đã hết dữ liệu hoặc trang 1 chưa về. */
    public void taiThem() {
        if (dangGoi || daHet || trangDaTai == 0) return;
        dangGoi = true;
        dangTaiThem.setValue(true);
        goi(trangDaTai + 1);
    }

    private void goi(int trang) {
        int ma = maYeuCau;
        goiTrang(locHienTai, trang, KICH_THUOC_TRANG, new KetQuaApi<DanhSach<T>>() {
            @Override
            public void thanhCong(DanhSach<T> ketQua) {
                if (ma != maYeuCau) return;
                List<T> trangMoi = ketQua.duLieu != null ? ketQua.duLieu : Collections.emptyList();
                daTai.addAll(trangMoi);
                trangDaTai = trang;
                // Hết khi trang trả ít hơn kích thước trang, hoặc đã đủ tổng số dòng. Trang vượt
                // quá cuối trả duLieu rỗng và tong = 0 nên vẫn dừng, không tải mãi.
                int tong = ketQua.phanTrang != null ? ketQua.phanTrang.tong : 0;
                daHet = trangMoi.size() < KICH_THUOC_TRANG || daTai.size() >= tong;
                dangGoi = false;
                dangTaiThem.setValue(false);
                Log.d(AppConfig.TAG, "Đã tải trang " + trang + ": " + daTai.size() + "/" + tong + " dòng");
                // Gửi bản sao để Fragment không giữ chung danh sách đang được nối thêm.
                danhSach.setValue(TrangThai.thanhCong(new ArrayList<>(daTai)));
            }

            @Override
            public void loi(String thongDiep) {
                if (ma != maYeuCau) return;
                dangGoi = false;
                if (trang == 1) {
                    danhSach.setValue(TrangThai.loi(thongDiep));
                } else {
                    dangTaiThem.setValue(false);
                    loiTaiThem.setValue(new SuKien<>(thongDiep));
                }
            }

            @Override
            public void hetPhien() {
                if (ma != maYeuCau) return;
                dangGoi = false;
                dangTaiThem.setValue(false);
                daHetPhien();
            }
        });
    }
}
