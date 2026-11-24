'use strict';

const { validate } = require('../../utils/validator');
const { badRequest } = require('../../utils/errors');

// Mã truy xuất: 10 byte ngẫu nhiên -> 20 ký tự hex in hoa (80 bit), khớp CHECK trong schema.sql.
const MA_TRUY_XUAT_SO_BYTE = 10;
const MA_TRUY_XUAT_REGEX = /^[0-9A-F]{20}$/;

// Chuẩn hóa mã người dùng quét/gõ; trả null nếu sai định dạng.
function chuanHoaMa(raw) {
  const ma = String(raw).trim().toUpperCase();
  return MA_TRUY_XUAT_REGEX.test(ma) ? ma : null;
}

function parseBuoc(item) {
  return validate(item)
    .int('thuTu', { min: 1, max: 100 })
    .string('tenBuoc', { required: true, max: 120 })
    .string('moTa', { max: 2000 })
    .datetime('thoiDiem', { required: true })
    .url('anhUrl')
    .done();
}

// Body tạo lô. Không nhận maTruyXuat: mã do server sinh.
function parseTaoLo(body) {
  const d = validate(body)
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
  const cacBuoc = (d.cacBuoc || []).map(parseBuoc);
  // Gán thứ tự 1, 2, 3... nếu không gửi; không cho trùng thứ tự.
  cacBuoc.forEach((b, i) => { if (!b.thuTu) b.thuTu = i + 1; });
  if (new Set(cacBuoc.map((b) => b.thuTu)).size !== cacBuoc.length) {
    throw badRequest('Dữ liệu không hợp lệ.', [{ truong: 'cacBuoc', thongDiep: 'Thứ tự các bước bị trùng.' }]);
  }
  return { ...d, cacBuoc };
}

const parseLocLo = (query) => validate(query).int('sanPhamId', { min: 1 }).done();

// Escape ký tự đặc biệt HTML để tránh XSS khi dựng trang truy xuất.
function escapeHtml(value) {
  if (value === null || value === undefined) return '';
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function anhAnToan(url, alt) {
  if (typeof url !== 'string' || !/^https?:\/\//i.test(url.trim())) return '';
  return `<img class="media-img" src="${escapeHtml(url.trim())}" alt="${escapeHtml(alt)}" loading="lazy">`;
}

function dongThongTin(nhan, giaTri) {
  if (giaTri === null || giaTri === undefined || giaTri === '') return '';
  return `<div class="row"><span class="label">${escapeHtml(nhan)}</span><span class="val">${escapeHtml(giaTri)}</span></div>`;
}

function khungTrangHtml(tieuDe, noiDung) {
  return `<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escapeHtml(tieuDe)}</title>
<style>
  :root{--bg:#f4f7f2;--card:#fff;--primary:#1f6f43;--primary-soft:#e8f5ee;--danger:#b42318;--danger-soft:#fef3f2;--text:#18221d;--muted:#5a6b61;--border:#dde5df}
  *{box-sizing:border-box}
  body{margin:0;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;background:var(--bg);color:var(--text);line-height:1.5;padding:16px}
  .wrap{max-width:680px;margin:0 auto;display:grid;gap:14px}
  .card{background:var(--card);border:1px solid var(--border);border-radius:14px;padding:16px;box-shadow:0 2px 8px rgba(16,32,22,.04)}
  .badge{display:inline-block;padding:4px 10px;border-radius:999px;font-size:13px;font-weight:600;background:var(--primary-soft);color:var(--primary)}
  .badge-err{background:var(--danger-soft);color:var(--danger)}
  h1{font-size:20px;margin:10px 0 4px}
  h2{font-size:16px;margin:0 0 10px;color:var(--primary)}
  .code{font-family:ui-monospace,SFMono-Regular,Consolas,monospace;font-size:13px;color:var(--muted);word-break:break-all}
  .media-img{width:100%;max-height:260px;object-fit:cover;border-radius:10px;margin-top:10px;border:1px solid var(--border)}
  .row{display:flex;justify-content:space-between;gap:12px;padding:6px 0;border-bottom:1px dashed var(--border);font-size:14px}
  .row:last-child{border-bottom:none}
  .label{color:var(--muted);flex-shrink:0}
  .val{text-align:right;font-weight:500}
  .desc{margin:8px 0 0;font-size:14px;color:var(--text)}
  .steps{list-style:none;padding:0;margin:0;display:grid;gap:12px}
  .step{border-left:3px solid var(--primary);padding-left:12px}
  .step-title{font-weight:600;font-size:15px}
  .step-time{font-size:12px;color:var(--muted)}
  .cert{padding:8px 10px;background:var(--bg);border-radius:8px;margin-top:8px;font-size:13px}
</style>
</head>
<body><main class="wrap">${noiDung}</main></body>
</html>`;
}

function renderTruyXuatHtml(d) {
  const sp = d.sanPham || {};
  const lo = d.lo || {};
  const vung = lo.vungNguyenLieu || {};
  const ncc = d.nhaCungCap || {};
  const chungNhan = Array.isArray(ncc.chungNhan) ? ncc.chungNhan : [];
  const cacBuoc = Array.isArray(d.cacBuoc) ? d.cacBuoc : [];

  const sao = sp.hangSao ? `${sp.hangSao} sao OCOP` : '';
  const cnHtml = chungNhan.length
    ? chungNhan.map((c) => `<div class="cert"><strong>${escapeHtml(c.loai || 'Chứng nhận')}</strong>${c.soHieu ? ` · Số: ${escapeHtml(c.soHieu)}` : ''}${c.ngayHetHan ? ` · HSD: ${escapeHtml(c.ngayHetHan)}` : ''}</div>`).join('')
    : '<p class="desc">Chưa có thông tin chứng nhận.</p>';

  const buocHtml = cacBuoc.length
    ? `<ol class="steps">${cacBuoc.map((b) => `<li class="step"><div class="step-title">Bước ${escapeHtml(b.thuTu)}: ${escapeHtml(b.tenBuoc)}</div><div class="step-time">${escapeHtml(b.thoiDiem)}</div>${b.moTa ? `<p class="desc">${escapeHtml(b.moTa)}</p>` : ''}${anhAnToan(b.anhUrl, b.tenBuoc || 'Ảnh bước truy xuất')}</li>`).join('')}</ol>`
    : '<p class="desc">Chưa có bước truy xuất nào được ghi nhận.</p>';

  const noiDung = `
    <section class="card">
      <span class="badge">Đã xác minh nguồn gốc OCOP</span>
      <h1>${escapeHtml(sp.ten || 'Sản phẩm OCOP')}</h1>
      <div class="code">Mã lô: ${escapeHtml(d.maTruyXuat)}</div>
      ${anhAnToan(sp.anhUrl, sp.ten || 'Ảnh sản phẩm')}
      ${dongThongTin('Hạng sao', sao)}
      ${dongThongTin('Đơn vị tính', sp.donViTinh)}
      ${sp.moTa ? `<p class="desc">${escapeHtml(sp.moTa)}</p>` : ''}
    </section>
    <section class="card">
      <h2>Thông tin lô sản xuất</h2>
      ${dongThongTin('Ngày sản xuất', lo.ngaySanXuat)}
      ${dongThongTin('Hạn sử dụng', lo.hanSuDung)}
      ${dongThongTin('Người sản xuất', lo.nguoiSanXuat)}
      ${dongThongTin('Vùng nguyên liệu', vung.ten)}
      ${vung.moTa ? `<p class="desc">${escapeHtml(vung.moTa)}</p>` : ''}
      ${anhAnToan(lo.anhHienTruongUrl, 'Ảnh hiện trường lô')}
    </section>
    <section class="card">
      <h2>Nhà cung cấp &amp; Chứng nhận</h2>
      ${dongThongTin('Đơn vị cung cấp', ncc.ten)}
      ${dongThongTin('Địa chỉ', ncc.diaChi)}
      ${dongThongTin('Vùng', ncc.vung)}
      ${anhAnToan(ncc.anhCoSoUrl, ncc.ten || 'Ảnh cơ sở sản xuất')}
      ${cnHtml}
    </section>
    <section class="card">
      <h2>Hành trình truy xuất (${cacBuoc.length} bước)</h2>
      ${buocHtml}
    </section>`;

  return khungTrangHtml(`${sp.ten || 'Truy xuất nguồn gốc'} - OCOP Gugugaga`, noiDung);
}

function renderKhongXacMinhHtml(maRaw) {
  const noiDung = `
    <section class="card">
      <span class="badge badge-err">Không xác minh được nguồn gốc</span>
      <h1>Không tìm thấy thông tin lô hàng</h1>
      <p class="desc">Mã truy xuất <strong>${escapeHtml(maRaw)}</strong> không hợp lệ, không tồn tại hoặc sản phẩm/nhà cung cấp hiện không còn được công bố.</p>
      <p class="desc">Vui lòng kiểm tra lại mã QR trên bao bì hoặc liên hệ đơn vị phân phối.</p>
    </section>`;
  return khungTrangHtml('Không xác minh được nguồn gốc - OCOP Gugugaga', noiDung);
}

module.exports = {
  MA_TRUY_XUAT_SO_BYTE,
  MA_TRUY_XUAT_REGEX,
  chuanHoaMa,
  parseBuoc,
  parseTaoLo,
  parseLocLo,
  escapeHtml,
  renderTruyXuatHtml,
  renderKhongXacMinhHtml,
};
