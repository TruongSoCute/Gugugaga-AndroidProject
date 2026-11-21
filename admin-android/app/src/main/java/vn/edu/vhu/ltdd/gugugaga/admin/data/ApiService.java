package vn.edu.vhu.ltdd.gugugaga.admin.data;

import java.util.List;

import vn.edu.vhu.ltdd.gugugaga.admin.model.BaoCaoDoanhSo;
import vn.edu.vhu.ltdd.gugugaga.admin.model.BuocTruyXuat;
import vn.edu.vhu.ltdd.gugugaga.admin.model.DanhSach;
import vn.edu.vhu.ltdd.gugugaga.admin.model.DonHang;
import vn.edu.vhu.ltdd.gugugaga.admin.model.KetQuaDangNhap;
import vn.edu.vhu.ltdd.gugugaga.admin.model.KetQuaTaiAnh;
import vn.edu.vhu.ltdd.gugugaga.admin.model.LoSanXuat;
import vn.edu.vhu.ltdd.gugugaga.admin.model.NhaCungCap;
import vn.edu.vhu.ltdd.gugugaga.admin.model.PhanAnh;
import vn.edu.vhu.ltdd.gugugaga.admin.model.SanPham;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauDangNhap;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauDoiTrangThai;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauDuyet;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauTaoLo;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauThemBuoc;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauXuLyPhanAnh;
import vn.edu.vhu.ltdd.gugugaga.admin.model.VungNguyenLieu;

import okhttp3.RequestBody;
import retrofit2.Call;
import retrofit2.http.Body;
import retrofit2.http.GET;
import retrofit2.http.PATCH;
import retrofit2.http.POST;
import retrofit2.http.Path;
import retrofit2.http.Query;

/**
 * Các API backend mà app Admin dùng (Phụ lục 2: @GET/@POST/@PATCH cùng @Body, @Query, @Path).
 * Danh sách đầy đủ: docs/development/API.md. Tham số @Query bằng null thì Retrofit bỏ qua.
 */
public interface ApiService {

    // ---- Xác thực ----
    @POST("auth/dang-nhap")
    Call<KetQuaDangNhap> dangNhap(@Body YeuCauDangNhap body);

    // ---- Danh mục ----
    @GET("vung-nguyen-lieu")
    Call<List<VungNguyenLieu>> dsVungNguyenLieu();

    // ---- Sản phẩm ----
    @GET("quan-tri/san-pham")
    Call<DanhSach<SanPham>> dsSanPhamQuanTri(@Query("trangThai") String trangThai,
                                             @Query("trang") int trang,
                                             @Query("kichThuoc") int kichThuoc);

    @PATCH("san-pham/{id}/duyet")
    Call<SanPham> duyetSanPham(@Path("id") int id, @Body YeuCauDuyet body);

    // ---- Nhà cung cấp ----
    @GET("quan-tri/nha-cung-cap")
    Call<DanhSach<NhaCungCap>> dsNhaCungCapQuanTri(@Query("trangThai") String trangThai,
                                                   @Query("trang") int trang,
                                                   @Query("kichThuoc") int kichThuoc);

    @GET("quan-tri/nha-cung-cap/{id}")
    Call<NhaCungCap> chiTietNhaCungCap(@Path("id") int id);

    @PATCH("nha-cung-cap/{id}/duyet")
    Call<NhaCungCap> duyetNhaCungCap(@Path("id") int id, @Body YeuCauDuyet body);

    // ---- Lô sản xuất và truy xuất ----
    @GET("lo-san-xuat")
    Call<DanhSach<LoSanXuat>> dsLo(@Query("trang") int trang, @Query("kichThuoc") int kichThuoc);

    @GET("lo-san-xuat/{id}")
    Call<LoSanXuat> chiTietLo(@Path("id") int id);

    @POST("lo-san-xuat")
    Call<LoSanXuat> taoLo(@Body YeuCauTaoLo body);

    @POST("lo-san-xuat/{id}/buoc")
    Call<BuocTruyXuat> themBuoc(@Path("id") int loId, @Body YeuCauThemBuoc body);

    // ---- Tải ảnh ----
    @POST("tai-len/anh")
    Call<KetQuaTaiAnh> taiLenAnh(@Query("mucDich") String mucDich, @Body RequestBody body);

    // ---- Đơn hàng ----
    @GET("quan-tri/don-hang")
    Call<DanhSach<DonHang>> dsDonHangQuanTri(@Query("trangThai") String trangThai,
                                             @Query("trang") int trang,
                                             @Query("kichThuoc") int kichThuoc);

    @GET("quan-tri/don-hang/{id}")
    Call<DonHang> chiTietDonHang(@Path("id") int id);

    @PATCH("don-hang/{id}/trang-thai")
    Call<DonHang> doiTrangThaiDon(@Path("id") int id, @Body YeuCauDoiTrangThai body);

    // ---- Phản ánh ----
    @GET("quan-tri/bao-cao-vi-pham")
    Call<DanhSach<PhanAnh>> dsPhanAnh(@Query("trangThai") String trangThai,
                                      @Query("trang") int trang,
                                      @Query("kichThuoc") int kichThuoc);

    @GET("quan-tri/bao-cao-vi-pham/{id}")
    Call<PhanAnh> chiTietPhanAnh(@Path("id") int id);

    @PATCH("quan-tri/bao-cao-vi-pham/{id}")
    Call<PhanAnh> xuLyPhanAnh(@Path("id") int id, @Body YeuCauXuLyPhanAnh body);

    // ---- Báo cáo ----
    /** tu, den dạng yyyy-MM-dd hoặc null (không lọc). Chỉ QUAN_TRI, NHAN_VIEN nhận 403. */
    @GET("bao-cao/doanh-so")
    Call<BaoCaoDoanhSo> baoCaoDoanhSo(@Query("tu") String tu, @Query("den") String den);
}
