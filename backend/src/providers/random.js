'use strict';

// Provider sinh số ngẫu nhiên an toàn mật mã: nơi DUY NHẤT dùng `node:crypto`.
const crypto = require('node:crypto');

const random = {
  // n byte ngẫu nhiên -> 2n ký tự hex in hoa.
  hexUpper: (n) => crypto.randomBytes(n).toString('hex').toUpperCase(),
};

module.exports = { random };
