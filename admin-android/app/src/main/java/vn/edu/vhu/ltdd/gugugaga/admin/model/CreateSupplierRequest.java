package vn.edu.vhu.ltdd.gugugaga.admin.model;

import java.util.List;

/** Body gửi POST /nha-cung-cap để nhân sự nhập hồ sơ nhà cung cấp kèm chứng nhận. */
public class CreateSupplierRequest {
    public final String ten;
    public final String nguoiDaiDien;
    public final String soDienThoai;
    public final String diaChi;
    public final int vungId;
    public final String anhCoSoUrl;
    public final List<Certificate> chungNhan;

    public CreateSupplierRequest(String ten, String nguoiDaiDien, String soDienThoai,
                               String diaChi, int vungId, String anhCoSoUrl,
                               List<Certificate> chungNhan) {
        this.ten = ten;
        this.nguoiDaiDien = nguoiDaiDien;
        this.soDienThoai = soDienThoai;
        this.diaChi = diaChi;
        this.vungId = vungId;
        this.anhCoSoUrl = anhCoSoUrl;
        this.chungNhan = chungNhan;
    }

    public static class Certificate {
        public final String loai;
        public final String soHieu;
        public final String ngayCap;
        public final String ngayHetHan;
        public final String anhUrl;

        public Certificate(String loai, String soHieu, String ngayCap, String ngayHetHan, String anhUrl) {
            this.loai = loai;
            this.soHieu = soHieu;
            this.ngayCap = ngayCap;
            this.ngayHetHan = ngayHetHan;
            this.anhUrl = anhUrl;
        }
    }
}
