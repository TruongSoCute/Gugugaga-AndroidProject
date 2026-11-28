package vn.edu.vhu.ltdd.gugugaga.admin.ui.issuereport;

import android.app.Application;

import androidx.annotation.NonNull;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.data.ApiResult;
import vn.edu.vhu.ltdd.gugugaga.admin.data.IssueReportRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.model.IssueReport;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.DetailsViewModel;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.StatusBadge;

public class IssueReportDetailsViewModel extends DetailsViewModel<IssueReport> {
    private final IssueReportRepository repo;

    public IssueReportDetailsViewModel(@NonNull Application app) {
        super(app);
        repo = new IssueReportRepository(app);
    }

    @Override
    protected void goiChiTiet(int id, ApiResult<IssueReport> kq) {
        repo.chiTiet(id, kq);
    }

    public void xuLy(String trangThaiMoi, String ketQua) {
        if (!batDauGui()) return;
        repo.xuLy(id, trangThaiMoi, ketQua,
                ketQuaThaoTac(chuoi(R.string.da_cap_nhat_phan_anh, chuoi(StatusBadge.chu(trangThaiMoi)))));
    }
}
