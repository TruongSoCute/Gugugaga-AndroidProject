package vn.edu.vhu.ltdd.gugugaga.admin.data;

import java.util.List;

import vn.edu.vhu.ltdd.gugugaga.admin.model.SalesReport;
import vn.edu.vhu.ltdd.gugugaga.admin.model.TraceabilityStep;
import vn.edu.vhu.ltdd.gugugaga.admin.model.DataList;
import vn.edu.vhu.ltdd.gugugaga.admin.model.Order;
import vn.edu.vhu.ltdd.gugugaga.admin.model.LoginResult;
import vn.edu.vhu.ltdd.gugugaga.admin.model.ImageUploadResult;
import vn.edu.vhu.ltdd.gugugaga.admin.model.ProductionBatch;
import vn.edu.vhu.ltdd.gugugaga.admin.model.User;
import vn.edu.vhu.ltdd.gugugaga.admin.model.Supplier;
import vn.edu.vhu.ltdd.gugugaga.admin.model.IssueReport;
import vn.edu.vhu.ltdd.gugugaga.admin.model.Product;
import vn.edu.vhu.ltdd.gugugaga.admin.model.LoginRequest;
import vn.edu.vhu.ltdd.gugugaga.admin.model.ChangeStatusRequest;
import vn.edu.vhu.ltdd.gugugaga.admin.model.ReviewRequest;
import vn.edu.vhu.ltdd.gugugaga.admin.model.LockAccountRequest;
import vn.edu.vhu.ltdd.gugugaga.admin.model.CreateBatchRequest;
import vn.edu.vhu.ltdd.gugugaga.admin.model.CreateSupplierRequest;
import vn.edu.vhu.ltdd.gugugaga.admin.model.CreateStaffRequest;
import vn.edu.vhu.ltdd.gugugaga.admin.model.CreateProductRequest;
import vn.edu.vhu.ltdd.gugugaga.admin.model.AddTraceabilityStepRequest;
import vn.edu.vhu.ltdd.gugugaga.admin.model.ResolveIssueReportRequest;
import vn.edu.vhu.ltdd.gugugaga.admin.model.SourcingRegion;

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
    Call<LoginResult> dangNhap(@Body LoginRequest body);

    // ---- Danh mục ----
    @GET("vung-nguyen-lieu")
    Call<List<SourcingRegion>> dsVungNguyenLieu();

    // ---- Sản phẩm ----
    @GET("quan-tri/san-pham")
    Call<DataList<Product>> dsSanPhamQuanTri(@Query("trangThai") String trangThai,
                                             @Query("trang") int trang,
                                             @Query("kichThuoc") int kichThuoc);

    @POST("san-pham")
    Call<Product> taoSanPham(@Body CreateProductRequest body);

    @PATCH("san-pham/{id}/duyet")
    Call<Product> duyetSanPham(@Path("id") int id, @Body ReviewRequest body);

    // ---- Nhà cung cấp ----
    @GET("quan-tri/nha-cung-cap")
    Call<DataList<Supplier>> dsNhaCungCapQuanTri(@Query("trangThai") String trangThai,
                                                   @Query("trang") int trang,
                                                   @Query("kichThuoc") int kichThuoc);

    @GET("quan-tri/nha-cung-cap/{id}")
    Call<Supplier> chiTietNhaCungCap(@Path("id") int id);

    @POST("nha-cung-cap")
    Call<Supplier> taoNhaCungCap(@Body CreateSupplierRequest body);

    @PATCH("nha-cung-cap/{id}/duyet")
    Call<Supplier> duyetNhaCungCap(@Path("id") int id, @Body ReviewRequest body);

    // ---- Lô sản xuất và truy xuất ----
    @GET("lo-san-xuat")
    Call<DataList<ProductionBatch>> dsLo(@Query("trang") int trang, @Query("kichThuoc") int kichThuoc);

    @GET("lo-san-xuat/{id}")
    Call<ProductionBatch> chiTietLo(@Path("id") int id);

    @POST("lo-san-xuat")
    Call<ProductionBatch> taoLo(@Body CreateBatchRequest body);

    @POST("lo-san-xuat/{id}/buoc")
    Call<TraceabilityStep> themBuoc(@Path("id") int loId, @Body AddTraceabilityStepRequest body);

    // ---- Tải ảnh ----
    @POST("tai-len/anh")
    Call<ImageUploadResult> taiLenAnh(@Query("mucDich") String mucDich, @Body RequestBody body);

    // ---- Đơn hàng ----
    @GET("quan-tri/don-hang")
    Call<DataList<Order>> dsDonHangQuanTri(@Query("trangThai") String trangThai,
                                             @Query("trang") int trang,
                                             @Query("kichThuoc") int kichThuoc);

    @GET("quan-tri/don-hang/{id}")
    Call<Order> chiTietDonHang(@Path("id") int id);

    @PATCH("don-hang/{id}/trang-thai")
    Call<Order> doiTrangThaiDon(@Path("id") int id, @Body ChangeStatusRequest body);

    // ---- Phản ánh ----
    @GET("quan-tri/bao-cao-vi-pham")
    Call<DataList<IssueReport>> dsPhanAnh(@Query("trangThai") String trangThai,
                                      @Query("trang") int trang,
                                      @Query("kichThuoc") int kichThuoc);

    @GET("quan-tri/bao-cao-vi-pham/{id}")
    Call<IssueReport> chiTietPhanAnh(@Path("id") int id);

    @PATCH("quan-tri/bao-cao-vi-pham/{id}")
    Call<IssueReport> xuLyPhanAnh(@Path("id") int id, @Body ResolveIssueReportRequest body);

    // ---- Báo cáo ----
    /** tu, den dạng yyyy-MM-dd hoặc null (không lọc). Chỉ QUAN_TRI, NHAN_VIEN nhận 403. */
    @GET("bao-cao/doanh-so")
    Call<SalesReport> baoCaoDoanhSo(@Query("tu") String tu, @Query("den") String den);

    // ---- Tài khoản nhân sự (chỉ QUAN_TRI) ----
    @GET("quan-tri/tai-khoan")
    Call<DataList<User>> dsTaiKhoanQuanTri(@Query("trang") int trang, @Query("kichThuoc") int kichThuoc);

    @POST("quan-tri/tai-khoan")
    Call<User> taoNhanVien(@Body CreateStaffRequest body);

    @PATCH("quan-tri/tai-khoan/{id}")
    Call<User> capNhatTrangThaiTaiKhoan(@Path("id") int id, @Body LockAccountRequest body);
}
