package vn.edu.vhu.ltdd.gugugaga.admin.data;

import android.content.Context;

import vn.edu.vhu.ltdd.gugugaga.admin.model.DataList;
import vn.edu.vhu.ltdd.gugugaga.admin.model.IssueReport;
import vn.edu.vhu.ltdd.gugugaga.admin.model.ResolveIssueReportRequest;

/** API phản ánh hàng giả, sai mô tả cho nhân sự. */
public class IssueReportRepository {
    private final Context app;

    public IssueReportRepository(Context ctx) {
        this.app = ctx.getApplicationContext();
    }

    /**
     * Một trang phản ánh (mới xếp trước), kèm phanTrang.
     *
     * @param trangThai MOI / DANG_XU_LY / DA_XU_LY / BAC_BO, hoặc null để lấy tất cả.
     */
    public void danhSach(String trangThai, int trang, int kichThuoc, ApiResult<DataList<IssueReport>> kq) {
        ApiCall.goi(app, ApiClient.get(app).dsPhanAnh(trangThai, trang, kichThuoc), true, kq);
    }

    public void chiTiet(int id, ApiResult<IssueReport> kq) {
        ApiCall.goi(app, ApiClient.get(app).chiTietPhanAnh(id), true, kq);
    }

    /** Chỉ đi tới; backend trả 409 nếu sai thứ tự, 400 nếu thiếu kết quả khi kết thúc. */
    public void xuLy(int id, String trangThai, String ketQuaXuLy, ApiResult<IssueReport> kq) {
        ApiCall.goi(app, ApiClient.get(app).xuLyPhanAnh(id, new ResolveIssueReportRequest(trangThai, ketQuaXuLy)), true, kq);
    }
}
