'use strict';

// Provider ghi log. TAG chứa mã nhóm "gugugaga" (quy định học phần).
const TAG = '[GUGUGAGA-API]';

const logger = {
  TAG,
  info: (...args) => console.log(TAG, ...args),
  error: (...args) => console.error(TAG, ...args),
};

module.exports = { logger };
