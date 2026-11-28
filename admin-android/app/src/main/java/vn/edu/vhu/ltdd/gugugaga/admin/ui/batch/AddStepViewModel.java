package vn.edu.vhu.ltdd.gugugaga.admin.ui.batch;

import android.app.Application;
import android.net.Uri;

import androidx.annotation.NonNull;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.data.ImageRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.data.ApiResult;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.BaseViewModel;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.Event;

/** Giữ trạng thái và kết quả tải ảnh của AddStepDialog qua xoay màn hình. */
public class AddStepViewModel extends BaseViewModel {
    private static final String MUC_DICH_ANH_LO = "lo";

    private final ImageRepository anhRepo;
    private final MutableLiveData<Boolean> dangTaiAnh = new MutableLiveData<>(false);
    private final MutableLiveData<String> trangThaiAnh = new MutableLiveData<>();
    /** URL upload thành công được giữ lại để Dialog mới nhận được sau khi xoay màn hình. */
    private final MutableLiveData<Event<String>> anhDaTai = new MutableLiveData<>();

    public AddStepViewModel(@NonNull Application app) {
        super(app);
        anhRepo = new ImageRepository(app);
    }

    public LiveData<Boolean> getDangTaiAnh() { return dangTaiAnh; }
    public LiveData<String> getTrangThaiAnh() { return trangThaiAnh; }
    public LiveData<Event<String>> getAnhDaTai() { return anhDaTai; }

    public void taiAnh(Uri uri) {
        if (uri == null || Boolean.TRUE.equals(dangTaiAnh.getValue())) return;
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
}
