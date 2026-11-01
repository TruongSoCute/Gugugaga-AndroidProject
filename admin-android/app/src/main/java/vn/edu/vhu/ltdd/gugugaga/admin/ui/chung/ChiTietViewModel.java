package vn.edu.vhu.ltdd.gugugaga.admin.ui.chung;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;

import vn.edu.vhu.ltdd.gugugaga.admin.data.KetQuaApi;

/**
 * ViewModel của một màn hình chi tiết: tải bản ghi theo id (id lấy từ arguments của Fragment),
 * gửi thao tác (duyệt, chuyển trạng thái...) và báo cho danh sách biết để tải lại.
 */
public abstract class ChiTietViewModel<T> extends CoSoViewModel {
    protected final MutableLiveData<TrangThai<T>> chiTiet = new MutableLiveData<>();
    private final MutableLiveData<Boolean> dangGui = new MutableLiveData<>(false);
    private final MutableLiveData<SuKien<Boolean>> daThayDoi = new MutableLiveData<>();
    protected int id = -1;

    protected ChiTietViewModel(@NonNull Application app) {
        super(app);
    }

    public LiveData<TrangThai<T>> getChiTiet() { return chiTiet; }
    /** true khi đang gửi thao tác: màn hình khóa nút để không bấm hai lần. */
    public LiveData<Boolean> getDangGui() { return dangGui; }
    /** Sự kiện "dữ liệu đã đổi": Fragment gửi Fragment Result để danh sách tải lại. */
    public LiveData<SuKien<Boolean>> getDaThayDoi() { return daThayDoi; }

    protected abstract void goiChiTiet(int id, KetQuaApi<T> kq);

    /** Gọi trong onViewCreated; khi xoay màn hình (cùng id) thì dùng lại dữ liệu đã có. */
    public void batDau(int id) {
        if (this.id == id && chiTiet.getValue() != null) return;
        this.id = id;
        taiLai();
    }

    public void taiLai() {
        chiTiet.setValue(TrangThai.dangTai());
        goiChiTiet(id, napVao(chiTiet));
    }

    /** Trả false nếu đang có thao tác chưa xong (chống bấm hai lần). */
    protected boolean batDauGui() {
        if (Boolean.TRUE.equals(dangGui.getValue())) return false;
        dangGui.setValue(true);
        return true;
    }

    /** Thao tác trả về bản ghi mới (vd đơn sau khi đổi trạng thái): hiện luôn, không tải lại. */
    protected KetQuaApi<T> ketQuaThaoTac(String thongDiepThanhCong) {
        return new KetQuaThaoTac<T>(thongDiepThanhCong) {
            @Override
            void capNhat(T duLieu) {
                chiTiet.setValue(TrangThai.thanhCong(duLieu));
            }
        };
    }

    /** Thao tác trả về thứ khác (vd bước vừa thêm): tải lại chi tiết sau khi thành công. */
    protected <R> KetQuaApi<R> ketQuaThaoTacRoiTaiLai(String thongDiepThanhCong) {
        return new KetQuaThaoTac<R>(thongDiepThanhCong) {
            @Override
            void capNhat(R duLieu) {
                taiLai();
            }
        };
    }

    private abstract class KetQuaThaoTac<R> implements KetQuaApi<R> {
        private final String thongDiepThanhCong;

        KetQuaThaoTac(String thongDiepThanhCong) {
            this.thongDiepThanhCong = thongDiepThanhCong;
        }

        abstract void capNhat(R duLieu);

        @Override
        public void thanhCong(R duLieu) {
            dangGui.setValue(false);
            capNhat(duLieu);
            daThayDoi.setValue(new SuKien<>(true));
            baoTin(thongDiepThanhCong);
        }

        @Override
        public void loi(String thongDiep) {
            dangGui.setValue(false);
            baoTin(thongDiep); // vd 409 của backend: "Không thể chuyển đơn từ ... sang ..."
        }

        @Override
        public void hetPhien() {
            dangGui.setValue(false);
            daHetPhien();
        }
    }
}
