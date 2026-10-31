'use strict';

const express = require('express');
const { validate, idParam } = require('../validator');
const { notFound, conflict, badRequest } = require('../errors');
const { ah, camel, phanTrang } = require('../utils');
const { withTransaction } = require('../db');
const { requireAuth, requireRole, NHAN_SU, VAI_TRO } = require('../middleware/auth');

const TRANG_THAI_DUYET = ['CHO_DUYET', 'DA_DUYET', 'TU_CHOI'];
// Ngày hiện tại theo giờ Việt Nam (CSDL Supabase chạy theo UTC).
const HOM_NAY = "(now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date";

const COT_NCC = `ncc.id, ncc.ten, ncc.nguoi_dai_dien, ncc.so_dien_thoai, ncc.dia_chi,
  ncc.vung_id, v.ten AS ten_vung, ncc.anh_co_so_url, ncc.trang_thai_duyet`;

async function layChungNhan(db, nhaCungCapId) {
  const { rows } = await db.query(
    `SELECT id, loai, so_hieu, ngay_cap, ngay_het_han, anh_url,
            (ngay_het_han IS NULL OR ngay_het_han >= ${HOM_NAY}) AS con_hieu_luc
     FROM chung_nhan WHERE nha_cung_cap_id = $1 ORDER BY loai, ngay_cap`,
    [nhaCungCapId],
  );
  return rows.map(camel);
}

function kiemTraChungNhan(list) {
  return list.map((item, i) => {
    const d = validate(item)
      .string('loai', { required: true, max: 60 })
      .string('soHieu', { required: true, max: 80 })
      .date('ngayCap', { required: true })
      .date('ngayHetHan')
      .url('anhUrl')
      .done();
    if (d.ngayHetHan && d.ngayHetHan <= d.ngayCap) {
      throw badRequest('Dữ liệu không hợp lệ.', [
        { truong: `chungNhan[${i}].ngayHetHan`, thongDiep: 'Ngày hết hạn phải sau ngày cấp.' },
      ]);
    }
    return d;
  });
}

module.exports = function nhaCungCapRouter(ctx) {
  const { pool } = ctx;
  const auth = requireAuth(ctx);

  // ---- Công khai (app Client): chỉ nhà cung cấp đã duyệt ----
  const pub = express.Router();

  pub.get('/', ah(async (req, res) => {
    const q = validate(req.query).int('vung', { min: 1 }).done();
    const { rows } = await pool.query(
      `SELECT ${COT_NCC},
              (SELECT count(*) FROM theo_doi_nha_cung_cap t WHERE t.nha_cung_cap_id = ncc.id) AS so_nguoi_theo_doi
       FROM nha_cung_cap ncc JOIN vung_nguyen_lieu v ON v.id = ncc.vung_id
       WHERE ncc.trang_thai_duyet = 'DA_DUYET' AND ($1::int IS NULL OR ncc.vung_id = $1)
       ORDER BY ncc.ten`,
      [q.vung ?? null],
    );
    res.json(rows.map(camel));
  }));

  pub.get('/:id', ah(async (req, res) => {
    const id = idParam(req.params.id);
    const { rows } = await pool.query(
      `SELECT ${COT_NCC},
              (SELECT count(*) FROM theo_doi_nha_cung_cap t WHERE t.nha_cung_cap_id = ncc.id) AS so_nguoi_theo_doi
       FROM nha_cung_cap ncc JOIN vung_nguyen_lieu v ON v.id = ncc.vung_id
       WHERE ncc.id = $1 AND ncc.trang_thai_duyet = 'DA_DUYET'`,
      [id],
    );
    if (!rows[0]) throw notFound('Không tìm thấy nhà cung cấp.');
    const sp = await pool.query(
      `SELECT id, ten, gia, don_vi_tinh, hang_sao, anh_url FROM san_pham
       WHERE nha_cung_cap_id = $1 AND trang_thai_duyet = 'DA_DUYET' ORDER BY ten`,
      [id],
    );
    res.json({ ...camel(rows[0]), chungNhan: await layChungNhan(pool, id), sanPham: sp.rows.map(camel) });
  }));

  // Nhân sự nhập hồ sơ nhà cung cấp kèm chứng nhận; hồ sơ chờ quản trị duyệt.
  // Transaction: hồ sơ và mọi chứng nhận cùng được lưu, hoặc không lưu gì nếu lỗi.
  pub.post('/', auth, requireRole(...NHAN_SU), ah(async (req, res) => {
    const d = validate(req.body)
      .string('ten', { required: true, max: 200 })
      .string('nguoiDaiDien', { required: true, max: 120 })
      .phone('soDienThoai', { required: true })
      .string('diaChi', { required: true, max: 500 })
      .int('vungId', { required: true, min: 1 })
      .url('anhCoSoUrl')
      .array('chungNhan', { max: 10 })
      .done();
    const chungNhan = kiemTraChungNhan(d.chungNhan || []);

    const result = await withTransaction(pool, async (client) => {
      const vung = await client.query('SELECT 1 FROM vung_nguyen_lieu WHERE id = $1', [d.vungId]);
      if (!vung.rowCount) throw badRequest('Vùng nguyên liệu không tồn tại.', [{ truong: 'vungId', thongDiep: 'Không tồn tại.' }]);
      const { rows } = await client.query(
        `INSERT INTO nha_cung_cap (ten, nguoi_dai_dien, so_dien_thoai, dia_chi, vung_id, anh_co_so_url, nguoi_tao_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id`,
        [d.ten, d.nguoiDaiDien, d.soDienThoai, d.diaChi, d.vungId, d.anhCoSoUrl || null, req.user.id],
      );
      const id = rows[0].id;
      for (const cn of chungNhan) {
        await client.query(
          `INSERT INTO chung_nhan (nha_cung_cap_id, loai, so_hieu, ngay_cap, ngay_het_han, anh_url)
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [id, cn.loai, cn.soHieu, cn.ngayCap, cn.ngayHetHan || null, cn.anhUrl || null],
        );
      }
      return id;
    }).catch((err) => {
      if (err.code === '23505' && err.constraint === 'chung_nhan_loai_so_hieu_key') {
        throw conflict('CHUNG_NHAN_TRUNG', 'Số hiệu chứng nhận đã tồn tại.');
      }
      throw err;
    });

    res.status(201).json(await chiTietQuanTri(pool, result));
  }));

  // Chỉ QUAN_TRI được duyệt hoặc từ chối. Khi duyệt, hồ sơ phải có ảnh cơ sở và
  // chứng nhận OCOP còn hiệu lực. Từ chối phải ghi lý do.
  pub.patch('/:id/duyet', auth, requireRole(VAI_TRO.QUAN_TRI), ah(async (req, res) => {
    const id = idParam(req.params.id);
    const d = validate(req.body)
      .oneOf('trangThai', ['DA_DUYET', 'TU_CHOI'], { required: true })
      .string('lyDo', { max: 1000 })
      .done();
    if (d.trangThai === 'TU_CHOI' && !d.lyDo) {
      throw badRequest('Dữ liệu không hợp lệ.', [{ truong: 'lyDo', thongDiep: 'Cần ghi lý do từ chối.' }]);
    }

    await withTransaction(pool, async (client) => {
      const { rows } = await client.query(
        'SELECT trang_thai_duyet, anh_co_so_url FROM nha_cung_cap WHERE id = $1 FOR UPDATE',
        [id],
      );
      const ncc = rows[0];
      if (!ncc) throw notFound('Không tìm thấy nhà cung cấp.');
      if (ncc.trang_thai_duyet === d.trangThai) {
        throw conflict('TRANG_THAI_KHONG_DOI', 'Hồ sơ đã ở trạng thái này.');
      }
      if (d.trangThai === 'DA_DUYET') {
        if (!ncc.anh_co_so_url) throw conflict('THIEU_ANH_CO_SO', 'Hồ sơ chưa có ảnh cơ sở sản xuất.');
        const cn = await client.query(
          `SELECT 1 FROM chung_nhan WHERE nha_cung_cap_id = $1 AND loai = 'OCOP'
             AND (ngay_het_han IS NULL OR ngay_het_han >= ${HOM_NAY})`,
          [id],
        );
        if (!cn.rowCount) throw conflict('THIEU_CHUNG_NHAN_OCOP', 'Hồ sơ chưa có chứng nhận OCOP còn hiệu lực.');
      }
      await client.query(
        `UPDATE nha_cung_cap
         SET trang_thai_duyet = $2, ly_do_tu_choi = $3, nguoi_duyet_id = $4, duyet_luc = now()
         WHERE id = $1`,
        [id, d.trangThai, d.trangThai === 'TU_CHOI' ? d.lyDo : null, req.user.id],
      );
    });

    res.json(await chiTietQuanTri(pool, id));
  }));

  // ---- Quản trị (app Admin): xem mọi trạng thái ----
  const admin = express.Router();
  admin.use(auth, requireRole(...NHAN_SU));

  admin.get('/', ah(async (req, res) => {
    const q = validate(req.query)
      .oneOf('trangThai', TRANG_THAI_DUYET)
      .int('vung', { min: 1 })
      .done();
    const p = phanTrang(req.query);
    const { rows } = await pool.query(
      `SELECT ${COT_NCC}, ncc.ly_do_tu_choi, ncc.tao_luc, count(*) OVER () AS tong
       FROM nha_cung_cap ncc JOIN vung_nguyen_lieu v ON v.id = ncc.vung_id
       WHERE ($1::text IS NULL OR ncc.trang_thai_duyet = $1)
         AND ($2::int IS NULL OR ncc.vung_id = $2)
       ORDER BY (ncc.trang_thai_duyet = 'CHO_DUYET') DESC, ncc.tao_luc DESC
       LIMIT $3 OFFSET $4`,
      [q.trangThai ?? null, q.vung ?? null, p.kichThuoc, p.offset],
    );
    res.json({
      duLieu: rows.map(({ tong, ...r }) => camel(r)),
      phanTrang: { trang: p.trang, kichThuoc: p.kichThuoc, tong: rows[0]?.tong ?? 0 },
    });
  }));

  admin.get('/:id', ah(async (req, res) => {
    res.json(await chiTietQuanTri(pool, idParam(req.params.id)));
  }));

  return { pub, admin };
};

async function chiTietQuanTri(pool, id) {
  const { rows } = await pool.query(
    `SELECT ${COT_NCC}, ncc.ly_do_tu_choi, ncc.duyet_luc, ncc.tao_luc,
            nd.ho_ten AS nguoi_duyet
     FROM nha_cung_cap ncc
     JOIN vung_nguyen_lieu v ON v.id = ncc.vung_id
     LEFT JOIN nguoi_dung nd ON nd.id = ncc.nguoi_duyet_id
     WHERE ncc.id = $1`,
    [id],
  );
  if (!rows[0]) throw notFound('Không tìm thấy nhà cung cấp.');
  return { ...camel(rows[0]), chungNhan: await layChungNhan(pool, id) };
}

module.exports.HOM_NAY = HOM_NAY;
