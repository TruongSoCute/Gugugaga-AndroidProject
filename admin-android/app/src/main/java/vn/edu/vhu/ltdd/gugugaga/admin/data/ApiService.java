package vn.edu.vhu.ltdd.gugugaga.admin.data;

import vn.edu.vhu.ltdd.gugugaga.admin.model.DanhSach;
import vn.edu.vhu.ltdd.gugugaga.admin.model.KetQuaDangNhap;
import vn.edu.vhu.ltdd.gugugaga.admin.model.SanPham;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauDangNhap;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauDuyet;

import retrofit2.Call;
import retrofit2.http.Body;
import retrofit2.http.GET;
import retrofit2.http.PATCH;
import retrofit2.http.POST;
import retrofit2.http.Path;
import retrofit2.http.Query;

/** Các API backend mà app Admin dùng. Danh sách đầy đủ: docs/development/API.md. */
public interface ApiService {

    @POST("auth/dang-nhap")
    Call<KetQuaDangNhap> dangNhap(@Body YeuCauDangNhap body);

    /** trangThai = null thì Retrofit bỏ tham số, backend trả mọi trạng thái. */
    @GET("quan-tri/san-pham")
    Call<DanhSach<SanPham>> dsSanPhamQuanTri(@Query("trangThai") String trangThai,
                                             @Query("trang") int trang,
                                             @Query("kichThuoc") int kichThuoc);

    @PATCH("san-pham/{id}/duyet")
    Call<SanPham> duyetSanPham(@Path("id") int id, @Body YeuCauDuyet body);
}
