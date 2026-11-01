'use strict';

// Nhà cung cấp dùng app Client: tự đăng ký, gửi hồ sơ và sản phẩm chờ duyệt, chỉ thấy và sửa
// dữ liệu của mình, không tự đổi trạng thái duyệt hay hạng sao; quản trị duyệt trên app Admin.
const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { setup } = require('./helpers');

let t;
let quanTri;
let khach;
let ncc1; // ncc1@ocop.example sở hữu nhà cung cấp 1 (đã duyệt, seed)
const s = {};

const HO_SO = {
  ten: 'Cơ sở Bánh pía thử nghiệm', nguoiDaiDien: 'Trần Văn Tư', soDienThoai: '0907 111 222',
  diaChi: 'Xã Bình Lợi, huyện Bình Chánh', vungId: 5, anhCoSoUrl: 'https://example.com/co-so.jpg',
  chungNhan: [{ loai: 'OCOP', soHieu: 'TEST-TU-GUI-1', ngayCap: '2026-01-10', ngayHetHan: '2029-01-10' }],
};

before(async () => {
  t = await setup();
  quanTri = await t.login('quantri@ocop.example');
  khach = await t.login('khach1@ocop.example');
  ncc1 = await t.login('ncc1@ocop.example');
});
after(async () => { await t.teardown(); });

test('Đăng ký tài khoản nhà cung cấp; không tự đăng ký được nhân sự', async () => {
  const r = await t.api('POST', '/auth/dang-ky', {
    body: { email: 'ncc.moi@ocop.example', matKhau: 'MatKhau@123', hoTen: 'Trần Văn Tư', loaiTaiKhoan: 'NHA_CUNG_CAP' },
  });
  assert.equal(r.status, 201, JSON.stringify(r.body));
  assert.equal(r.body.nguoiDung.vaiTro, 'NHA_CUNG_CAP');
  s.nccMoi = r.body.token;

  const quan = await t.api('POST', '/auth/dang-ky', {
    body: { email: 'gia.mao@ocop.example', matKhau: 'MatKhau@123', hoTen: 'X', loaiTaiKhoan: 'QUAN_TRI' },
  });
  assert.equal(quan.status, 400);
  const vaiTro = await t.api('POST', '/auth/dang-ky', {
    body: { email: 'gia.mao2@ocop.example', matKhau: 'MatKhau@123', hoTen: 'X', vaiTro: 'QUAN_TRI' },
  });
  assert.equal(vaiTro.status, 201);
  assert.equal(vaiTro.body.nguoiDung.vaiTro, 'KHACH');
});

test('Chưa có hồ sơ: GET 404, thêm sản phẩm 409, danh sách sản phẩm rỗng', async () => {
  const r = await t.api('GET', '/cua-toi/nha-cung-cap', { token: s.nccMoi });
  assert.equal(r.status, 404);
  assert.equal(r.body.loi.ma, 'CHUA_CO_HO_SO');
  assert.equal((await t.api('POST', '/cua-toi/san-pham', { token: s.nccMoi, body: { ten: 'X', gia: 1000 } })).status, 409);
  assert.deepEqual((await t.api('GET', '/cua-toi/san-pham', { token: s.nccMoi })).body, []);
});

test('Khách, nhân sự và người chưa đăng nhập không dùng được API của nhà cung cấp', async () => {
  assert.equal((await t.api('GET', '/cua-toi/nha-cung-cap')).status, 401);
  assert.equal((await t.api('GET', '/cua-toi/nha-cung-cap', { token: khach })).status, 403);
  assert.equal((await t.api('GET', '/cua-toi/san-pham', { token: quanTri })).status, 403);
  // Nhà cung cấp không dùng được API nhân sự hay đặt hàng.
  assert.equal((await t.api('GET', '/quan-tri/san-pham', { token: ncc1 })).status, 403);
  assert.equal((await t.api('PATCH', '/san-pham/1/duyet', { token: ncc1, body: { trangThai: 'DA_DUYET', hangSao: 5 } })).status, 403);
  assert.equal((await t.api('GET', '/gio-hang', { token: ncc1 })).status, 403);
});

test('Gửi hồ sơ: luôn CHO_DUYET dù gửi kèm trạng thái; gửi lần hai 409; dữ liệu sai 400', async () => {
  const sai = await t.api('POST', '/cua-toi/nha-cung-cap', { token: s.nccMoi, body: { ten: '', vungId: 'x' } });
  assert.equal(sai.status, 400);

  const r = await t.api('POST', '/cua-toi/nha-cung-cap', {
    token: s.nccMoi, body: { ...HO_SO, trangThaiDuyet: 'DA_DUYET' },
  });
  assert.equal(r.status, 201, JSON.stringify(r.body));
  assert.equal(r.body.trangThaiDuyet, 'CHO_DUYET');
  assert.equal(r.body.tuGui, true);
  assert.equal(r.body.chungNhan.length, 1);
  s.nccId = r.body.id;

  const lai = await t.api('POST', '/cua-toi/nha-cung-cap', { token: s.nccMoi, body: HO_SO });
  assert.equal(lai.status, 409);
  assert.equal(lai.body.loi.ma, 'DA_CO_HO_SO');

  // Quản trị thấy hồ sơ tự gửi trong danh sách chờ duyệt.
  const ds = await t.api('GET', '/quan-tri/nha-cung-cap?trangThai=CHO_DUYET', { token: quanTri });
  assert.ok(ds.body.duLieu.some((x) => x.id === s.nccId && x.tuGui === true));
});

test('Hồ sơ bị từ chối: sửa và gửi lại thì về CHO_DUYET, chứng nhận được thay mới', async () => {
  await t.api('PATCH', `/nha-cung-cap/${s.nccId}/duyet`, { token: quanTri, body: { trangThai: 'TU_CHOI', lyDo: 'Ảnh mờ' } });
  const tuChoi = await t.api('GET', '/cua-toi/nha-cung-cap', { token: s.nccMoi });
  assert.equal(tuChoi.body.trangThaiDuyet, 'TU_CHOI');
  assert.equal(tuChoi.body.lyDoTuChoi, 'Ảnh mờ');

  // Hồ sơ bị từ chối thì chưa thêm được sản phẩm.
  const sp = await t.api('POST', '/cua-toi/san-pham', { token: s.nccMoi, body: { ten: 'Bánh pía', gia: 60000 } });
  assert.equal(sp.status, 409);
  assert.equal(sp.body.loi.ma, 'NHA_CUNG_CAP_BI_TU_CHOI');

  const r = await t.api('PUT', '/cua-toi/nha-cung-cap', {
    token: s.nccMoi,
    body: { ...HO_SO, ten: 'Cơ sở Bánh pía (đã sửa)', chungNhan: [{ loai: 'OCOP', soHieu: 'TEST-TU-GUI-2', ngayCap: '2026-02-01' }] },
  });
  assert.equal(r.status, 200, JSON.stringify(r.body));
  assert.equal(r.body.trangThaiDuyet, 'CHO_DUYET');
  assert.equal(r.body.lyDoTuChoi, null);
  assert.equal(r.body.ten, 'Cơ sở Bánh pía (đã sửa)');
  assert.deepEqual(r.body.chungNhan.map((c) => c.soHieu), ['TEST-TU-GUI-2']);
});

test('Thêm và sửa sản phẩm của mình; luôn chờ duyệt; không chọn được hạng sao', async () => {
  const r = await t.api('POST', '/cua-toi/san-pham', {
    token: s.nccMoi, body: { ten: 'Bánh pía sầu riêng', gia: 65000, donViTinh: 'hộp', hangSao: 5, trangThaiDuyet: 'DA_DUYET', nhaCungCapId: 1 },
  });
  assert.equal(r.status, 201, JSON.stringify(r.body));
  assert.equal(r.body.trangThaiDuyet, 'CHO_DUYET');
  assert.equal(r.body.hangSao, null);
  s.spId = r.body.id;
  // Gắn vào đúng hồ sơ của tài khoản, không phải nhà cung cấp 1 như client gửi.
  const row = (await t.pool.query('SELECT nha_cung_cap_id FROM san_pham WHERE id = $1', [s.spId])).rows[0];
  assert.equal(row.nha_cung_cap_id, s.nccId);

  const sua = await t.api('PUT', `/cua-toi/san-pham/${s.spId}`, { token: s.nccMoi, body: { ten: 'Bánh pía sầu riêng 4 cái', gia: 70000 } });
  assert.equal(sua.status, 200);
  assert.equal(sua.body.gia, 70000);
  assert.equal((await t.api('PUT', `/cua-toi/san-pham/${s.spId}`, { token: s.nccMoi, body: { ten: 'X', gia: 0 } })).status, 400);

  const ds = await t.api('GET', '/cua-toi/san-pham', { token: s.nccMoi });
  assert.deepEqual(ds.body.map((x) => x.id), [s.spId]);
});

test('Nhà cung cấp chỉ thấy và sửa sản phẩm của mình; sản phẩm đã duyệt không tự sửa được', async () => {
  // ncc1 không xem/sửa được sản phẩm của hồ sơ khác.
  assert.equal((await t.api('GET', `/cua-toi/san-pham/${s.spId}`, { token: ncc1 })).status, 404);
  assert.equal((await t.api('PUT', `/cua-toi/san-pham/${s.spId}`, { token: ncc1, body: { ten: 'Chiếm', gia: 1 } })).status, 404);

  const ds1 = await t.api('GET', '/cua-toi/san-pham', { token: ncc1 });
  assert.equal(ds1.body.length, 5); // nhà cung cấp 1 có 5 sản phẩm mẫu
  const daDuyet = ds1.body.find((x) => x.trangThaiDuyet === 'DA_DUYET');
  assert.ok(daDuyet.soLo > 0);
  const r = await t.api('PUT', `/cua-toi/san-pham/${daDuyet.id}`, { token: ncc1, body: { ten: daDuyet.ten, gia: 1 } });
  assert.equal(r.status, 409);
  assert.equal(r.body.loi.ma, 'SAN_PHAM_DA_DUYET');

  // Hồ sơ đã duyệt cũng không tự sửa được.
  const hs = await t.api('PUT', '/cua-toi/nha-cung-cap', { token: ncc1, body: HO_SO });
  assert.equal(hs.status, 409);
  assert.equal(hs.body.loi.ma, 'HO_SO_DA_DUYET');
});

test('Quản trị duyệt hồ sơ và sản phẩm tự gửi thì sản phẩm xuất hiện công khai', async () => {
  assert.equal((await t.api('PATCH', `/nha-cung-cap/${s.nccId}/duyet`, { token: quanTri, body: { trangThai: 'DA_DUYET' } })).status, 200);
  assert.equal((await t.api('PATCH', `/san-pham/${s.spId}/duyet`, { token: quanTri, body: { trangThai: 'DA_DUYET', hangSao: 3 } })).status, 200);
  const pub = await t.api('GET', `/san-pham/${s.spId}`);
  assert.equal(pub.status, 200);
  assert.equal(pub.body.hangSao, 3);
  const cuaToi = await t.api('GET', `/cua-toi/san-pham/${s.spId}`, { token: s.nccMoi });
  assert.equal(cuaToi.body.trangThaiDuyet, 'DA_DUYET');
});
