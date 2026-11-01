'use strict';

// Phí giao theo hình thức (VND). **Đề xuất**: đề không quy định phí và không yêu cầu tích hợp
// hãng vận chuyển thật, nên dùng mức cố định, khớp với dữ liệu mẫu trong seed.sql.
// Xem Open_questions.md; đổi mức phí chỉ cần sửa ở đây.
const PHI_GIAO = Object.freeze({
  TIEU_CHUAN: 30000,
  NHANH: 50000,
  NHAN_TAI_CHO: 0,
});

const TEN_HINH_THUC_GIAO = Object.freeze({
  TIEU_CHUAN: 'Giao tiêu chuẩn (3–5 ngày)',
  NHANH: 'Giao nhanh (1–2 ngày)',
  NHAN_TAI_CHO: 'Nhận tại điểm bán',
});

module.exports = { PHI_GIAO, TEN_HINH_THUC_GIAO };
