package vn.edu.vhu.ltdd.gugugaga.admin.ui.vidusai;

import vn.edu.vhu.ltdd.gugugaga.admin.data.ApiClient;

import retrofit2.Call;

/**
 * VÍ DỤ SAI, chỉ nằm trong thư mục test: màn hình gọi Retrofit trực tiếp và gọi đồng bộ.
 * KienTrucTuKiemTest dùng lớp này để chứng minh các quy tắc ArchUnit bắt được vi phạm.
 */
public class ManHinhGoiThangApi {
    Object taiDuLieu(Call<Object> call) throws Exception {
        Object client = ApiClient.class;
        return call.execute().body() == null ? client : null;
    }
}
