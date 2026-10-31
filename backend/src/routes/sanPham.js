'use strict';

const express = require('express');
const { validate, idParam } = require('../validator');
const { notFound, conflict, badRequest } = require('../errors');
const { ah, camel, phanTrang, escapeLike } = require('../utils');
const { withTransaction } = require('../db');
const { requireAuth, requireRole, NHAN_SU, VAI_TRO } = require('../middleware/auth');
const { HOM_NAY } = require('./nhaCungCap');

// Sản phẩm được công bố khi chính nó và nhà cung cấp đều đã được duyệt.
const CONG_BO = "sp.trang_thai_duyet = 'DA_DUYET' AND ncc.trang_thai_duyet = 'DA_DUYET'";

const COT_SP = `sp.id, sp.ten, sp.mo_ta, sp.don_vi_tinh, sp.gia, sp.hang_sao, sp.anh_url,
  sp.nha_cung_cap_id, ncc.ten AS ten_nha_cung_cap, ncc.vung_id, v.ten AS ten_vung,
  COALESCE(dg.so_danh_gia, 0) AS so_danh_gia, dg.diem_trung_binh`;

const JOIN_SP = `FROM san_pham sp
  JOIN nha_cung_cap ncc ON ncc.id = sp.nha_cung_cap_id
  JOIN vung_nguyen_lieu v ON v.id = ncc.vung_id
  LEFT JOIN (
    SELECT san_pham_id, count(*) AS so_danh_gia, round(avg(so_sao), 1) AS diem_trung_binh
    FROM danh_gia GROUP BY san_pham_id
  ) dg ON dg.san_pham_id = sp.id`;

// Lọc chung cho danh sách công khai và quản trị. Mọi giá trị đi qua tham số $n.
function boLoc(req, { quanTri }) {
  const v = validate(req.query)
    .int('vung', { min: 1 })
    .int('hangSao', { min: 3, max: 5 })
    .int('nhaCungCapId', { min: 1 })
    .string('tuKhoa', { max: 100 });
  if (quanTri) v.oneOf('trangThai', ['CHO_DUYET', 'DA_DUYET', 'TU_CHOI']);
  const q = v.done();

  const where = [quanTri ? 'TRUE' : CONG_BO];
  const params = [];
  const add = (sql, value) => {
    params.push(value);
    where.push(sql.replace('?', `$${params.length}`));
  };
  if (q.vung) add('ncc.vung_id = ?', q.vung);
  if (q.hangSao) add('sp.hang_sao = ?', q.hangSao);
  if (q.nhaCungCapId) add('sp.nha_cung_cap_id = ?', q.nhaCungCapId);
  if (q.tuKhoa) add("sp.ten ILIKE ? ESCAPE '\\'", `%${escapeLike(q.tuKhoa)}%`);
  if (q.trangThai) add('sp.trang_thai_duyet = ?', q.trangThai);
  return { where: where.join(' AND '), params };
}

async function danhSach(pool, req, { quanTri }) {
  const { where, params } = boLoc(req, { quanTri });
  const p = phanTrang(req.query);
  const extra = quanTri ? ', sp.trang_thai_duyet, ncc.trang_thai_duyet AS trang_thai_nha_cung_cap, sp.tao_luc' : '';
  const order = quanTri ? "(sp.trang_thai_duyet = 'CHO_DUYET') DESC, sp.tao_luc DESC" : 'sp.hang_sao DESC, sp.ten';
  const { rows } = await pool.query(
    `SELECT ${COT_SP}${extra}, count(*) OVER () AS tong
     ${JOIN_SP}
     WHERE ${where}
     ORDER BY ${order}, sp.id
     LIMIT $${params.length + 1} OFFSET $${params.length + 2}`,
    [...params, p.kichThuoc, p.offset],
  );
  return {
    duLieu: rows.map(({ tong, ...r }) => camel(r)),
    phanTrang: { trang: p.trang, kichThuoc: p.kichThuoc, tong: rows[0]?.tong ?? 0 },
  };
}

async function chiTiet(pool, id, { quanTri }) {
  const extra = quanTri
    ? `, sp.trang_thai_duyet, sp.ly_do_tu_choi, sp.duyet_luc, sp.tao_luc,
       ncc.trang_thai_duyet AS trang_thai_nha_cung_cap`
    : '';
  const { rows } = await pool.query(
    `SELECT ${COT_SP}${extra}, ncc.dia_chi AS dia_chi_nha_cung_cap, ncc.anh_co_so_url
     ${JOIN_SP}
     WHERE sp.id = $1 AND ${quanTri ? 'TRUE' : CONG_BO}`,
    [id],
  );
  if (!rows[0]) throw notFound('Không tìm thấy sản phẩm.');
  const r = camel(rows[0]);
  const chungNhan = await pool.query(
    `SELECT id, loai, so_hieu, ngay_cap, ngay_het_han, anh_url,
            (ngay_het_han IS NULL OR ngay_het_han >= ${HOM_NAY}) AS con_hieu_luc
     FROM chung_nhan WHERE nha_cung_cap_id = $1 ORDER BY loai`,
    [r.nhaCungCapId],
  );
  // Đánh giá công khai chỉ hiện tên người đánh giá, không hiện email/số điện thoại.
  const danhGia = await pool.query(
    `SELECT dg.id, dg.so_sao, dg.noi_dung, dg.tao_luc, nd.ho_ten AS ten_nguoi_danh_gia,
            COALESCE(array_agg(a.anh_url ORDER BY a.id) FILTER (WHERE a.id IS NOT NULL), '{}') AS anh
     FROM danh_gia dg
     JOIN nguoi_dung nd ON nd.id = dg.khach_id
     LEFT JOIN anh_danh_gia a ON a.danh_gia_id = dg.id
     WHERE dg.san_pham_id = $1
     GROUP BY dg.id, nd.ho_ten
     ORDER BY dg.tao_luc DESC
     LIMIT 10`,
    [id],
  );
  return {
    ...r,
    chungNhan: chungNhan.rows.map(camel),
    danhGiaGanDay: danhGia.rows.map(camel),
  };
}

module.exports = function sanPhamRouter(ctx) {
  const { pool } = ctx;
  const auth = requireAuth(ctx);

  // ---- Công khai (app Client) ----
  const pub = express.Router();

  // GET /san-pham?vung=&hangSao=&tuKhoa=&nhaCungCapId=&trang=&kichThuoc=
  // "vung" lọc theo vùng của nhà cung cấp.
  pub.get('/', ah(async (req, res) => {
    res.json(await danhSach(pool, req, { quanTri: false }));
  }));

  pub.get('/:id', ah(async (req, res) => {
    res.json(await chiTiet(pool, idParam(req.params.id), { quanTri: false }));
  }));

  // Nhân sự nhập sản phẩm; sản phẩm mới luôn CHO_DUYET, hạng sao do quản trị chốt khi duyệt.
  pub.post('/', auth, requireRole(...NHAN_SU), ah(async (req, res) => {
    const d = validate(req.body)
      .int('nhaCungCapId', { required: true, min: 1 })
      .string('ten', { required: true, max: 200 })
      .string('moTa', { max: 5000 })
      .string('donViTinh', { max: 40 })
      .int('gia', { required: true, min: 1, max: 1000000000 })
      .url('anhUrl')
      .done();
    const ncc = await pool.query('SELECT trang_thai_duyet FROM nha_cung_cap WHERE id = $1', [d.nhaCungCapId]);
    if (!ncc.rows[0]) {
      throw badRequest('Dữ liệu không hợp lệ.', [{ truong: 'nhaCungCapId', thongDiep: 'Nhà cung cấp không tồn tại.' }]);
    }
    if (ncc.rows[0].trang_thai_duyet === 'TU_CHOI') {
      throw conflict('NHA_CUNG_CAP_BI_TU_CHOI', 'Nhà cung cấp đã bị từ chối, không thể thêm sản phẩm.');
    }
    const { rows } = await pool.query(
      `INSERT INTO san_pham (nha_cung_cap_id, ten, mo_ta, don_vi_tinh, gia, anh_url, nguoi_tao_id)
       VALUES ($1, $2, $3, COALESCE($4, 'gói'), $5, $6, $7) RETURNING id`,
      [d.nhaCungCapId, d.ten, d.moTa || null, d.donViTinh || null, d.gia, d.anhUrl || null, req.user.id],
    );
    res.status(201).json(await chiTiet(pool, rows[0].id, { quanTri: true }));
  }));

  // Chỉ QUAN_TRI duyệt sản phẩm và chốt hạng OCOP 3–5 sao.
  pub.patch('/:id/duyet', auth, requireRole(VAI_TRO.QUAN_TRI), ah(async (req, res) => {
    const id = idParam(req.params.id);
    const d = validate(req.body)
      .oneOf('trangThai', ['DA_DUYET', 'TU_CHOI'], { required: true })
      .int('hangSao', { min: 3, max: 5 })
      .string('lyDo', { max: 1000 })
      .done();
    if (d.trangThai === 'DA_DUYET' && !d.hangSao) {
      throw badRequest('Dữ liệu không hợp lệ.', [{ truong: 'hangSao', thongDiep: 'Cần chọn hạng OCOP 3, 4 hoặc 5 sao.' }]);
    }
    if (d.trangThai === 'TU_CHOI' && !d.lyDo) {
      throw badRequest('Dữ liệu không hợp lệ.', [{ truong: 'lyDo', thongDiep: 'Cần ghi lý do từ chối.' }]);
    }

    await withTransaction(pool, async (client) => {
      const { rows } = await client.query(
        `SELECT sp.trang_thai_duyet, sp.hang_sao, ncc.trang_thai_duyet AS trang_thai_ncc
         FROM san_pham sp JOIN nha_cung_cap ncc ON ncc.id = sp.nha_cung_cap_id
         WHERE sp.id = $1 FOR UPDATE OF sp`,
        [id],
      );
      const sp = rows[0];
      if (!sp) throw notFound('Không tìm thấy sản phẩm.');
      if (sp.trang_thai_duyet === d.trangThai && (d.trangThai === 'TU_CHOI' || sp.hang_sao === d.hangSao)) {
        throw conflict('TRANG_THAI_KHONG_DOI', 'Sản phẩm đã ở trạng thái này.');
      }
      if (d.trangThai === 'DA_DUYET' && sp.trang_thai_ncc !== 'DA_DUYET') {
        throw conflict('NHA_CUNG_CAP_CHUA_DUYET', 'Cần duyệt nhà cung cấp trước khi duyệt sản phẩm.');
      }
      await client.query(
        `UPDATE san_pham
         SET trang_thai_duyet = $2::varchar,
             hang_sao = CASE WHEN $2::varchar = 'DA_DUYET' THEN $3::smallint ELSE hang_sao END,
             ly_do_tu_choi = $4, nguoi_duyet_id = $5, duyet_luc = now()
         WHERE id = $1`,
        [id, d.trangThai, d.hangSao ?? null, d.trangThai === 'TU_CHOI' ? d.lyDo : null, req.user.id],
      );
    });

    res.json(await chiTiet(pool, id, { quanTri: true }));
  }));

  // ---- Quản trị (app Admin): mọi trạng thái, có lọc trangThai ----
  const admin = express.Router();
  admin.use(auth, requireRole(...NHAN_SU));
  admin.get('/', ah(async (req, res) => {
    res.json(await danhSach(pool, req, { quanTri: true }));
  }));
  admin.get('/:id', ah(async (req, res) => {
    res.json(await chiTiet(pool, idParam(req.params.id), { quanTri: true }));
  }));

  return { pub, admin };
};
