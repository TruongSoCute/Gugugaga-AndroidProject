'use strict';

const { camel } = require('../../utils/sql');

const SP_CONG_BO = "sp.trang_thai_duyet = 'DA_DUYET' AND ncc.trang_thai_duyet = 'DA_DUYET'";

async function sanPhamCongBo(q, id) {
  const { rowCount } = await q.query(
    `SELECT 1 FROM san_pham sp JOIN nha_cung_cap ncc ON ncc.id = sp.nha_cung_cap_id WHERE sp.id = $1 AND ${SP_CONG_BO}`,
    [id],
  );
  return rowCount > 0;
}

async function nhaCungCapDaDuyet(q, id) {
  const { rowCount } = await q.query("SELECT 1 FROM nha_cung_cap WHERE id = $1 AND trang_thai_duyet = 'DA_DUYET'", [id]);
  return rowCount > 0;
}

// Chỉ trả sản phẩm còn đang bán (bị thu hồi duyệt thì ẩn khỏi danh sách yêu thích).
async function dsYeuThich(q, nguoiDungId) {
  const { rows } = await q.query(
    `SELECT sp.id, sp.ten, sp.gia, sp.don_vi_tinh, sp.hang_sao, sp.anh_url,
            ncc.id AS nha_cung_cap_id, ncc.ten AS ten_nha_cung_cap, yt.tao_luc
     FROM yeu_thich yt
     JOIN san_pham sp ON sp.id = yt.san_pham_id
     JOIN nha_cung_cap ncc ON ncc.id = sp.nha_cung_cap_id
     WHERE yt.nguoi_dung_id = $1 AND ${SP_CONG_BO}
     ORDER BY yt.tao_luc DESC, sp.id`,
    [nguoiDungId],
  );
  return rows.map(camel);
}

async function themYeuThich(q, nguoiDungId, sanPhamId) {
  await q.query(
    'INSERT INTO yeu_thich (nguoi_dung_id, san_pham_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
    [nguoiDungId, sanPhamId],
  );
}

async function boYeuThich(q, nguoiDungId, sanPhamId) {
  await q.query('DELETE FROM yeu_thich WHERE nguoi_dung_id = $1 AND san_pham_id = $2', [nguoiDungId, sanPhamId]);
}

async function dsTheoDoi(q, nguoiDungId) {
  const { rows } = await q.query(
    `SELECT ncc.id, ncc.ten, ncc.dia_chi, ncc.anh_co_so_url, v.ten AS ten_vung, td.tao_luc,
            (SELECT count(*) FROM san_pham sp WHERE sp.nha_cung_cap_id = ncc.id AND sp.trang_thai_duyet = 'DA_DUYET') AS so_san_pham
     FROM theo_doi_nha_cung_cap td
     JOIN nha_cung_cap ncc ON ncc.id = td.nha_cung_cap_id
     JOIN vung_nguyen_lieu v ON v.id = ncc.vung_id
     WHERE td.nguoi_dung_id = $1 AND ncc.trang_thai_duyet = 'DA_DUYET'
     ORDER BY td.tao_luc DESC, ncc.id`,
    [nguoiDungId],
  );
  return rows.map(camel);
}

async function themTheoDoi(q, nguoiDungId, nccId) {
  await q.query(
    'INSERT INTO theo_doi_nha_cung_cap (nguoi_dung_id, nha_cung_cap_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
    [nguoiDungId, nccId],
  );
}

async function boTheoDoi(q, nguoiDungId, nccId) {
  await q.query('DELETE FROM theo_doi_nha_cung_cap WHERE nguoi_dung_id = $1 AND nha_cung_cap_id = $2', [nguoiDungId, nccId]);
}

module.exports = {
  sanPhamCongBo, nhaCungCapDaDuyet, dsYeuThich, themYeuThich, boYeuThich, dsTheoDoi, themTheoDoi, boTheoDoi,
};
