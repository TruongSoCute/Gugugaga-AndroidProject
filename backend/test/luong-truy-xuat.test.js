'use strict';

// Luồng xuyên suốt theo Plan.md bước 2: nhân viên nhập nhà cung cấp và sản phẩm,
// quản trị duyệt, nhân viên tạo lô + bước truy xuất, người quét QR (không đăng nhập)
// thấy đúng hành trình của từng lô.
const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { setup } = require('./helpers');

let t;
let quanTri;
let nhanVien;
let khach;
const s = {}; // trạng thái dùng chung giữa các bước

before(async () => {
  t = await setup();
  quanTri = await t.login('quantri@ocop.example');
  nhanVien = await t.login('nhanvien@ocop.example');
  khach = await t.login('khach1@ocop.example');
});
after(async () => { await t.teardown(); });

test('Nhân viên tạo hồ sơ nhà cung cấp kèm chứng nhận: trạng thái CHO_DUYET', async () => {
  const r = await t.api('POST', '/nha-cung-cap', {
    token: nhanVien,
    body: {
      ten: 'Cơ sở thử nghiệm', nguoiDaiDien: 'Người A', soDienThoai: '0901 234 567',
      diaChi: 'Cần Giờ', vungId: 1, anhCoSoUrl: 'https://example.com/co-so.jpg',
      trangThaiDuyet: 'DA_DUYET', // client tự gửi trạng thái: phải bị bỏ qua
      chungNhan: [{ loai: 'OCOP', soHieu: 'TEST-OCOP-1', ngayCap: '2026-01-01', ngayHetHan: '2029-01-01' }],
    },
  });
  assert.equal(r.status, 201, JSON.stringify(r.body));
  assert.equal(r.body.trangThaiDuyet, 'CHO_DUYET');
  assert.equal(r.body.chungNhan.length, 1);
  assert.equal(r.body.chungNhan[0].conHieuLuc, true);
  s.nccId = r.body.id;
});

test('Tạo nhà cung cấp lỗi ở chứng nhận thì không lưu gì (rollback transaction)', async () => {
  const truoc = (await t.pool.query('SELECT count(*) n FROM nha_cung_cap')).rows[0].n;
  const r = await t.api('POST', '/nha-cung-cap', {
    token: nhanVien,
    body: {
      ten: 'Cơ sở lỗi', nguoiDaiDien: 'B', soDienThoai: '0901234568', diaChi: 'X', vungId: 1,
      chungNhan: [
        { loai: 'OCOP', soHieu: 'TEST-OCOP-2', ngayCap: '2026-01-01' },
        { loai: 'OCOP', soHieu: 'TEST-OCOP-1', ngayCap: '2026-01-01' }, // trùng số hiệu đã có
      ],
    },
  });
  assert.equal(r.status, 409);
  const sau = (await t.pool.query('SELECT count(*) n FROM nha_cung_cap')).rows[0].n;
  assert.equal(sau, truoc);
  const cn = await t.pool.query("SELECT 1 FROM chung_nhan WHERE so_hieu = 'TEST-OCOP-2'");
  assert.equal(cn.rowCount, 0);
});

test('Dữ liệu nhà cung cấp không hợp lệ trả 400', async () => {
  const r = await t.api('POST', '/nha-cung-cap', {
    token: nhanVien,
    body: { ten: '', soDienThoai: 'abc', vungId: 'x', anhCoSoUrl: 'javascript:alert(1)' },
  });
  assert.equal(r.status, 400);
  const truong = r.body.loi.chiTiet.map((x) => x.truong);
  for (const f of ['ten', 'nguoiDaiDien', 'soDienThoai', 'diaChi', 'vungId', 'anhCoSoUrl']) {
    assert.ok(truong.includes(f), `thiếu lỗi cho ${f}`);
  }
});

test('Khách không tạo được nhà cung cấp (403); không token (401)', async () => {
  const body = { ten: 'X', nguoiDaiDien: 'Y', soDienThoai: '0901234567', diaChi: 'Z', vungId: 1 };
  assert.equal((await t.api('POST', '/nha-cung-cap', { token: khach, body })).status, 403);
  assert.equal((await t.api('POST', '/nha-cung-cap', { body })).status, 401);
});

test('Nhà cung cấp chưa duyệt không xuất hiện công khai', async () => {
  assert.equal((await t.api('GET', `/nha-cung-cap/${s.nccId}`)).status, 404);
  const ds = await t.api('GET', '/nha-cung-cap');
  assert.equal(ds.body.some((x) => x.id === s.nccId), false);
});

test('Nhân viên tạo sản phẩm: CHO_DUYET và chưa công khai', async () => {
  const r = await t.api('POST', '/san-pham', {
    token: nhanVien,
    body: { nhaCungCapId: s.nccId, ten: 'Khô cá dứa thử nghiệm 500 g', gia: 300000, hangSao: 5, trangThaiDuyet: 'DA_DUYET' },
  });
  assert.equal(r.status, 201, JSON.stringify(r.body));
  assert.equal(r.body.trangThaiDuyet, 'CHO_DUYET');
  assert.equal(r.body.hangSao, null, 'hạng sao chỉ do quản trị chốt khi duyệt');
  s.spId = r.body.id;
  assert.equal((await t.api('GET', `/san-pham/${s.spId}`)).status, 404);
});

test('Nhân viên không được duyệt (403); quản trị không duyệt sản phẩm trước nhà cung cấp (409)', async () => {
  const a = await t.api('PATCH', `/nha-cung-cap/${s.nccId}/duyet`, { token: nhanVien, body: { trangThai: 'DA_DUYET' } });
  assert.equal(a.status, 403);
  const b = await t.api('PATCH', `/san-pham/${s.spId}/duyet`, { token: nhanVien, body: { trangThai: 'DA_DUYET', hangSao: 4 } });
  assert.equal(b.status, 403);
  const c = await t.api('PATCH', `/san-pham/${s.spId}/duyet`, { token: quanTri, body: { trangThai: 'DA_DUYET', hangSao: 4 } });
  assert.equal(c.status, 409);
  assert.equal(c.body.loi.ma, 'NHA_CUNG_CAP_CHUA_DUYET');
});

test('Từ chối phải có lý do; duyệt sản phẩm phải chọn hạng 3–5 sao', async () => {
  const a = await t.api('PATCH', `/nha-cung-cap/${s.nccId}/duyet`, { token: quanTri, body: { trangThai: 'TU_CHOI' } });
  assert.equal(a.status, 400);
  const b = await t.api('PATCH', `/nha-cung-cap/${s.nccId}/duyet`, { token: quanTri, body: { trangThai: 'XYZ' } });
  assert.equal(b.status, 400);
});

test('Quản trị duyệt nhà cung cấp rồi duyệt sản phẩm hạng 4 sao: sản phẩm công khai', async () => {
  const a = await t.api('PATCH', `/nha-cung-cap/${s.nccId}/duyet`, { token: quanTri, body: { trangThai: 'DA_DUYET' } });
  assert.equal(a.status, 200, JSON.stringify(a.body));
  assert.equal(a.body.trangThaiDuyet, 'DA_DUYET');
  const again = await t.api('PATCH', `/nha-cung-cap/${s.nccId}/duyet`, { token: quanTri, body: { trangThai: 'DA_DUYET' } });
  assert.equal(again.status, 409);

  const thieuSao = await t.api('PATCH', `/san-pham/${s.spId}/duyet`, { token: quanTri, body: { trangThai: 'DA_DUYET' } });
  assert.equal(thieuSao.status, 400);
  const saiSao = await t.api('PATCH', `/san-pham/${s.spId}/duyet`, { token: quanTri, body: { trangThai: 'DA_DUYET', hangSao: 6 } });
  assert.equal(saiSao.status, 400);

  const b = await t.api('PATCH', `/san-pham/${s.spId}/duyet`, { token: quanTri, body: { trangThai: 'DA_DUYET', hangSao: 4 } });
  assert.equal(b.status, 200, JSON.stringify(b.body));
  assert.equal(b.body.hangSao, 4);

  const pub = await t.api('GET', `/san-pham/${s.spId}`);
  assert.equal(pub.status, 200);
  assert.equal(pub.body.tenNhaCungCap, 'Cơ sở thử nghiệm');
  assert.equal(pub.body.chungNhan[0].soHieu, 'TEST-OCOP-1');
});

test('Không duyệt được nhà cung cấp thiếu chứng nhận OCOP còn hiệu lực', async () => {
  const r = await t.api('POST', '/nha-cung-cap', {
    token: nhanVien,
    body: {
      ten: 'Cơ sở hết hạn', nguoiDaiDien: 'C', soDienThoai: '0901234569', diaChi: 'Củ Chi', vungId: 2,
      anhCoSoUrl: 'https://example.com/a.jpg',
      chungNhan: [{ loai: 'OCOP', soHieu: 'TEST-OCOP-HET', ngayCap: '2020-01-01', ngayHetHan: '2023-01-01' }],
    },
  });
  assert.equal(r.status, 201);
  const d = await t.api('PATCH', `/nha-cung-cap/${r.body.id}/duyet`, { token: quanTri, body: { trangThai: 'DA_DUYET' } });
  assert.equal(d.status, 409);
  assert.equal(d.body.loi.ma, 'THIEU_CHUNG_NHAN_OCOP');
});

test('Nhân viên tạo hai lô cùng sản phẩm, kèm 4 bước: mã truy xuất khác nhau, khó đoán', async () => {
  const buoc = (ten, ngay) => ({ tenBuoc: ten, moTa: `${ten} lô thử`, thoiDiem: `${ngay}T08:00:00+07:00`, anhUrl: `https://example.com/${encodeURIComponent(ten)}.jpg` });
  const a = await t.api('POST', '/lo-san-xuat', {
    token: nhanVien,
    body: {
      sanPhamId: s.spId, ngaySanXuat: '2026-10-01', hanSuDung: '2027-10-01', soLuong: 200,
      nguoiSanXuat: 'Tổ A', anhHienTruongUrl: 'https://example.com/lo-a.jpg', ghiChu: 'GHI_CHU_NOI_BO_A',
      maTruyXuat: 'AAAAAAAAAAAAAAAAAAAA', // client tự đặt mã: phải bị bỏ qua
      cacBuoc: [buoc('Thu hoạch', '2026-09-28'), buoc('Sơ chế', '2026-09-29'), buoc('Đóng gói', '2026-10-01'), buoc('Kiểm nghiệm', '2026-10-03')],
    },
  });
  assert.equal(a.status, 201, JSON.stringify(a.body));
  assert.match(a.body.maTruyXuat, /^[0-9A-F]{20}$/);
  assert.notEqual(a.body.maTruyXuat, 'AAAAAAAAAAAAAAAAAAAA');
  assert.equal(a.body.cacBuoc.length, 4);
  assert.equal(a.body.soLuongCon, 200);
  assert.equal(a.body.vungNguyenLieuId, 1, 'mặc định lấy vùng của nhà cung cấp');
  assert.equal(a.body.duongDanTruyXuat, `https://ocop.example/truy-xuat/${a.body.maTruyXuat}`);

  const b = await t.api('POST', '/lo-san-xuat', {
    token: nhanVien,
    body: {
      sanPhamId: s.spId, ngaySanXuat: '2026-10-15', hanSuDung: '2027-10-15', soLuong: 50,
      vungNguyenLieuId: 3, nguoiSanXuat: 'Tổ B',
      cacBuoc: [buoc('Thu hoạch', '2026-10-12'), buoc('Phơi khô', '2026-10-13')],
    },
  });
  assert.equal(b.status, 201, JSON.stringify(b.body));
  assert.notEqual(a.body.maTruyXuat, b.body.maTruyXuat);
  s.loA = a.body;
  s.loB = b.body;
});

test('Thêm bước truy xuất vào lô: tự lấy thứ tự kế tiếp; trùng thứ tự trả 409', async () => {
  const r = await t.api('POST', `/lo-san-xuat/${s.loB.id}/buoc`, {
    token: nhanVien,
    body: { tenBuoc: 'Đóng gói', thoiDiem: '2026-10-15T09:00:00+07:00' },
  });
  assert.equal(r.status, 201, JSON.stringify(r.body));
  assert.equal(r.body.thuTu, 3);
  const dup = await t.api('POST', `/lo-san-xuat/${s.loB.id}/buoc`, {
    token: nhanVien,
    body: { thuTu: 1, tenBuoc: 'Trùng', thoiDiem: '2026-10-15T09:00:00+07:00' },
  });
  assert.equal(dup.status, 409);
  const notFound = await t.api('POST', '/lo-san-xuat/999999/buoc', {
    token: nhanVien,
    body: { tenBuoc: 'X', thoiDiem: '2026-10-15T09:00:00+07:00' },
  });
  assert.equal(notFound.status, 404);
  const sai = await t.api('POST', `/lo-san-xuat/${s.loB.id}/buoc`, {
    token: nhanVien,
    body: { tenBuoc: 'X', thoiDiem: '15/10/2026' },
  });
  assert.equal(sai.status, 400);
});

test('Dữ liệu lô không hợp lệ trả 400; khách tạo lô bị 403', async () => {
  const sai = await t.api('POST', '/lo-san-xuat', {
    token: nhanVien,
    body: { sanPhamId: s.spId, ngaySanXuat: '2026-10-01', hanSuDung: '2026-09-01', soLuong: 0, nguoiSanXuat: 'A' },
  });
  assert.equal(sai.status, 400);
  const ngayKhongCo = await t.api('POST', '/lo-san-xuat', {
    token: nhanVien,
    body: { sanPhamId: s.spId, ngaySanXuat: '2026-02-30', hanSuDung: '2027-01-01', soLuong: 1, nguoiSanXuat: 'A' },
  });
  assert.equal(ngayKhongCo.status, 400);
  const khongCoSp = await t.api('POST', '/lo-san-xuat', {
    token: nhanVien,
    body: { sanPhamId: 999999, ngaySanXuat: '2026-10-01', hanSuDung: '2027-01-01', soLuong: 1, nguoiSanXuat: 'A' },
  });
  assert.equal(khongCoSp.status, 400);
  const r = await t.api('POST', '/lo-san-xuat', {
    token: khach,
    body: { sanPhamId: s.spId, ngaySanXuat: '2026-10-01', hanSuDung: '2027-10-01', soLuong: 1, nguoiSanXuat: 'A' },
  });
  assert.equal(r.status, 403);
  assert.equal((await t.api('GET', '/lo-san-xuat', { token: khach })).status, 403);
});

test('Quét QR không đăng nhập: mỗi mã trả đúng hành trình của lô đó', async () => {
  const a = await t.api('GET', `/truy-xuat/${s.loA.maTruyXuat}`);
  const b = await t.api('GET', `/truy-xuat/${s.loB.maTruyXuat.toLowerCase()}`); // chấp nhận chữ thường
  assert.equal(a.status, 200, JSON.stringify(a.body));
  assert.equal(b.status, 200, JSON.stringify(b.body));

  assert.equal(a.body.maTruyXuat, s.loA.maTruyXuat);
  assert.equal(a.body.sanPham.id, s.spId);
  assert.equal(a.body.lo.nguoiSanXuat, 'Tổ A');
  assert.equal(a.body.lo.vungNguyenLieu.ten, 'Cần Giờ');
  assert.deepEqual(a.body.cacBuoc.map((x) => x.tenBuoc), ['Thu hoạch', 'Sơ chế', 'Đóng gói', 'Kiểm nghiệm']);
  assert.equal(a.body.cacBuoc[0].anhUrl, 'https://example.com/Thu%20ho%E1%BA%A1ch.jpg');

  assert.equal(b.body.sanPham.id, s.spId, 'cùng sản phẩm');
  assert.equal(b.body.lo.nguoiSanXuat, 'Tổ B');
  assert.equal(b.body.lo.vungNguyenLieu.ten, 'Bà Rịa – Vũng Tàu');
  assert.deepEqual(b.body.cacBuoc.map((x) => x.tenBuoc), ['Thu hoạch', 'Phơi khô', 'Đóng gói']);
});

test('Truy xuất công khai không lộ dữ liệu nội bộ hoặc cá nhân', async () => {
  const a = await t.api('GET', `/truy-xuat/${s.loA.maTruyXuat}`);
  const json = JSON.stringify(a.body);
  for (const bi of ['GHI_CHU_NOI_BO_A', 'soLuong', 'nguoiTao', 'email', 'matKhau', 'soDienThoai', 'nguoiDaiDien', '"id":' + s.loA.id + ',"ma']) {
    assert.equal(json.includes(bi), false, `không được chứa ${bi}`);
  }
  assert.equal('id' in a.body.lo, false, 'không lộ id nội bộ của lô');
});

test('Mã không tồn tại hoặc sai định dạng trả 404', async () => {
  assert.equal((await t.api('GET', '/truy-xuat/0123456789ABCDEF0123')).status, 404);
  assert.equal((await t.api('GET', '/truy-xuat/1')).status, 404);
  assert.equal((await t.api('GET', "/truy-xuat/' OR 1=1 --")).status, 404);
});

test('Mã truy xuất mẫu trong seed truy xuất được và có 4 bước', async () => {
  const { rows } = await t.pool.query('SELECT ma_truy_xuat FROM lo_san_xuat ORDER BY id LIMIT 1');
  const r = await t.api('GET', `/truy-xuat/${rows[0].ma_truy_xuat}`);
  assert.equal(r.status, 200);
  assert.equal(r.body.cacBuoc.length, 4);
});

test('Khi nhà cung cấp bị thu hồi duyệt, lô của họ không còn được công bố', async () => {
  const r = await t.api('PATCH', `/nha-cung-cap/${s.nccId}/duyet`, {
    token: quanTri, body: { trangThai: 'TU_CHOI', lyDo: 'Phát hiện chứng nhận không hợp lệ' },
  });
  assert.equal(r.status, 200);
  assert.equal((await t.api('GET', `/truy-xuat/${s.loA.maTruyXuat}`)).status, 404);
  assert.equal((await t.api('GET', `/san-pham/${s.spId}`)).status, 404);
  // Nhân sự vẫn xem được lô trong app Admin.
  assert.equal((await t.api('GET', `/lo-san-xuat/${s.loA.id}`, { token: nhanVien })).status, 200);
});
