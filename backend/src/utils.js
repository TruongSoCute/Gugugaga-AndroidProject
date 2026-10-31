'use strict';

const crypto = require('node:crypto');

// Đổi khóa snake_case của dòng SQL sang camelCase cho JSON trả về app.
function camel(row) {
  if (!row) return row;
  const out = {};
  for (const [k, v] of Object.entries(row)) {
    out[k.replace(/_([a-z0-9])/g, (_, c) => c.toUpperCase())] = v;
  }
  return out;
}

// Mã truy xuất: 10 byte ngẫu nhiên an toàn mật mã -> 20 ký tự hex in hoa (80 bit),
// không thể đoán hoặc dò lần lượt như mã tăng dần.
const MA_TRUY_XUAT_REGEX = /^[0-9A-F]{20}$/;
function taoMaTruyXuat() {
  return crypto.randomBytes(10).toString('hex').toUpperCase();
}

// Thoát ký tự đặc biệt của LIKE để từ khóa người dùng không thành mẫu tìm kiếm.
function escapeLike(s) {
  return s.replace(/[\\%_]/g, (c) => `\\${c}`);
}

function phanTrang(query) {
  const trang = Math.max(1, Number.parseInt(query.trang, 10) || 1);
  const kichThuoc = Math.min(100, Math.max(1, Number.parseInt(query.kichThuoc, 10) || 20));
  return { trang, kichThuoc, offset: (trang - 1) * kichThuoc };
}

module.exports = { camel, taoMaTruyXuat, MA_TRUY_XUAT_REGEX, escapeLike, phanTrang };

// Express 4 không tự bắt lỗi của hàm async; bọc lại để lỗi tới errorHandler.
const ah = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

module.exports.ah = ah;
