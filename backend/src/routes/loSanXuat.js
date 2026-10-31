'use strict';

const express = require('express');
const { validate, idParam } = require('../validator');
const { notFound, conflict, badRequest } = require('../errors');
const { ah, camel, phanTrang, taoMaTruyXuat } = require('../utils');
const { withTransaction } = require('../db');
const { requireAuth, requireRole, NHAN_SU } = require('../middleware/auth');

// Nội dung in trên QR: đường dẫn tới API truy xuất công khai của đúng lô.
// App Client đọc đoạn cuối đường dẫn để lấy mã rồi gọi GET /truy-xuat/:ma.
function duongDanTruyXuat(config, req, ma) {
  const base = config.publicBaseUrl || `${req.protocol}://${req.get('host')}`;
  return `${base}/truy-xuat/${ma}`;
}

function kiemTraBuoc(item, prefix = '') {
  const d = validate(item)
    .int('thuTu', { min: 1, max: 100 })
    .string('tenBuoc', { required: true, max: 120 })
    .string('moTa', { max: 2000 })
    .datetime('thoiDiem', { required: true })
    .url('anhUrl')
    .done();
  return { ...d, prefix };
}

async function chiTietLo(db, config, req, id) {
  const { rows } = await db.query(
    `SELECT lo.id, lo.ma_truy_xuat, lo.san_pham_id, sp.ten AS ten_san_pham,
            sp.trang_thai_duyet AS trang_thai_san_pham,
            lo.ngay_san_xuat, lo.han_su_dung, lo.so_luong, lo.so_luong_con,
            lo.vung_nguyen_lieu_id, v.ten AS ten_vung, lo.nguoi_san_xuat,
            lo.anh_hien_truong_url, lo.ghi_chu, lo.tao_luc
     FROM lo_san_xuat lo
     JOIN san_pham sp ON sp.id = lo.san_pham_id
     JOIN vung_nguyen_lieu v ON v.id = lo.vung_nguyen_lieu_id
     WHERE lo.id = $1`,
    [id],
  );
  if (!rows[0]) throw notFound('Không tìm thấy lô.');
  const buoc = await db.query(
    `SELECT id, thu_tu, ten_buoc, mo_ta, thoi_diem, anh_url
     FROM buoc_truy_xuat WHERE lo_id = $1 ORDER BY thu_tu`,
    [id],
  );
  const lo = camel(rows[0]);
  return {
    ...lo,
    duongDanTruyXuat: duongDanTruyXuat(config, req, lo.maTruyXuat),
    cacBuoc: buoc.rows.map(camel),
  };
}

module.exports = function loSanXuatRouter(ctx) {
  const { pool, config } = ctx;
  const r = express.Router();
  // Toàn bộ quản lý lô dành cho nhân sự (QUAN_TRI, NHAN_VIEN).
  r.use(requireAuth(ctx), requireRole(...NHAN_SU));

  r.get('/', ah(async (req, res) => {
    const q = validate(req.query).int('sanPhamId', { min: 1 }).done();
    const p = phanTrang(req.query);
    const { rows } = await pool.query(
      `SELECT lo.id, lo.ma_truy_xuat, lo.san_pham_id, sp.ten AS ten_san_pham,
              lo.ngay_san_xuat, lo.han_su_dung, lo.so_luong, lo.so_luong_con,
              v.ten AS ten_vung, lo.nguoi_san_xuat,
              (SELECT count(*) FROM buoc_truy_xuat b WHERE b.lo_id = lo.id) AS so_buoc,
              count(*) OVER () AS tong
       FROM lo_san_xuat lo
       JOIN san_pham sp ON sp.id = lo.san_pham_id
       JOIN vung_nguyen_lieu v ON v.id = lo.vung_nguyen_lieu_id
       WHERE ($1::int IS NULL OR lo.san_pham_id = $1)
       ORDER BY lo.tao_luc DESC, lo.id DESC
       LIMIT $2 OFFSET $3`,
      [q.sanPhamId ?? null, p.kichThuoc, p.offset],
    );
    res.json({
      duLieu: rows.map(({ tong, ...row }) => camel(row)),
      phanTrang: { trang: p.trang, kichThuoc: p.kichThuoc, tong: rows[0]?.tong ?? 0 },
    });
  }));

  r.get('/:id', ah(async (req, res) => {
    res.json(await chiTietLo(pool, config, req, idParam(req.params.id)));
  }));

  // Tạo lô (kèm các bước nếu có) trong một transaction. Mã truy xuất do backend sinh,
  // client không được tự đặt. Số lượng còn bán ban đầu bằng số lượng của lô.
  r.post('/', ah(async (req, res) => {
    const d = validate(req.body)
      .int('sanPhamId', { required: true, min: 1 })
      .date('ngaySanXuat', { required: true })
      .date('hanSuDung', { required: true })
      .int('soLuong', { required: true, min: 1, max: 10000000 })
      .int('vungNguyenLieuId', { min: 1 })
      .string('nguoiSanXuat', { required: true, max: 120 })
      .url('anhHienTruongUrl')
      .string('ghiChu', { max: 2000 })
      .array('cacBuoc', { max: 30 })
      .done();
    if (d.hanSuDung <= d.ngaySanXuat) {
      throw badRequest('Dữ liệu không hợp lệ.', [{ truong: 'hanSuDung', thongDiep: 'Hạn sử dụng phải sau ngày sản xuất.' }]);
    }
    const cacBuoc = (d.cacBuoc || []).map((b) => kiemTraBuoc(b));
    // Gán thứ tự 1, 2, 3... nếu không gửi; không cho trùng thứ tự.
    cacBuoc.forEach((b, i) => { if (!b.thuTu) b.thuTu = i + 1; });
    if (new Set(cacBuoc.map((b) => b.thuTu)).size !== cacBuoc.length) {
      throw badRequest('Dữ liệu không hợp lệ.', [{ truong: 'cacBuoc', thongDiep: 'Thứ tự các bước bị trùng.' }]);
    }

    const tao = () => withTransaction(pool, async (client) => {
      const sp = await client.query(
        `SELECT sp.trang_thai_duyet, ncc.vung_id
         FROM san_pham sp JOIN nha_cung_cap ncc ON ncc.id = sp.nha_cung_cap_id
         WHERE sp.id = $1`,
        [d.sanPhamId],
      );
      if (!sp.rows[0]) {
        throw badRequest('Dữ liệu không hợp lệ.', [{ truong: 'sanPhamId', thongDiep: 'Sản phẩm không tồn tại.' }]);
      }
      if (sp.rows[0].trang_thai_duyet === 'TU_CHOI') {
        throw conflict('SAN_PHAM_BI_TU_CHOI', 'Sản phẩm đã bị từ chối, không thể tạo lô.');
      }
      const vungId = d.vungNguyenLieuId ?? sp.rows[0].vung_id;
      const vung = await client.query('SELECT 1 FROM vung_nguyen_lieu WHERE id = $1', [vungId]);
      if (!vung.rowCount) {
        throw badRequest('Dữ liệu không hợp lệ.', [{ truong: 'vungNguyenLieuId', thongDiep: 'Vùng không tồn tại.' }]);
      }
      const { rows } = await client.query(
        `INSERT INTO lo_san_xuat
           (san_pham_id, ma_truy_xuat, ngay_san_xuat, han_su_dung, so_luong, so_luong_con,
            vung_nguyen_lieu_id, nguoi_san_xuat, anh_hien_truong_url, ghi_chu, nguoi_tao_id)
         VALUES ($1, $2, $3, $4, $5, $5, $6, $7, $8, $9, $10) RETURNING id`,
        [d.sanPhamId, taoMaTruyXuat(), d.ngaySanXuat, d.hanSuDung, d.soLuong, vungId,
          d.nguoiSanXuat, d.anhHienTruongUrl || null, d.ghiChu || null, req.user.id],
      );
      const loId = rows[0].id;
      for (const b of cacBuoc) {
        await client.query(
          `INSERT INTO buoc_truy_xuat (lo_id, thu_tu, ten_buoc, mo_ta, thoi_diem, anh_url)
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [loId, b.thuTu, b.tenBuoc, b.moTa || null, b.thoiDiem, b.anhUrl || null],
        );
      }
      return loId;
    });

    // Xác suất trùng mã 80 bit gần như bằng 0; nếu vẫn trùng thì sinh mã khác và thử lại.
    let loId;
    for (let lan = 1; ; lan += 1) {
      try {
        loId = await tao();
        break;
      } catch (err) {
        if (err.code === '23505' && err.constraint === 'lo_san_xuat_ma_truy_xuat_key' && lan < 3) continue;
        throw err;
      }
    }
    res.status(201).json(await chiTietLo(pool, config, req, loId));
  }));

  // Thêm một bước truy xuất vào lô. Không gửi thuTu thì lấy thứ tự kế tiếp.
  r.post('/:id/buoc', ah(async (req, res) => {
    const loId = idParam(req.params.id);
    const b = kiemTraBuoc(req.body);
    const lo = await pool.query('SELECT 1 FROM lo_san_xuat WHERE id = $1', [loId]);
    if (!lo.rowCount) throw notFound('Không tìm thấy lô.');
    let rows;
    try {
      ({ rows } = await pool.query(
        `INSERT INTO buoc_truy_xuat (lo_id, thu_tu, ten_buoc, mo_ta, thoi_diem, anh_url)
         SELECT $1, COALESCE($2::smallint, COALESCE(max(thu_tu), 0) + 1), $3, $4, $5, $6
         FROM buoc_truy_xuat WHERE lo_id = $1
         RETURNING id, thu_tu, ten_buoc, mo_ta, thoi_diem, anh_url`,
        [loId, b.thuTu ?? null, b.tenBuoc, b.moTa || null, b.thoiDiem, b.anhUrl || null],
      ));
    } catch (err) {
      if (err.code === '23505') throw conflict('THU_TU_BUOC_TRUNG', 'Lô đã có bước với thứ tự này.');
      throw err;
    }
    res.status(201).json(camel(rows[0]));
  }));

  return r;
};
