package vn.edu.vhu.ltdd.gugugaga.admin.ui.issuereport;

import android.app.Application;

import androidx.annotation.NonNull;

import vn.edu.vhu.ltdd.gugugaga.admin.data.ApiResult;
import vn.edu.vhu.ltdd.gugugaga.admin.data.IssueReportRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.model.DataList;
import vn.edu.vhu.ltdd.gugugaga.admin.model.IssueReport;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.FilteredListViewModel;

public class IssueReportListViewModel extends FilteredListViewModel<IssueReport> {
    private final IssueReportRepository repo;

    public IssueReportListViewModel(@NonNull Application app) {
        super(app);
        repo = new IssueReportRepository(app);
    }

    @Override
    protected void goiTrang(String loc, int trang, int kichThuoc, ApiResult<DataList<IssueReport>> kq) {
        repo.danhSach(loc, trang, kichThuoc, kq);
    }
}
