'use strict';

// Tiện ích thuần (không trạng thái, không I/O) dùng chung cho tầng repo/service/routes.

// Đổi khóa snake_case của dòng SQL sang camelCase cho JSON trả về app.
function camel(row) {
  if (!row) return row;
  const out = {};
  for (const [k, v] of Object.entries(row)) {
    out[k.replace(/_([a-z0-9])/g, (_, c) => c.toUpperCase())] = v;
  }
  return out;
}

// Thoát ký tự đặc biệt của LIKE để từ khóa người dùng không thành mẫu tìm kiếm.
function escapeLike(s) {
  return s.replace(/[\\%_]/g, (c) => `\\${c}`);
}

// Đọc trang/kichThuoc từ query string; mặc định 1/20, tối đa 100 dòng mỗi trang.
function phanTrang(query) {
  const trang = Math.max(1, Number.parseInt(query.trang, 10) || 1);
  const kichThuoc = Math.min(100, Math.max(1, Number.parseInt(query.kichThuoc, 10) || 20));
  return { trang, kichThuoc, offset: (trang - 1) * kichThuoc };
}

// Gói kết quả danh sách có cột "tong" (count(*) OVER ()) thành { duLieu, phanTrang }.
function ketQuaPhanTrang(rows, p) {
  return {
    duLieu: rows.map(({ tong, ...r }) => camel(r)),
    phanTrang: { trang: p.trang, kichThuoc: p.kichThuoc, tong: rows[0]?.tong ?? 0 },
  };
}

// Biểu thức SQL: ngày hiện tại theo giờ Việt Nam (CSDL Supabase chạy theo UTC).
const HOM_NAY_SQL = "(now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date";

module.exports = { camel, escapeLike, phanTrang, ketQuaPhanTrang, HOM_NAY_SQL };
