'use strict';

// Giỏ hàng và đơn hàng: tính tiền ở backend, gán lô FIFO, trừ/hoàn tồn trong transaction,
// không bán vượt tồn khi đặt đồng thời, quyền xem đơn và quy tắc chuyển trạng thái.
const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { setup } = require('./helpers');

let t;
let nhanVien;
let khach2; // id 4
let khach5; // id 7, giỏ trống trong seed
const s = {};

const NGUOI_NHAN = {
  tenNguoiNhan: 'Khách thử nghiệm', sdtNguoiNhan: '0912 345 678', diaChiGiao: '1 Võ Văn Ngân, TP. Thủ Đức',
};

const tonLo = async (loId) => (await t.pool.query('SELECT so_luong_con FROM lo_san_xuat WHERE id = $1', [loId])).rows[0].so_luong_con;
const tongTon = async (spId) => (await t.pool.query(
  'SELECT COALESCE(sum(so_luong_con), 0)::int n FROM lo_san_xuat WHERE san_pham_id = $1', [spId],
)).rows[0].n;
const soDon = async () => (await t.pool.query('SELECT count(*)::int n FROM don_hang')).rows[0].n;

// Các sản phẩm đang bán có ít nhất 2 lô, xếp theo id.
async function sanPhamCoNhieuLo() {
  const { rows } = await t.pool.query(
    `SELECT sp.id, sp.gia FROM san_pham sp JOIN nha_cung_cap ncc ON ncc.id = sp.nha_cung_cap_id
     WHERE sp.trang_thai_duyet = 'DA_DUYET' AND ncc.trang_thai_duyet = 'DA_DUYET'
       AND (SELECT count(*) FROM lo_san_xuat lo WHERE lo.san_pham_id = sp.id) >= 2
     ORDER BY sp.id`,
  );
  return rows;
}

async function loCua(spId) {
  const { rows } = await t.pool.query(
    'SELECT id, so_luong FROM lo_san_xuat WHERE san_pham_id = $1 ORDER BY ngay_san_xuat, id', [spId],
  );
  return rows;
}

before(async () => {
  t = await setup();
  nhanVien = await t.login('nhanvien@ocop.example');
  khach2 = await t.login('khach2@ocop.example');
  khach5 = await t.login('khach5@ocop.example');
  s.sp = await sanPhamCoNhieuLo();
});
after(async () => { await t.teardown(); });

test('Hình thức giao và phí giao là công khai', async () => {
  const r = await t.api('GET', '/don-hang/hinh-thuc-giao');
  assert.equal(r.status, 200);
  assert.deepEqual(r.body.map((x) => [x.ma, x.phiGiao]), [['TIEU_CHUAN', 30000], ['NHANH', 50000], ['NHAN_TAI_CHO', 0]]);
});

test('Giỏ hàng: không token 401, nhân sự 403', async () => {
  assert.equal((await t.api('GET', '/gio-hang')).status, 401);
  assert.equal((await t.api('GET', '/gio-hang', { token: nhanVien })).status, 403);
  assert.equal((await t.api('POST', '/don-hang', { token: nhanVien, body: {} })).status, 403);
});

test('Giỏ hàng: dữ liệu sai 400, sản phẩm chưa duyệt hoặc bị từ chối 404', async () => {
  assert.equal((await t.api('PUT', '/gio-hang/1', { token: khach5, body: { soLuong: 0 } })).status, 400);
  assert.equal((await t.api('PUT', '/gio-hang/1', { token: khach5, body: { soLuong: 'hai' } })).status, 400);
  assert.equal((await t.api('PUT', '/gio-hang/abc', { token: khach5, body: { soLuong: 1 } })).status, 400);
  const { rows } = await t.pool.query("SELECT id FROM san_pham WHERE trang_thai_duyet <> 'DA_DUYET' ORDER BY id");
  for (const { id } of rows.slice(0, 2)) {
    assert.equal((await t.api('PUT', `/gio-hang/${id}`, { token: khach5, body: { soLuong: 1 } })).status, 404);
  }
});

test('Giỏ hàng: thêm, đặt lại số lượng, xóa; tạm tính theo giá trong CSDL', async () => {
  const [a, b] = s.sp;
  let r = await t.api('PUT', `/gio-hang/${a.id}`, { token: khach5, body: { soLuong: 2 } });
  assert.equal(r.status, 200, JSON.stringify(r.body));
  r = await t.api('PUT', `/gio-hang/${a.id}`, { token: khach5, body: { soLuong: 3, gia: 1 } });
  r = await t.api('PUT', `/gio-hang/${b.id}`, { token: khach5, body: { soLuong: 1 } });
  assert.equal(r.body.duLieu.length, 2);
  assert.equal(r.body.duLieu.find((x) => x.sanPhamId === a.id).soLuong, 3);
  assert.equal(r.body.tamTinh, 3 * a.gia + b.gia);
  assert.ok(r.body.duLieu.every((x) => x.dangBan && x.conHang > 0));

  r = await t.api('PUT', `/gio-hang/${b.id}`, { token: khach5, body: { soLuong: 2 } });
  assert.equal(r.body.tamTinh, 3 * a.gia + 2 * b.gia);
  // Giỏ của khách khác không bị ảnh hưởng.
  const gio2 = await t.api('GET', '/gio-hang', { token: khach2 });
  assert.ok(!gio2.body.duLieu.some((x) => x.sanPhamId === a.id && x.soLuong === 3));

  assert.equal((await t.api('DELETE', '/gio-hang/9999', { token: khach5 })).status, 404);
});

test('Đặt đơn từ giỏ: backend tính giá, phí giao, tổng; trừ tồn; xóa giỏ', async () => {
  const [a, b] = s.sp;
  const tonTruoc = { a: await tongTon(a.id), b: await tongTon(b.id) };
  const r = await t.api('POST', '/don-hang', {
    token: khach5,
    body: { hinhThucGiao: 'NHANH', ...NGUOI_NHAN, tongTien: 1, phiGiao: 0, trangThai: 'DA_GIAO' },
  });
  assert.equal(r.status, 201, JSON.stringify(r.body));
  const d = r.body;
  assert.equal(d.trangThai, 'CHO_XAC_NHAN');
  assert.equal(d.phiGiao, 50000);
  assert.equal(d.tienHang, 3 * a.gia + 2 * b.gia);
  assert.equal(d.tongTien, d.tienHang + 50000);
  assert.equal(d.sdtNguoiNhan, '0912345678');
  assert.equal(d.lichSu.length, 1);
  assert.equal(d.lichSu[0].trangThai, 'CHO_XAC_NHAN');
  // Mỗi dòng ghi lô thực tế, kèm mã truy xuất để khách tra nguồn gốc hàng đã mua.
  for (const ct of d.chiTiet) assert.match(ct.maTruyXuat, /^[0-9A-F]{20}$/);
  assert.equal(await tongTon(a.id), tonTruoc.a - 3);
  assert.equal(await tongTon(b.id), tonTruoc.b - 2);
  assert.equal((await t.api('GET', '/gio-hang', { token: khach5 })).body.duLieu.length, 0);
  s.donKhach5 = d.id;
});

test('Giỏ trống hoặc dữ liệu đặt hàng sai trả 400', async () => {
  let r = await t.api('POST', '/don-hang', { token: khach5, body: { hinhThucGiao: 'NHANH', ...NGUOI_NHAN } });
  assert.equal(r.status, 400);
  r = await t.api('POST', '/don-hang', {
    token: khach5,
    body: { hinhThucGiao: 'BAY', sdtNguoiNhan: 'abc', cacDong: [{ sanPhamId: 1, soLuong: -1 }] },
  });
  assert.equal(r.status, 400);
  const truong = r.body.loi.chiTiet.map((x) => x.truong);
  for (const f of ['hinhThucGiao', 'tenNguoiNhan', 'sdtNguoiNhan', 'diaChiGiao']) assert.ok(truong.includes(f), f);
  r = await t.api('POST', '/don-hang', {
    token: khach5, body: { hinhThucGiao: 'NHANH', ...NGUOI_NHAN, cacDong: [{ sanPhamId: 1, soLuong: 0 }] },
  });
  assert.equal(r.status, 400);
  assert.equal(r.body.loi.chiTiet[0].truong, 'cacDong[0].soLuong');
});

test('Gán lô FIFO: lô sản xuất trước bán trước, thiếu thì chia sang lô kế tiếp', async () => {
  const sp = s.sp[2];
  const [lo1, lo2] = await loCua(sp.id);
  await t.pool.query('UPDATE lo_san_xuat SET so_luong_con = 2 WHERE id = $1', [lo1.id]);
  const ton2 = await tonLo(lo2.id);

  const r = await t.api('POST', '/don-hang', {
    token: khach2, body: { hinhThucGiao: 'TIEU_CHUAN', ...NGUOI_NHAN, cacDong: [{ sanPhamId: sp.id, soLuong: 5 }] },
  });
  assert.equal(r.status, 201, JSON.stringify(r.body));
  assert.deepEqual(r.body.chiTiet.map((c) => [c.loId, c.soLuong]), [[lo1.id, 2], [lo2.id, 3]]);
  assert.ok(r.body.chiTiet.every((c) => c.donGia === sp.gia));
  assert.equal(r.body.tienHang, 5 * sp.gia);
  assert.equal(await tonLo(lo1.id), 0);
  assert.equal(await tonLo(lo2.id), ton2 - 3);
  s.donFifo = { id: r.body.id, lo1: lo1.id, lo2: lo2.id, ton2 };
});

test('Không đủ hàng trả 409 và không lưu gì (rollback)', async () => {
  const [a, b] = s.sp;
  const truoc = { don: await soDon(), a: await tongTon(a.id), b: await tongTon(b.id) };
  const r = await t.api('POST', '/don-hang', {
    token: khach2,
    body: {
      hinhThucGiao: 'TIEU_CHUAN', ...NGUOI_NHAN,
      cacDong: [{ sanPhamId: a.id, soLuong: 1 }, { sanPhamId: b.id, soLuong: truoc.b + 1 }],
    },
  });
  assert.equal(r.status, 409);
  assert.equal(r.body.loi.ma, 'KHONG_DU_HANG');
  assert.equal(r.body.loi.chiTiet[0].conLai, truoc.b);
  assert.equal(await soDon(), truoc.don);
  assert.equal(await tongTon(a.id), truoc.a);
  assert.equal(await tongTon(b.id), truoc.b);
});

test('Lô hết hạn sử dụng không được bán', async () => {
  const sp = s.sp[3];
  await t.pool.query(
    "UPDATE lo_san_xuat SET ngay_san_xuat = '2020-01-01', han_su_dung = '2020-06-01' WHERE san_pham_id = $1", [sp.id],
  );
  const r = await t.api('POST', '/don-hang', {
    token: khach2, body: { hinhThucGiao: 'NHANH', ...NGUOI_NHAN, cacDong: [{ sanPhamId: sp.id, soLuong: 1 }] },
  });
  assert.equal(r.status, 409);
  assert.equal(r.body.loi.chiTiet[0].conLai, 0);
});

test('Sản phẩm không còn bán (chưa duyệt) trả 409', async () => {
  const { rows } = await t.pool.query("SELECT id FROM san_pham WHERE trang_thai_duyet = 'CHO_DUYET' LIMIT 1");
  const r = await t.api('POST', '/don-hang', {
    token: khach2, body: { hinhThucGiao: 'NHANH', ...NGUOI_NHAN, cacDong: [{ sanPhamId: rows[0].id, soLuong: 1 }] },
  });
  assert.equal(r.status, 409);
  assert.equal(r.body.loi.ma, 'SAN_PHAM_KHONG_CON_BAN');
});

test('Hai khách đặt cùng lúc phần hàng cuối không bị bán vượt tồn', async () => {
  const sp = s.sp[4];
  const lo = await loCua(sp.id);
  await t.pool.query('UPDATE lo_san_xuat SET so_luong_con = 0 WHERE san_pham_id = $1', [sp.id]);
  await t.pool.query('UPDATE lo_san_xuat SET so_luong_con = 3 WHERE id = $1', [lo[0].id]);
  const body = { hinhThucGiao: 'NHANH', ...NGUOI_NHAN, cacDong: [{ sanPhamId: sp.id, soLuong: 2 }] };
  const kq = await Promise.all([
    t.api('POST', '/don-hang', { token: khach2, body }),
    t.api('POST', '/don-hang', { token: khach5, body }),
  ]);
  assert.deepEqual(kq.map((r) => r.status).sort(), [201, 409]);
  assert.equal(await tonLo(lo[0].id), 1);
});

test('Khách chỉ xem được đơn của mình; nhân sự xem mọi đơn', async () => {
  assert.equal((await t.api('GET', `/don-hang/${s.donKhach5}`, { token: khach2 })).status, 404);
  assert.equal((await t.api('GET', `/don-hang/${s.donKhach5}`, { token: khach5 })).status, 200);
  assert.equal((await t.api('GET', `/don-hang/${s.donKhach5}`)).status, 401);

  const ds2 = await t.api('GET', '/don-hang?kichThuoc=100', { token: khach2 });
  assert.equal(ds2.status, 200);
  assert.ok(ds2.body.duLieu.length > 0);
  assert.ok(ds2.body.duLieu.every((d) => d.khachId === 4));

  const nv = await t.api('GET', `/don-hang/${s.donKhach5}`, { token: nhanVien });
  assert.equal(nv.status, 200);
  assert.equal(nv.body.emailKhach, 'khach5@ocop.example');

  const dsQt = await t.api('GET', '/quan-tri/don-hang?trangThai=CHO_XAC_NHAN&kichThuoc=100', { token: nhanVien });
  assert.equal(dsQt.status, 200);
  assert.ok(dsQt.body.duLieu.some((d) => d.id === s.donKhach5));
  assert.ok(dsQt.body.duLieu.every((d) => d.trangThai === 'CHO_XAC_NHAN'));
  assert.equal((await t.api('GET', '/quan-tri/don-hang', { token: khach5 })).status, 403);
  assert.equal((await t.api('GET', '/quan-tri/don-hang?trangThai=XYZ', { token: nhanVien })).status, 400);
  assert.equal((await t.api('GET', '/quan-tri/don-hang/999999', { token: nhanVien })).status, 404);
});

test('Chuyển trạng thái theo vai trò, đi đúng thứ tự, có lịch sử', async () => {
  const id = s.donKhach5;
  const doi = (token, trangThai, ghiChu) => t.api('PATCH', `/don-hang/${id}/trang-thai`, { token, body: { trangThai, ghiChu } });

  assert.equal((await doi(khach5, 'DA_XAC_NHAN')).status, 403);
  assert.equal((await doi(nhanVien, 'DANG_GIAO')).status, 409);
  assert.equal((await doi(nhanVien, 'TRANG_THAI_LA')).status, 400);
  assert.equal((await doi(nhanVien, 'DA_XAC_NHAN')).status, 200);
  assert.equal((await doi(khach5, 'DA_HUY')).status, 409); // đã xác nhận thì khách không tự hủy
  assert.equal((await doi(nhanVien, 'DANG_GIAO')).status, 200);
  assert.equal((await doi(nhanVien, 'DA_HUY', 'Hết xe')).status, 409); // đang giao thì không hủy
  assert.equal((await doi(khach5, 'DA_NHAN')).status, 409); // chưa giao xong
  assert.equal((await doi(nhanVien, 'DA_GIAO')).status, 200);
  assert.equal((await doi(nhanVien, 'DA_NHAN')).status, 403); // chỉ khách xác nhận đã nhận
  assert.equal((await doi(khach2, 'DA_NHAN')).status, 404); // không phải đơn của khách 2
  const r = await doi(khach5, 'DA_NHAN', 'Đã nhận đủ');
  assert.equal(r.status, 200);
  assert.equal(r.body.trangThai, 'DA_NHAN');
  assert.deepEqual(r.body.lichSu.map((x) => x.trangThai), ['CHO_XAC_NHAN', 'DA_XAC_NHAN', 'DANG_GIAO', 'DA_GIAO', 'DA_NHAN']);
});

test('Hủy đơn hoàn tồn về đúng các lô; nhân sự hủy phải có lý do', async () => {
  const { id, lo1, lo2, ton2 } = s.donFifo;
  const url = `/don-hang/${id}/trang-thai`;
  assert.equal((await t.api('PATCH', url, { token: nhanVien, body: { trangThai: 'DA_HUY' } })).status, 400);
  const r = await t.api('PATCH', url, { token: khach2, body: { trangThai: 'DA_HUY', ghiChu: 'Đặt nhầm' } });
  assert.equal(r.status, 200, JSON.stringify(r.body));
  assert.equal(r.body.trangThai, 'DA_HUY');
  assert.equal(await tonLo(lo1), 2);
  assert.equal(await tonLo(lo2), ton2);
  // Hủy lần nữa không được hoàn tồn thêm.
  assert.equal((await t.api('PATCH', url, { token: khach2, body: { trangThai: 'DA_HUY' } })).status, 409);
  assert.equal(await tonLo(lo1), 2);
});
