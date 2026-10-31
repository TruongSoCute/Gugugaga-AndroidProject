'use strict';

const { badRequest } = require('./errors');

// Bộ kiểm tra dữ liệu đầu vào đơn giản. Mỗi hàm kiểm tra một trường, ghi lỗi nếu sai
// và đưa giá trị đã chuẩn hóa vào `out`. Gọi done() để lấy kết quả hoặc ném lỗi 400.
// Chỉ các trường được khai báo mới vào `out`, nên trường lạ (vd: vaiTro, trangThai)
// do client tự gửi sẽ bị bỏ qua.
class Validator {
  constructor(src) {
    this.src = src && typeof src === 'object' && !Array.isArray(src) ? src : {};
    this.errors = [];
    this.out = {};
  }

  error(truong, thongDiep) {
    this.errors.push({ truong, thongDiep });
    return this;
  }

  raw(field, required) {
    const v = this.src[field];
    if (v === undefined || v === null || v === '') {
      if (required) this.error(field, 'Bắt buộc nhập.');
      return undefined;
    }
    return v;
  }

  string(field, { required = false, max = 255, min = 1 } = {}) {
    const v = this.raw(field, required);
    if (v === undefined) return this;
    if (typeof v !== 'string') return this.error(field, 'Phải là chuỗi ký tự.');
    const s = v.trim();
    if (s.length < min) return this.error(field, `Cần ít nhất ${min} ký tự.`);
    if (s.length > max) return this.error(field, `Tối đa ${max} ký tự.`);
    this.out[field] = s;
    return this;
  }

  // Mật khẩu không bị trim. bcrypt chỉ dùng 72 byte đầu nên giới hạn 72.
  password(field, { required = true } = {}) {
    const v = this.raw(field, required);
    if (v === undefined) return this;
    if (typeof v !== 'string') return this.error(field, 'Phải là chuỗi ký tự.');
    if (v.length < 8) return this.error(field, 'Mật khẩu cần ít nhất 8 ký tự.');
    if (Buffer.byteLength(v, 'utf8') > 72) return this.error(field, 'Mật khẩu quá dài.');
    this.out[field] = v;
    return this;
  }

  email(field, { required = false } = {}) {
    const v = this.raw(field, required);
    if (v === undefined) return this;
    if (typeof v !== 'string' || v.length > 255 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v.trim())) {
      return this.error(field, 'Email không hợp lệ.');
    }
    this.out[field] = v.trim().toLowerCase();
    return this;
  }

  phone(field, { required = false } = {}) {
    const v = this.raw(field, required);
    if (v === undefined) return this;
    if (typeof v !== 'string' || !/^\+?[0-9]{8,15}$/.test(v.replace(/[\s.-]/g, ''))) {
      return this.error(field, 'Số điện thoại không hợp lệ.');
    }
    this.out[field] = v.replace(/[\s.-]/g, '');
    return this;
  }

  // Nhận số nguyên dạng number hoặc chuỗi chữ số (query string).
  int(field, { required = false, min = -Infinity, max = Infinity } = {}) {
    const v = this.raw(field, required);
    if (v === undefined) return this;
    const ok = typeof v === 'number' ? Number.isInteger(v) : typeof v === 'string' && /^-?\d+$/.test(v);
    const n = Number(v);
    if (!ok || !Number.isSafeInteger(n)) return this.error(field, 'Phải là số nguyên.');
    if (n < min || n > max) return this.error(field, `Phải trong khoảng ${min} – ${max}.`);
    this.out[field] = n;
    return this;
  }

  // Ngày dạng YYYY-MM-DD và là ngày có thật.
  date(field, { required = false } = {}) {
    const v = this.raw(field, required);
    if (v === undefined) return this;
    if (typeof v !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(v)) {
      return this.error(field, 'Ngày phải có dạng YYYY-MM-DD.');
    }
    const d = new Date(`${v}T00:00:00Z`);
    if (Number.isNaN(d.getTime()) || d.toISOString().slice(0, 10) !== v) {
      return this.error(field, 'Ngày không tồn tại.');
    }
    this.out[field] = v;
    return this;
  }

  // Thời điểm ISO 8601 có múi giờ, vd 2026-03-01T07:00:00+07:00.
  datetime(field, { required = false } = {}) {
    const v = this.raw(field, required);
    if (v === undefined) return this;
    if (
      typeof v !== 'string' ||
      !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2}(\.\d+)?)?(Z|[+-]\d{2}:\d{2})$/.test(v) ||
      Number.isNaN(Date.parse(v))
    ) {
      return this.error(field, 'Thời điểm phải theo ISO 8601 có múi giờ, vd 2026-03-01T07:00:00+07:00.');
    }
    this.out[field] = new Date(v).toISOString();
    return this;
  }

  url(field, { required = false } = {}) {
    const v = this.raw(field, required);
    if (v === undefined) return this;
    let u;
    try {
      u = typeof v === 'string' && v.length <= 2000 ? new URL(v) : null;
    } catch {
      u = null;
    }
    if (!u || !['http:', 'https:'].includes(u.protocol)) {
      return this.error(field, 'Phải là đường dẫn http(s) hợp lệ.');
    }
    this.out[field] = v;
    return this;
  }

  oneOf(field, values, { required = false } = {}) {
    const v = this.raw(field, required);
    if (v === undefined) return this;
    if (!values.includes(v)) return this.error(field, `Chỉ nhận: ${values.join(', ')}.`);
    this.out[field] = v;
    return this;
  }

  array(field, { required = false, max = 50 } = {}) {
    const v = this.raw(field, required);
    if (v === undefined) return this;
    if (!Array.isArray(v)) return this.error(field, 'Phải là danh sách.');
    if (v.length > max) return this.error(field, `Tối đa ${max} phần tử.`);
    this.out[field] = v;
    return this;
  }

  done() {
    if (this.errors.length) throw badRequest('Dữ liệu không hợp lệ.', this.errors);
    return this.out;
  }
}

const validate = (src) => new Validator(src);

// Kiểm tra :id trên đường dẫn là số nguyên dương.
function idParam(value, name = 'id') {
  return validate({ [name]: value }).int(name, { required: true, min: 1, max: 2147483647 }).done()[name];
}

module.exports = { validate, idParam, Validator };
