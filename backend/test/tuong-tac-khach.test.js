'use strict';

// Đánh giá kèm ảnh, phản ánh hàng giả/sai mô tả, yêu thích, theo dõi nhà cung cấp, tải ảnh lên.
const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { setup } = require('./helpers');

// Kho ảnh giả: ghi lại các tệp được "tải lên" thay cho Supabase Storage.
const daTai = [];
const khoGia = {
  daCauHinh: true,
  async taiLen(duongDan, buffer, contentType) {
    daTai.push({ duongDan, kichThuoc: buffer.length, contentType });
    return `https://kho.example/public/${duongDan}`;
  },
};
const PNG = Buffer.concat([Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), Buffer.alloc(32)]);

let t;
let nhanVien;
let khach1; // id 3
let khach2; // id 4
let ncc1;
const s = {};

before(async () => {
  t = await setup({ storage: khoGia });
  nhanVien = await t.login('nhanvien@ocop.example');
  khach1 = await t.login('khach1@ocop.example');
  khach2 = await t.login('khach2@ocop.example');
  ncc1 = await t.login('ncc1@ocop.example');
  // Một dòng đơn DA_NHAN của khách 1 chưa được đánh giá.
  s.dongChuaDanhGia = (await t.pool.query(
    `SELECT c.don_hang_id, c.san_pham_id FROM chi_tiet_don c JOIN don_hang dh ON dh.id = c.don_hang_id
     WHERE dh.khach_id = 3 AND dh.trang_thai = 'DA_NHAN'
       AND NOT EXISTS (SELECT 1 FROM danh_gia dg WHERE dg.don_hang_id = c.don_hang_id AND dg.san_pham_id = c.san_pham_id)
     ORDER BY c.id LIMIT 1`,
  )).rows[0];
  s.donChuaNhan = (await t.pool.query(
    `SELECT c.don_hang_id, c.san_pham_id FROM chi_tiet_don c JOIN don_hang dh ON dh.id = c.don_hang_id
     WHERE dh.khach_id = 3 AND dh.trang_thai <> 'DA_NHAN' ORDER BY c.id LIMIT 1`,
  )).rows[0];
});
after(async () => { await t.teardown(); });

// ---------------------------------------------------------------- Tải ảnh
test('Tải ảnh: cần đăng nhập; chỉ nhận ảnh thật; tên tệp do máy chủ đặt', async () => {
  assert.equal((await t.api('POST', '/tai-len/anh', { body: PNG, headers: { 'content-type': 'image/png' } })).status, 401);
  const r = await t.api('POST', '/tai-len/anh?mucDich=danh-gia', { token: khach1, body: PNG, headers: { 'content-type': 'image/png' } });
  assert.equal(r.status, 201, JSON.stringify(r.body));
  assert.match(r.body.url, /^https:\/\/kho\.example\/public\/danh-gia\/3-[0-9a-f]{24}\.png$/);
  assert.equal(daTai.at(-1).contentType, 'image/png');
  s.anhUrl = r.body.url;

  // Khai báo là ảnh nhưng nội dung không phải ảnh -> 415.
  const gia = await t.api('POST', '/tai-len/anh', { token: khach1, body: Buffer.from('<?php echo 1; ?>xxxxxxxx'), headers: { 'content-type': 'image/jpeg' } });
  assert.equal(gia.status, 415);
  // Loại nội dung không phải ảnh -> 415.
  assert.equal((await t.api('POST', '/tai-len/anh', { token: khach1, body: { a: 1 } })).status, 415);
});

test('Tải ảnh khi máy chủ chưa cấu hình kho ảnh trả 503', async () => {
  const t2 = await setup();
  try {
    const tk = await t2.login('khach1@ocop.example');
    const r = await t2.api('POST', '/tai-len/anh', { token: tk, body: PNG, headers: { 'content-type': 'image/png' } });
    assert.equal(r.status, 503);
    assert.equal(r.body.loi.ma, 'CHUA_CAU_HINH_LUU_ANH');
  } finally {
    await t2.teardown();
  }
});

// ---------------------------------------------------------------- Đánh giá
test('Đánh giá: chỉ khách, chỉ đơn của mình đã nhận, sản phẩm có trong đơn', async () => {
  const { don_hang_id: donHangId, san_pham_id: sanPhamId } = s.dongChuaDanhGia;
  const body = { donHangId, sanPhamId, soSao: 5, noiDung: 'Rất ngon', anhUrls: [s.anhUrl] };
  assert.equal((await t.api('POST', '/danh-gia', { body })).status, 401);
  assert.equal((await t.api('POST', '/danh-gia', { token: nhanVien, body })).status, 403);
  assert.equal((await t.api('POST', '/danh-gia', { token: khach2, body })).status, 404); // đơn của khách 1
  assert.equal((await t.api('POST', '/danh-gia', { token: khach1, body: { ...body, soSao: 6 } })).status, 400);
  assert.equal((await t.api('POST', '/danh-gia', { token: khach1, body: { ...body, anhUrls: ['javascript:alert(1)'] } })).status, 400);
  const khongCo = await t.api('POST', '/danh-gia', { token: khach1, body: { ...body, sanPhamId: 45 } });
  assert.equal(khongCo.status, 400);
  const chuaNhan = await t.api('POST', '/danh-gia', {
    token: khach1, body: { ...body, donHangId: s.donChuaNhan.don_hang_id, sanPhamId: s.donChuaNhan.san_pham_id },
  });
  assert.equal(chuaNhan.status, 409);
  assert.equal(chuaNhan.body.loi.ma, 'DON_CHUA_NHAN');
});

test('Đánh giá thành công kèm ảnh; đánh giá lại 409; xuất hiện công khai và trong chi tiết đơn', async () => {
  const { don_hang_id: donHangId, san_pham_id: sanPhamId } = s.dongChuaDanhGia;
  const r = await t.api('POST', '/danh-gia', { token: khach1, body: { donHangId, sanPhamId, soSao: 5, noiDung: 'Rất ngon', anhUrls: [s.anhUrl] } });
  assert.equal(r.status, 201, JSON.stringify(r.body));
  assert.deepEqual(r.body.anh, [s.anhUrl]);
  assert.equal(r.body.tenNguoiDanhGia, 'Khách mẫu 1');
  assert.ok(!('email' in r.body));

  const lai = await t.api('POST', '/danh-gia', { token: khach1, body: { donHangId, sanPhamId, soSao: 1 } });
  assert.equal(lai.status, 409);
  assert.equal(lai.body.loi.ma, 'DA_DANH_GIA');

  const ds = await t.api('GET', `/danh-gia?sanPhamId=${sanPhamId}`);
  assert.equal(ds.status, 200);
  assert.equal(ds.body.duLieu[0].id, r.body.id);
  assert.ok(ds.body.tongHop.soDanhGia >= 1);
  assert.equal((await t.api('GET', '/danh-gia')).status, 400);

  const don = await t.api('GET', `/don-hang/${donHangId}`, { token: khach1 });
  assert.equal(don.body.chiTiet.find((c) => c.sanPhamId === sanPhamId).daDanhGia, true);
});

// ---------------------------------------------------------------- Phản ánh
test('Phản ánh: gắn đúng lô theo mã; mã lô của sản phẩm khác bị từ chối', async () => {
  const lo = (await t.pool.query('SELECT ma_truy_xuat, san_pham_id FROM lo_san_xuat ORDER BY id LIMIT 2')).rows;
  const body = { sanPhamId: lo[0].san_pham_id, maTruyXuat: lo[0].ma_truy_xuat.toLowerCase(), loai: 'HANG_GIA', noiDung: 'Tem QR bị dán đè' };
  assert.equal((await t.api('POST', '/bao-cao-vi-pham', { token: nhanVien, body })).status, 403);
  assert.equal((await t.api('POST', '/bao-cao-vi-pham', { token: khach2, body: { ...body, loai: 'LUNG_TUNG' } })).status, 400);
  const sai = await t.api('POST', '/bao-cao-vi-pham', { token: khach2, body: { ...body, maTruyXuat: lo[1].ma_truy_xuat } });
  assert.equal(sai.status, 400);

  const r = await t.api('POST', '/bao-cao-vi-pham', { token: khach2, body: { ...body, trangThai: 'DA_XU_LY' } });
  assert.equal(r.status, 201, JSON.stringify(r.body));
  assert.equal(r.body.trangThai, 'MOI');
  assert.equal(r.body.maTruyXuat, lo[0].ma_truy_xuat);
  assert.ok(!('emailNguoiBao' in r.body));
  s.phanAnhId = r.body.id;
});

test('Phản ánh: khách chỉ xem của mình; nhân sự xem tất cả và xử lý theo thứ tự', async () => {
  assert.equal((await t.api('GET', `/bao-cao-vi-pham/${s.phanAnhId}`, { token: khach1 })).status, 404);
  const ds2 = await t.api('GET', '/bao-cao-vi-pham', { token: khach2 });
  assert.ok(ds2.body.duLieu.every((x) => x.nguoiBaoId === 4));
  assert.equal((await t.api('GET', '/quan-tri/bao-cao-vi-pham', { token: khach2 })).status, 403);

  const ds = await t.api('GET', '/quan-tri/bao-cao-vi-pham?trangThai=MOI', { token: nhanVien });
  assert.ok(ds.body.duLieu.some((x) => x.id === s.phanAnhId));
  const url = `/quan-tri/bao-cao-vi-pham/${s.phanAnhId}`;
  assert.equal((await t.api('GET', url, { token: nhanVien })).body.emailNguoiBao, 'khach2@ocop.example');
  assert.equal((await t.api('PATCH', url, { token: nhanVien, body: { trangThai: 'DA_XU_LY' } })).status, 400); // thiếu kết quả
  assert.equal((await t.api('PATCH', url, { token: nhanVien, body: { trangThai: 'DANG_XU_LY' } })).status, 200);
  const xong = await t.api('PATCH', url, { token: nhanVien, body: { trangThai: 'DA_XU_LY', ketQuaXuLy: 'Đã yêu cầu nhà cung cấp thu hồi lô.' } });
  assert.equal(xong.status, 200);
  assert.equal(xong.body.tenNguoiXuLy, 'Nhân viên mẫu');
  assert.ok(xong.body.xuLyLuc);
  // Đã kết thúc thì không mở lại được.
  assert.equal((await t.api('PATCH', url, { token: nhanVien, body: { trangThai: 'DANG_XU_LY' } })).status, 409);
});

// ---------------------------------------------------------------- Yêu thích, theo dõi
test('Yêu thích: thêm/bỏ không lỗi khi gọi lại; sản phẩm chưa duyệt 404; chỉ khách', async () => {
  assert.equal((await t.api('GET', '/yeu-thich', { token: ncc1 })).status, 403);
  assert.equal((await t.api('PUT', '/yeu-thich/45', { token: khach2 })).status, 404);
  assert.equal((await t.api('PUT', '/yeu-thich/2', { token: khach2 })).status, 200);
  assert.equal((await t.api('PUT', '/yeu-thich/2', { token: khach2 })).status, 200);
  let ds = await t.api('GET', '/yeu-thich', { token: khach2 });
  assert.equal(ds.body.filter((x) => x.id === 2).length, 1);
  assert.equal((await t.api('DELETE', '/yeu-thich/2', { token: khach2 })).body.yeuThich, false);
  ds = await t.api('GET', '/yeu-thich', { token: khach2 });
  assert.ok(!ds.body.some((x) => x.id === 2));
});

test('Theo dõi nhà cung cấp: chỉ nhà cung cấp đã duyệt; số người theo dõi tăng', async () => {
  const truoc = (await t.api('GET', '/nha-cung-cap/9')).body.soNguoiTheoDoi;
  assert.equal((await t.api('PUT', '/theo-doi/11', { token: khach2 })).status, 404); // chờ duyệt
  assert.equal((await t.api('PUT', '/theo-doi/9', { token: khach2 })).status, 200);
  assert.equal((await t.api('GET', '/nha-cung-cap/9')).body.soNguoiTheoDoi, truoc + 1);
  assert.ok((await t.api('GET', '/theo-doi', { token: khach2 })).body.some((x) => x.id === 9));
  await t.api('DELETE', '/theo-doi/9', { token: khach2 });
  assert.equal((await t.api('GET', '/nha-cung-cap/9')).body.soNguoiTheoDoi, truoc);
});
