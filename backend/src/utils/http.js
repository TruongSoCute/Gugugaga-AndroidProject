'use strict';

// Express 4 không tự bắt lỗi của hàm async; bọc lại để lỗi tới errorHandler.
const ah = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

module.exports = { ah };
