package vn.edu.vhu.ltdd.gugugaga.admin.model;

import java.util.List;

/** Lô sản xuất: dòng trong GET /lo-san-xuat và chi tiết GET /lo-san-xuat/:id. */
public class LoSanXuat {
    public int id;
    /** 20 ký tự hex do server sinh ngẫu nhiên; mỗi lô một mã, khó đoán. */
    public String maTruyXuat;
    public int sanPhamId;
    public String tenSanPham;
    public String ngaySanXuat;
    public String hanSuDung;
    public int soLuong;
    public int soLuongCon;
    public String tenVung;
    public String nguoiSanXuat;
    /** Chỉ có ở danh sách. */
    public int soBuoc;

    // Chỉ có ở chi tiết
    public String trangThaiSanPham;
    public String anhHienTruongUrl;
    public String ghiChu;
    public String taoLuc;
    /** Nội dung in lên QR: PUBLIC_BASE_URL/truy-xuat/<mã>. */
    public String duongDanTruyXuat;
    public List<BuocTruyXuat> cacBuoc;
}
