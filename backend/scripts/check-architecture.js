'use strict';

// Kiểm tra kiến trúc phân tầng bằng máy (chạy: npm run check:arch; cũng chạy trong npm test).
//
// Cấu trúc src/:
//   app.js, server.js, config.js   App Wiring: ghép Providers với các miền
//   providers/*.js                 Mối quan tâm xuyên suốt: CSDL, xác thực, mật khẩu, ngẫu nhiên, log, HTTP
//   utils/*.js                     Hàm thuần dùng chung, không phụ thuộc gì ngoài utils
//   domains/<miền>/<tầng>.js       Tầng: types -> config -> repo -> service -> routes -> index
//
// Quy tắc:
//   1. Trong một miền chỉ được require tầng ĐỨNG TRƯỚC (vd: service dùng repo, repo không dùng service).
//   2. routes không require repo: mọi truy cập dữ liệu phải qua service.
//   3. Chỉ service, routes, index được dùng providers; types/config/repo thì không.
//   4. Miền không require miền khác; phụ thuộc giữa các miền được truyền vào từ app.js.
//   5. utils chỉ require utils. providers chỉ require providers và utils.
//   6. Thư viện nhạy cảm chỉ dùng ở đúng một provider (pg, jsonwebtoken, bcryptjs, crypto).
//      Trong miền, chỉ tầng routes được dùng express; không dùng thư viện ngoài nào khác.
//   7. Không require động (tham số không phải chuỗi cố định), không dùng import ES module.
//   8. Mọi file .js trong src phải thuộc một trong các vị trí trên.
const fs = require('node:fs');
const path = require('node:path');

const TANG = ['types', 'config', 'repo', 'service', 'routes', 'index'];
const TANG_DUNG_PROVIDER = new Set(['service', 'routes', 'index']);
const WIRING = new Set(['app.js', 'server.js', 'config.js']);
const CHU_THU_VIEN = {
  pg: 'providers/db.js',
  jsonwebtoken: 'providers/auth.js',
  bcryptjs: 'providers/password.js',
  crypto: 'providers/random.js',
};

function liKeFile(dir) {
  const out = [];
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) out.push(...liKeFile(p));
    else if (e.name.endsWith('.js')) out.push(p);
  }
  return out;
}

// Phân loại file theo đường dẫn tương đối với src (dùng dấu /).
function phanLoai(rel) {
  if (WIRING.has(rel)) return { loai: 'wiring' };
  let m = rel.match(/^providers\/[^/]+\.js$/);
  if (m) return { loai: 'provider' };
  m = rel.match(/^utils\/[^/]+\.js$/);
  if (m) return { loai: 'util' };
  m = rel.match(/^domains\/([^/]+)\/([^/]+)\.js$/);
  if (m && TANG.includes(m[2])) return { loai: 'domain', mien: m[1], tang: m[2] };
  return null;
}

// Tìm file đích của require tương đối: thử nguyên tên, thêm .js, rồi /index.js.
function giaiQuyet(fromFile, spec) {
  const base = path.resolve(path.dirname(fromFile), spec);
  for (const p of [base, `${base}.js`, path.join(base, 'index.js')]) {
    if (fs.existsSync(p) && fs.statSync(p).isFile()) return p;
  }
  return `${base}.js`;
}

function tenThuVien(spec) {
  const s = spec.replace(/^node:/, '');
  return s.startsWith('@') ? s.split('/').slice(0, 2).join('/') : s.split('/')[0];
}

function soDong(text, index) {
  return text.slice(0, index).split('\n').length;
}

function kiemTraKienTruc(srcDir) {
  const loi = [];
  const bao = (file, dong, ma, thongDiep) => loi.push({ file, dong, ma, thongDiep });

  for (const abs of liKeFile(srcDir)) {
    const rel = path.relative(srcDir, abs).split(path.sep).join('/');
    const nguon = phanLoai(rel);
    if (!nguon) {
      bao(rel, 1, 'TEP_NGOAI_KIEN_TRUC', 'File không thuộc tầng nào (wiring, providers, utils, domains/<miền>/<tầng>.js).');
      continue;
    }
    const text = fs.readFileSync(abs, 'utf8');

    if (/^\s*import\s/m.test(text) || /^\s*export\s/m.test(text)) {
      bao(rel, 1, 'IMPORT_ES', 'Dùng require (CommonJS), không dùng import/export ES module.');
    }
    for (const m of text.matchAll(/\brequire\s*\(\s*(?!['"][^'"]+['"]\s*\))/g)) {
      bao(rel, soDong(text, m.index), 'REQUIRE_DONG', 'require phải nhận một chuỗi cố định để kiểm tra được.');
    }

    for (const m of text.matchAll(/\brequire\s*\(\s*(['"])([^'"]+)\1\s*\)/g)) {
      const spec = m[2];
      const dong = soDong(text, m.index);

      // ---- Thư viện ngoài / module có sẵn của Node ----
      if (!spec.startsWith('.')) {
        const lib = tenThuVien(spec);
        const chu = CHU_THU_VIEN[lib];
        if (chu && chu !== rel) {
          bao(rel, dong, 'THU_VIEN_SAI_CHO', `"${spec}" chỉ được dùng trong ${chu}.`);
        } else if (nguon.loai === 'util') {
          bao(rel, dong, 'UTILS_PHU_THUOC', `utils phải là hàm thuần, không dùng "${spec}".`);
        } else if (nguon.loai === 'domain' && !(lib === 'express' && nguon.tang === 'routes')) {
          bao(rel, dong, 'THU_VIEN_SAI_CHO', `Tầng ${nguon.tang} của miền không được dùng "${spec}" (chỉ routes dùng express; còn lại qua providers).`);
        }
        continue;
      }

      // ---- File trong dự án ----
      const dichAbs = giaiQuyet(abs, spec);
      const dichRel = path.relative(srcDir, dichAbs).split(path.sep).join('/');
      if (dichRel.startsWith('..')) {
        bao(rel, dong, 'NGOAI_SRC', `Không require file ngoài src: "${spec}".`);
        continue;
      }
      const dich = phanLoai(dichRel);
      if (!dich) continue; // file đích tự bị báo TEP_NGOAI_KIEN_TRUC

      if (nguon.loai === 'wiring') continue;

      if (nguon.loai === 'util') {
        if (dich.loai !== 'util') bao(rel, dong, 'UTILS_PHU_THUOC', `utils chỉ được require utils, không require ${dichRel}.`);
        continue;
      }

      if (nguon.loai === 'provider') {
        if (dich.loai !== 'util' && dich.loai !== 'provider') {
          bao(rel, dong, 'PROVIDER_PHU_THUOC', `providers chỉ được require providers/utils, không require ${dichRel}.`);
        }
        continue;
      }

      // nguon.loai === 'domain'
      if (dich.loai === 'util') continue;
      if (dich.loai === 'wiring') {
        bao(rel, dong, 'MIEN_GOI_WIRING', `Miền không require ${dichRel}; cấu hình đi vào qua providers.`);
      } else if (dich.loai === 'provider') {
        if (!TANG_DUNG_PROVIDER.has(nguon.tang)) {
          bao(rel, dong, 'PROVIDER_SAI_TANG', `Tầng ${nguon.tang} không được dùng providers (chỉ service, routes, index).`);
        }
      } else if (dich.mien !== nguon.mien) {
        bao(rel, dong, 'LIEN_MIEN', `Miền ${nguon.mien} không require miền ${dich.mien}; truyền service qua app.js.`);
      } else if (TANG.indexOf(dich.tang) >= TANG.indexOf(nguon.tang)) {
        bao(rel, dong, 'TANG_NGUOC', `Tầng ${nguon.tang} không được require tầng ${dich.tang} (chỉ require tầng đứng trước).`);
      } else if (nguon.tang === 'routes' && dich.tang === 'repo') {
        bao(rel, dong, 'ROUTES_GOI_REPO', 'routes không gọi repo trực tiếp; truy cập dữ liệu phải qua service.');
      }
    }
  }
  return loi;
}

module.exports = { kiemTraKienTruc, TANG };

if (require.main === module) {
  const srcDir = path.join(__dirname, '..', 'src');
  const loi = kiemTraKienTruc(srcDir);
  if (loi.length) {
    for (const l of loi) console.error(`src/${l.file}:${l.dong}  [${l.ma}] ${l.thongDiep}`);
    console.error(`\n${loi.length} vi phạm kiến trúc. Xem docs/development/Tech_stack.md mục Kiến trúc backend.`);
    process.exit(1);
  }
  console.log('Kiến trúc hợp lệ: không có vi phạm.');
}
