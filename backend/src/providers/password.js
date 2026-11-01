'use strict';

// Provider băm mật khẩu: nơi DUY NHẤT dùng `bcryptjs`.
const bcrypt = require('bcryptjs');

const BCRYPT_COST = 10;
// Hash giả để so sánh khi email không tồn tại, giúp thời gian phản hồi tương đương
// và không lộ email nào đã đăng ký.
const DUMMY_HASH = bcrypt.hashSync('khong-phai-mat-khau-that', BCRYPT_COST);

const password = {
  hash: (plain) => bcrypt.hash(plain, BCRYPT_COST),
  // hash = null (không có tài khoản) vẫn tốn thời gian so sánh như bình thường, luôn trả false.
  async compare(plain, hash) {
    const ok = await bcrypt.compare(plain, hash || DUMMY_HASH);
    return Boolean(hash) && ok;
  },
};

module.exports = { password };
