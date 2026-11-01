package vn.edu.vhu.ltdd.gugugaga.admin.model;

import java.util.List;

/** Dạng phản hồi danh sách có phân trang: { duLieu: [...], phanTrang: {...} }. */
public class DanhSach<T> {
    public List<T> duLieu;
    public PhanTrang phanTrang;
}
