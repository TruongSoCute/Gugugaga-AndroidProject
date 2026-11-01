'use strict';

// Kiểm tra kiến trúc bằng máy: code thật không vi phạm, và bộ kiểm tra bắt được
// từng loại vi phạm trên một cây thư mục mẫu.
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { kiemTraKienTruc } = require('../scripts/check-architecture');

test('src/ tuân thủ kiến trúc phân tầng', () => {
  const loi = kiemTraKienTruc(path.join(__dirname, '..', 'src'));
  assert.deepEqual(loi, [], loi.map((l) => `${l.file}:${l.dong} ${l.ma} ${l.thongDiep}`).join('\n'));
});

test('Bộ kiểm tra phát hiện từng loại vi phạm', (t) => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'kien-truc-'));
  t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
  const viet = (rel, noiDung) => {
    fs.mkdirSync(path.dirname(path.join(dir, rel)), { recursive: true });
    fs.writeFileSync(path.join(dir, rel), `'use strict';\n${noiDung}\n`);
  };

  viet('app.js', "require('./domains/a'); require('pg/lib/x');");
  viet('providers/db.js', "require('pg'); require('../utils/u');");
  viet('providers/khac.js', "require('jsonwebtoken'); require('../domains/a/service');");
  viet('utils/u.js', "require('../providers/db'); require('node:fs');");
  viet('domains/a/types.js', "require('../../providers/db');");
  viet('domains/a/repo.js', "require('./service'); require('./types'); require('../../utils/u');");
  viet('domains/a/service.js', "require('./repo'); require('../b/service'); require('pg'); require(tenDong);");
  viet('domains/a/routes.js', "require('express'); require('./service'); require('./repo'); require('../../config');");
  viet('domains/a/index.js', "require('./service'); require('./routes');");
  viet('domains/a/helpers.js', '');
  viet('domains/b/service.js', "require('node:crypto');");
  viet('config.js', '');

  const loi = kiemTraKienTruc(dir).map((l) => `${l.file} ${l.ma}`).sort();
  assert.deepEqual(loi, [
    'app.js THU_VIEN_SAI_CHO', // pg ngoài providers/db.js
    'domains/a/helpers.js TEP_NGOAI_KIEN_TRUC',
    'domains/a/repo.js TANG_NGUOC',
    'domains/a/routes.js MIEN_GOI_WIRING',
    'domains/a/routes.js ROUTES_GOI_REPO',
    'domains/a/service.js LIEN_MIEN',
    'domains/a/service.js REQUIRE_DONG',
    'domains/a/service.js THU_VIEN_SAI_CHO',
    'domains/a/types.js PROVIDER_SAI_TANG',
    'domains/b/service.js THU_VIEN_SAI_CHO', // crypto chỉ ở providers/random.js
    'providers/khac.js PROVIDER_PHU_THUOC',
    'providers/khac.js THU_VIEN_SAI_CHO',
    'utils/u.js UTILS_PHU_THUOC',
    'utils/u.js UTILS_PHU_THUOC',
  ]);
});
