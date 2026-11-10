package vn.edu.vhu.ltdd.gugugaga.admin.ui.lo;

import android.app.Application;
import android.net.Uri;

import androidx.annotation.NonNull;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.data.AnhRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.data.KetQuaApi;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.CoSoViewModel;

/** Giữ trạng thái và kết quả tải ảnh của ThemBuocDialog qua xoay màn hình. */
public class ThemBuocViewModel extends CoSoViewModel {
    private static final String MUC_DICH_ANH_LO = "lo";

    private final AnhRepository anhRepo;
    private final MutableLiveData<Boolean> dangTaiAnh = new MutableLiveData<>(false);
    private final MutableLiveData<String> trangThaiAnh = new MutableLiveData<>();
    /** URL upload thành công được giữ lại để Dialog mới nhận được sau khi xoay màn hình. */
    private final MutableLiveData<String> anhDaTai = new MutableLiveData<>();

    public ThemBuocViewModel(@NonNull Application app) {
        super(app);
        anhRepo = new AnhRepository(app);
    }

    public LiveData<Boolean> getDangTaiAnh() { return dangTaiAnh; }
    public LiveData<String> getTrangThaiAnh() { return trangThaiAnh; }
    public LiveData<String> getAnhDaTai() { return anhDaTai; }

    public void taiAnh(Uri uri) {
        if (uri == null || Boolean.TRUE.equals(dangTaiAnh.getValue())) return;
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
}
