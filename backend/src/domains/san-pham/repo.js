'use strict';

const { camel, escapeLike } = require('../../utils/sql');

// Sản phẩm được công bố khi chính nó và nhà cung cấp đều đã được duyệt.
const CONG_BO = "sp.trang_thai_duyet = 'DA_DUYET' AND ncc.trang_thai_duyet = 'DA_DUYET'";

const COT = `sp.id, sp.ten, sp.mo_ta, sp.don_vi_tinh, sp.gia, sp.hang_sao, sp.anh_url,
  sp.nha_cung_cap_id, ncc.ten AS ten_nha_cung_cap, ncc.vung_id, v.ten AS ten_vung,
  COALESCE(dg.so_danh_gia, 0) AS so_danh_gia, dg.diem_trung_binh`;
const COT_QUAN_TRI_DS = ', sp.trang_thai_duyet, ncc.trang_thai_duyet AS trang_thai_nha_cung_cap, sp.tao_luc';
const COT_QUAN_TRI_CT = `, sp.trang_thai_duyet, sp.ly_do_tu_choi, sp.duyet_luc, sp.tao_luc,
  ncc.trang_thai_duyet AS trang_thai_nha_cung_cap`;

const FROM = `FROM san_pham sp
  JOIN nha_cung_cap ncc ON ncc.id = sp.nha_cung_cap_id
  JOIN vung_nguyen_lieu v ON v.id = ncc.vung_id
  LEFT JOIN (
    SELECT san_pham_id, count(*) AS so_danh_gia, round(avg(so_sao), 1) AS diem_trung_binh
    FROM danh_gia GROUP BY san_pham_id
  ) dg ON dg.san_pham_id = sp.id`;

// Ghép điều kiện WHERE từ bộ lọc. Giá trị luôn đi qua tham số $n, không ghép vào chuỗi SQL.
function dieuKien(loc, quanTri) {
  const where = [quanTri ? 'TRUE' : CONG_BO];
  const params = [];
  const add = (sql, value) => {
    params.push(value);
    where.push(sql.replace('?', `$${params.length}`));
  };
  if (loc.vung) add('ncc.vung_id = ?', loc.vung);
  if (loc.hangSao) add('sp.hang_sao = ?', loc.hangSao);
  if (loc.nhaCungCapId) add('sp.nha_cung_cap_id = ?', loc.nhaCungCapId);
  if (loc.tuKhoa) add("sp.ten ILIKE ? ESCAPE '\\'", `%${escapeLike(loc.tuKhoa)}%`);
  if (loc.trangThai) add('sp.trang_thai_duyet = ?', loc.trangThai);
  return { where: where.join(' AND '), params };
}

// Trả dòng thô có cột "tong" để service đóng gói phân trang.
async function danhSach(q, loc, { quanTri, limit, offset }) {
  const { where, params } = dieuKien(loc, quanTri);
  const order = quanTri ? "(sp.trang_thai_duyet = 'CHO_DUYET') DESC, sp.tao_luc DESC" : 'sp.hang_sao DESC, sp.ten';
  const { rows } = await q.query(
    `SELECT ${COT}${quanTri ? COT_QUAN_TRI_DS : ''}, count(*) OVER () AS tong
     ${FROM}
     WHERE ${where}
     ORDER BY ${order}, sp.id
     LIMIT $${params.length + 1} OFFSET $${params.length + 2}`,
    [...params, limit, offset],
  );
  return rows;
}

async function timTheoId(q, id, { quanTri }) {
  const { rows } = await q.query(
    `SELECT ${COT}${quanTri ? COT_QUAN_TRI_CT : ''}, ncc.dia_chi AS dia_chi_nha_cung_cap, ncc.anh_co_so_url
     ${FROM}
     WHERE sp.id = $1 AND ${quanTri ? 'TRUE' : CONG_BO}`,
    [id],
  );
  return camel(rows[0]);
}

// Đánh giá công khai chỉ có tên người đánh giá, không có email/số điện thoại.
async function danhGiaGanDay(q, sanPhamId, limit = 10) {
  const { rows } = await q.query(
    `SELECT dg.id, dg.so_sao, dg.noi_dung, dg.tao_luc, nd.ho_ten AS ten_nguoi_danh_gia,
            COALESCE(array_agg(a.anh_url ORDER BY a.id) FILTER (WHERE a.id IS NOT NULL), '{}') AS anh
     FROM danh_gia dg
     JOIN nguoi_dung nd ON nd.id = dg.khach_id
     LEFT JOIN anh_danh_gia a ON a.danh_gia_id = dg.id
     WHERE dg.san_pham_id = $1
     GROUP BY dg.id, nd.ho_ten
     ORDER BY dg.tao_luc DESC
     LIMIT $2`,
    [sanPhamId, limit],
  );
  return rows.map(camel);
}

async function trangThaiNhaCungCap(q, nhaCungCapId) {
  const { rows } = await q.query('SELECT trang_thai_duyet FROM nha_cung_cap WHERE id = $1', [nhaCungCapId]);
  return rows[0]?.trang_thai_duyet ?? null;
}

async function them(q, d, nguoiTaoId) {
  const { rows } = await q.query(
    `INSERT INTO san_pham (nha_cung_cap_id, ten, mo_ta, don_vi_tinh, gia, anh_url, nguoi_tao_id)
     VALUES ($1, $2, $3, COALESCE($4, 'gói'), $5, $6, $7) RETURNING id`,
    [d.nhaCungCapId, d.ten, d.moTa || null, d.donViTinh || null, d.gia, d.anhUrl || null, nguoiTaoId],
  );
  return rows[0].id;
}

// Khóa dòng sản phẩm để hai người duyệt cùng lúc không ghi đè nhau.
async function khoaDeDuyet(q, id) {
  const { rows } = await q.query(
    `SELECT sp.trang_thai_duyet, sp.hang_sao, ncc.trang_thai_duyet AS trang_thai_nha_cung_cap
     FROM san_pham sp JOIN nha_cung_cap ncc ON ncc.id = sp.nha_cung_cap_id
     WHERE sp.id = $1 FOR UPDATE OF sp`,
    [id],
  );
  return camel(rows[0]);
}

async function capNhatDuyet(q, id, { trangThai, hangSao, lyDoTuChoi, nguoiDuyetId }) {
  await q.query(
    `UPDATE san_pham
     SET trang_thai_duyet = $2::varchar,
         hang_sao = CASE WHEN $2::varchar = 'DA_DUYET' THEN $3::smallint ELSE hang_sao END,
         ly_do_tu_choi = $4, nguoi_duyet_id = $5, duyet_luc = now()
     WHERE id = $1`,
    [id, trangThai, hangSao ?? null, lyDoTuChoi, nguoiDuyetId],
  );
}

module.exports = { danhSach, timTheoId, danhGiaGanDay, trangThaiNhaCungCap, them, khoaDeDuyet, capNhatDuyet };
