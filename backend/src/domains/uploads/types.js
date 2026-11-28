'use strict';

const KICH_THUOC_TOI_DA = 5 * 1024 * 1024; // 5 MB
const LOAI_ANH = Object.freeze({ jpg: 'image/jpeg', png: 'image/png', webp: 'image/webp' });
const MUC_DICH = Object.freeze(['danh-gia', 'san-pham', 'nha-cung-cap', 'lo', 'phan-anh', 'khac']);

// Nhận dạng ảnh theo byte đầu tệp (magic number), không tin Content-Type app gửi lên.
function nhanDangAnh(buf) {
  if (!buf || buf.length < 12) return null;
  if (buf[0] === 0xff && buf[1] === 0xd8 && buf[2] === 0xff) return 'jpg';
  if (buf[0] === 0x89 && buf[1] === 0x50 && buf[2] === 0x4e && buf[3] === 0x47) return 'png';
  if (buf.toString('ascii', 0, 4) === 'RIFF' && buf.toString('ascii', 8, 12) === 'WEBP') return 'webp';
  return null;
}

// Thư mục lưu theo mục đích, để dễ quản lý trên Supabase. Giá trị lạ thì về "khac".
const thuMuc = (mucDich) => (MUC_DICH.includes(mucDich) ? mucDich : 'khac');

module.exports = { KICH_THUOC_TOI_DA, LOAI_ANH, MUC_DICH, nhanDangAnh, thuMuc };
