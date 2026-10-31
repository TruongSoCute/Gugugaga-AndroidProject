'use strict';

// Provider ghi log. TAG cần chứa mã nhóm khi đã biết (quy định học phần).
const TAG = '[OCOP-API]';

const logger = {
  TAG,
  info: (...args) => console.log(TAG, ...args),
  error: (...args) => console.error(TAG, ...args),
};

module.exports = { logger };
