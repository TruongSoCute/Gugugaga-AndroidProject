'use strict';

// Đọc cấu hình từ biến môi trường. File .env chỉ dùng khi chạy trên máy cá nhân
// và KHÔNG được commit; xem .env.example.
require('dotenv').config({ quiet: true });

function required(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Thiếu biến môi trường ${name}. Xem backend/.env.example.`);
  }
  return value;
}

function loadConfig() {
  const jwtSecret = required('JWT_SECRET');
  if (jwtSecret.length < 32) {
    throw new Error('JWT_SECRET phải dài ít nhất 32 ký tự ngẫu nhiên.');
  }

  return {
    port: Number(process.env.PORT) || 3000,
    databaseUrl: required('DATABASE_URL'),
    // "true": dùng SSL (bắt buộc với Supabase). Nếu có DATABASE_CA_CERT (nội dung PEM)
    // thì kiểm tra chứng chỉ máy chủ; nếu không thì chỉ mã hóa kết nối.
    databaseSsl: process.env.DATABASE_SSL === 'true',
    databaseCaCert: process.env.DATABASE_CA_CERT || null,
    databasePoolMax: Number(process.env.DATABASE_POOL_MAX) || 5,
    jwtSecret,
    jwtExpiresIn: process.env.JWT_EXPIRES_IN || '8h',
    // Địa chỉ công khai của backend, dùng để tạo nội dung QR. Để trống thì lấy từ request.
    publicBaseUrl: (process.env.PUBLIC_BASE_URL || '').replace(/\/+$/, ''),
  };
}

module.exports = { loadConfig };
