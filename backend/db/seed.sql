-- Dữ liệu mẫu đề 05. Chạy sau schema.sql; có thể chạy lại (xóa dữ liệu cũ trước khi chèn).
--
-- TOÀN BỘ dữ liệu dưới đây là DỮ LIỆU GIẢ LẬP để demo: tên cơ sở, người đại diện,
-- số điện thoại, số hiệu chứng nhận (tiền tố "MAU-") và ảnh minh họa không phải
-- thông tin đã được xác minh. Không trình bày chúng như dữ liệu thật.
--
-- Số lượng theo yêu cầu đề: 5 vùng (>= 4), 12 nhà cung cấp, 60 sản phẩm,
-- 100 lô x 4 bước truy xuất, 50 đơn hàng.
--
-- Mã truy xuất được sinh ngẫu nhiên mỗi lần chạy, nên không ghi cố định trong tài liệu.
-- Xem mã bằng API quản trị GET /lo-san-xuat hoặc truy vấn bảng production_batches.
--
-- Tài khoản thử nghiệm (mật khẩu chung Demo@12345, đổi khi triển khai thật):
--   quantri@ocop.example   QUAN_TRI
--   nhanvien@ocop.example  NHAN_VIEN
--   khach1..khach5@ocop.example  KHACH
--   ncc1@ocop.example      NHA_CUNG_CAP, sở hữu hồ sơ nhà cung cấp 1 (đã duyệt)
--   ncc11@ocop.example     NHA_CUNG_CAP, sở hữu hồ sơ nhà cung cấp 11 (chờ duyệt)

BEGIN;

TRUNCATE
  order_status_history, review_images, reviews, issue_reports, order_items,
  orders, cart_items, product_favorites, supplier_follows, traceability_steps, production_batches,
  products, certificates, suppliers, users, sourcing_regions
RESTART IDENTITY CASCADE;

-- ---------------------------------------------------------------------------
-- Vùng nguyên liệu (tọa độ gần đúng trung tâm khu vực)
-- ---------------------------------------------------------------------------
INSERT INTO sourcing_regions (name, description, latitude, longitude) VALUES
  ('Cần Giờ',          'Vùng ven biển rừng ngập mặn: hải sản khô, muối, yến.', 10.411400, 106.953900),
  ('Củ Chi',           'Vùng nông nghiệp ngoại thành: rau, bò sữa, bánh tráng.', 11.000000, 106.500000),
  ('Bà Rịa – Vũng Tàu','Vùng hạt điều, hồ tiêu và hải sản.',                   10.541700, 107.242900),
  ('Hóc Môn',          'Vùng cây ăn trái và nông sản chế biến.',              10.886400, 106.592300),
  ('Bình Chánh',       'Vùng nông nghiệp phía tây nam thành phố.',            10.687700, 106.593800);

-- ---------------------------------------------------------------------------
-- Người dùng. Mật khẩu: Demo@12345 (bcrypt, cost 10)
-- ---------------------------------------------------------------------------
INSERT INTO users (email, password_hash, full_name, phone_number, role) VALUES
  ('quantri@ocop.example',  '$2b$10$WE2BlejJLkb/aMvR9DcAFetiSsx5EzCD34Xs1qhpy14jwx3av97rq', 'Quản trị viên mẫu', '0900000001', 'QUAN_TRI'),
  ('nhanvien@ocop.example', '$2b$10$WE2BlejJLkb/aMvR9DcAFetiSsx5EzCD34Xs1qhpy14jwx3av97rq', 'Nhân viên mẫu',     '0900000002', 'NHAN_VIEN'),
  ('khach1@ocop.example',   '$2b$10$WE2BlejJLkb/aMvR9DcAFetiSsx5EzCD34Xs1qhpy14jwx3av97rq', 'Khách mẫu 1',       '0911000001', 'KHACH'),
  ('khach2@ocop.example',   '$2b$10$WE2BlejJLkb/aMvR9DcAFetiSsx5EzCD34Xs1qhpy14jwx3av97rq', 'Khách mẫu 2',       '0911000002', 'KHACH'),
  ('khach3@ocop.example',   '$2b$10$WE2BlejJLkb/aMvR9DcAFetiSsx5EzCD34Xs1qhpy14jwx3av97rq', 'Khách mẫu 3',       '0911000003', 'KHACH'),
  ('khach4@ocop.example',   '$2b$10$WE2BlejJLkb/aMvR9DcAFetiSsx5EzCD34Xs1qhpy14jwx3av97rq', 'Khách mẫu 4',       '0911000004', 'KHACH'),
  ('khach5@ocop.example',   '$2b$10$WE2BlejJLkb/aMvR9DcAFetiSsx5EzCD34Xs1qhpy14jwx3av97rq', 'Khách mẫu 5',       '0911000005', 'KHACH'),
  ('ncc1@ocop.example',     '$2b$10$WE2BlejJLkb/aMvR9DcAFetiSsx5EzCD34Xs1qhpy14jwx3av97rq', 'Nguyễn Văn An (mẫu)', '0281000001', 'NHA_CUNG_CAP'),
  ('ncc11@ocop.example',    '$2b$10$WE2BlejJLkb/aMvR9DcAFetiSsx5EzCD34Xs1qhpy14jwx3av97rq', 'Lý Văn Minh (mẫu)',   '0281000011', 'NHA_CUNG_CAP');

-- ---------------------------------------------------------------------------
-- Nhà cung cấp: 1–10 đã duyệt, 11 chờ duyệt, 12 bị từ chối.
-- ---------------------------------------------------------------------------
INSERT INTO suppliers
  (name, representative_name, phone_number, address, sourcing_region_id, facility_image_url,
   approval_status, rejection_reason, reviewed_by_user_id, reviewed_at, created_by_user_id, created_at)
VALUES
  ('HTX Hải sản khô Cần Giờ (mẫu)',  'Nguyễn Văn An',  '0281000001', 'Xã Long Hòa, huyện Cần Giờ',          1, 'https://picsum.photos/seed/ocop-ncc-1/800/500',  'DA_DUYET', NULL, 1, '2026-02-01 09:00+07', 2, '2026-01-20 09:00+07'),
  ('Cơ sở Muối sạch Cần Giờ (mẫu)',  'Trần Thị Bình',  '0281000002', 'Xã Lý Nhơn, huyện Cần Giờ',           1, 'https://picsum.photos/seed/ocop-ncc-2/800/500',  'DA_DUYET', NULL, 1, '2026-02-01 09:30+07', 2, '2026-01-20 10:00+07'),
  ('Yến sào Cần Giờ (mẫu)',          'Lê Văn Cường',   '0281000003', 'Thị trấn Cần Thạnh, huyện Cần Giờ',   1, 'https://picsum.photos/seed/ocop-ncc-3/800/500',  'DA_DUYET', NULL, 1, '2026-02-02 09:00+07', 2, '2026-01-21 09:00+07'),
  ('HTX Rau sạch Củ Chi (mẫu)',      'Phạm Thị Dung',  '0281000004', 'Xã Tân Thạnh Đông, huyện Củ Chi',     2, 'https://picsum.photos/seed/ocop-ncc-4/800/500',  'DA_DUYET', NULL, 1, '2026-02-02 10:00+07', 2, '2026-01-21 10:00+07'),
  ('Cơ sở Bò sữa Củ Chi (mẫu)',      'Hoàng Văn Em',   '0281000005', 'Xã An Nhơn Tây, huyện Củ Chi',        2, 'https://picsum.photos/seed/ocop-ncc-5/800/500',  'DA_DUYET', NULL, 1, '2026-02-03 09:00+07', 2, '2026-01-22 09:00+07'),
  ('Cơ sở Bánh tráng Củ Chi (mẫu)',  'Võ Thị Giang',   '0281000006', 'Xã Phước Hiệp, huyện Củ Chi',         2, 'https://picsum.photos/seed/ocop-ncc-6/800/500',  'DA_DUYET', NULL, 1, '2026-02-03 10:00+07', 2, '2026-01-22 10:00+07'),
  ('HTX Hạt điều Bà Rịa (mẫu)',      'Đặng Văn Hải',   '0254000007', 'Huyện Châu Đức, Bà Rịa – Vũng Tàu',   3, 'https://picsum.photos/seed/ocop-ncc-7/800/500',  'DA_DUYET', NULL, 1, '2026-02-04 09:00+07', 2, '2026-01-23 09:00+07'),
  ('Cơ sở Hồ tiêu Bà Rịa (mẫu)',     'Bùi Thị Hoa',    '0254000008', 'Huyện Châu Đức, Bà Rịa – Vũng Tàu',   3, 'https://picsum.photos/seed/ocop-ncc-8/800/500',  'DA_DUYET', NULL, 1, '2026-02-04 10:00+07', 2, '2026-01-23 10:00+07'),
  ('Cơ sở Hải sản Long Hải (mẫu)',   'Đỗ Văn Khoa',    '0254000009', 'Thị trấn Long Hải, Bà Rịa – Vũng Tàu',3, 'https://picsum.photos/seed/ocop-ncc-9/800/500',  'DA_DUYET', NULL, 1, '2026-02-05 09:00+07', 2, '2026-01-24 09:00+07'),
  ('HTX Mãng cầu Hóc Môn (mẫu)',     'Ngô Thị Lan',    '0281000010', 'Xã Xuân Thới Thượng, huyện Hóc Môn',  4, 'https://picsum.photos/seed/ocop-ncc-10/800/500', 'DA_DUYET', NULL, 1, '2026-02-05 10:00+07', 2, '2026-01-24 10:00+07'),
  ('Cơ sở Mật ong Bình Chánh (mẫu)', 'Lý Văn Minh',    '0281000011', 'Xã Vĩnh Lộc A, huyện Bình Chánh',     5, 'https://picsum.photos/seed/ocop-ncc-11/800/500', 'CHO_DUYET', NULL, NULL, NULL, 2, '2026-09-20 09:00+07'),
  ('Cơ sở Gạo Bình Chánh (mẫu)',     'Mai Thị Ngọc',   '0281000012', 'Xã Tân Nhựt, huyện Bình Chánh',       5, 'https://picsum.photos/seed/ocop-ncc-12/800/500', 'TU_CHOI', 'Ảnh giấy chứng nhận OCOP không đọc được, cần nộp lại bản rõ nét.', 1, '2026-09-25 09:00+07', 2, '2026-09-21 09:00+07');

-- Gắn hồ sơ với tài khoản nhà cung cấp (đăng nhập app Client).
UPDATE suppliers SET account_id = nd.id
FROM users nd
WHERE (suppliers.id, nd.email) IN ((1, 'ncc1@ocop.example'), (11, 'ncc11@ocop.example'));

-- Mỗi nhà cung cấp có một chứng nhận OCOP và một chứng nhận an toàn thực phẩm.
-- Chứng nhận OCOP của nhà cung cấp 10 đã hết hạn (dùng để thử chức năng mở rộng).
INSERT INTO certificates (supplier_id, certificate_type, certificate_number, issued_on, expires_on, image_url)
SELECT n,
       'OCOP',
       'MAU-OCOP-' || lpad(n::text, 3, '0'),
       DATE '2024-03-01' + (n * 10),
       CASE WHEN n = 10 THEN DATE '2026-06-30' ELSE DATE '2027-03-01' + (n * 10) END,
       'https://picsum.photos/seed/ocop-cn-ocop-' || n || '/600/800'
FROM generate_series(1, 12) AS n
UNION ALL
SELECT n,
       'ATTP',
       'MAU-ATTP-' || lpad(n::text, 3, '0'),
       DATE '2025-01-15' + (n * 5),
       DATE '2028-01-15' + (n * 5),
       'https://picsum.photos/seed/ocop-cn-attp-' || n || '/600/800'
FROM generate_series(1, 12) AS n;

-- ---------------------------------------------------------------------------
-- Sản phẩm: 12 nhà cung cấp x 5 = 60 sản phẩm.
-- Sản phẩm của NCC 1–10 phần lớn đã duyệt; 3 sản phẩm chờ duyệt/bị từ chối;
-- sản phẩm của NCC 11–12 chưa được duyệt.
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE sample_products (
  stt INTEGER, ncc INTEGER, name TEXT, don_vi TEXT, price_vnd BIGINT, ocop_rating SMALLINT, description TEXT
) ON COMMIT DROP;

INSERT INTO sample_products VALUES
  ( 1,  1, 'Khô cá dứa 500 g',                    'gói',  320000, 4, 'Cá dứa làm sạch, phơi nắng tự nhiên.'),
  ( 2,  1, 'Khô cá dứa một nắng 250 g',           'gói',  180000, 4, 'Cá dứa phơi một nắng, giữ độ mềm.'),
  ( 3,  1, 'Khô cá đù 500 g',                     'gói',  150000, 3, 'Cá đù phơi khô, đóng gói hút chân không.'),
  ( 4,  1, 'Tôm khô Cần Giờ 250 g',               'gói',  260000, 4, 'Tôm đất luộc, phơi và tách vỏ.'),
  ( 5,  1, 'Mắm ruốc Cần Giờ 300 g',              'hũ',    70000, 3, 'Ruốc ủ muối theo cách truyền thống.'),
  ( 6,  2, 'Muối hạt sạch 1 kg',                  'gói',   25000, 3, 'Muối biển kết tinh trên ruộng trải bạt.'),
  ( 7,  2, 'Muối tôm 200 g',                      'hũ',    45000, 3, 'Muối rang cùng tôm khô và ớt.'),
  ( 8,  2, 'Muối ớt xanh 250 g',                  'hũ',    50000, 3, 'Muối xay cùng ớt xanh và lá chanh.'),
  ( 9,  2, 'Muối biển rang 500 g',                'gói',   30000, 3, 'Muối hạt rang khô.'),
  (10,  2, 'Muối hồng thảo mộc 300 g',            'hũ',    60000, 4, 'Muối phối thảo mộc sấy.'),
  (11,  3, 'Yến thô 50 g',                        'hộp', 1500000, 5, 'Tổ yến nhà nuôi, chưa làm sạch lông.'),
  (12,  3, 'Yến tinh chế 50 g',                   'hộp', 2200000, 5, 'Tổ yến đã làm sạch, định hình.'),
  (13,  3, 'Nước yến đường phèn hộp 6 lọ',        'hộp',  180000, 4, 'Yến chưng đường phèn, lọ 70 ml.'),
  (14,  3, 'Yến chưng hạt sen hộp 6 lọ',          'hộp',  210000, 4, 'Yến chưng cùng hạt sen.'),
  (15,  3, 'Chân yến 100 g',                      'hộp', 1200000, 4, 'Phần chân tổ yến đã làm sạch.'),
  (16,  4, 'Rau muống thủy canh 500 g',           'bó',    25000, 3, 'Trồng thủy canh trong nhà màng.'),
  (17,  4, 'Cải ngọt hữu cơ 500 g',               'bó',    30000, 3, 'Canh tác theo hướng hữu cơ.'),
  (18,  4, 'Dưa leo baby 1 kg',                   'túi',   45000, 3, 'Dưa leo trồng nhà màng.'),
  (19,  4, 'Nấm bào ngư 500 g',                   'túi',   50000, 3, 'Nấm trồng trên giá thể mùn cưa.'),
  (20,  4, 'Rau má sấy lạnh 100 g',               'gói',   60000, 4, 'Rau má sấy lạnh, nghiền bột.'),
  (21,  5, 'Sữa bò tươi 1 lít',                   'chai',  38000, 4, 'Sữa bò tươi thanh trùng trong ngày.'),
  (22,  5, 'Sữa chua nếp cẩm hộp 6 hũ',           'hộp',   60000, 4, 'Sữa chua lên men tự nhiên cùng nếp cẩm.'),
  (23,  5, 'Bánh sữa Củ Chi 250 g',               'hộp',   70000, 3, 'Bánh sữa cô đặc từ sữa bò tươi.'),
  (24,  5, 'Phô mai tươi 200 g',                  'hộp',   85000, 3, 'Phô mai tươi làm từ sữa bò địa phương.'),
  (25,  5, 'Sữa bò thanh trùng 500 ml',           'chai',  22000, 3, 'Sữa thanh trùng, bảo quản lạnh.'),
  (26,  6, 'Bánh tráng phơi sương 500 g',         'gói',   55000, 4, 'Bánh tráng nướng rồi phơi sương đêm.'),
  (27,  6, 'Bánh tráng muối tôm 200 g',           'gói',   35000, 3, 'Bánh tráng kèm muối tôm.'),
  (28,  6, 'Bánh tráng nướng mè đen 10 cái',      'gói',   40000, 3, 'Bánh tráng mè đen nướng than.'),
  (29,  6, 'Bánh tráng trộn hộp',                 'hộp',   30000, 3, 'Bộ bánh tráng trộn kèm gia vị.'),
  (30,  6, 'Bánh tráng dẻo tôm 300 g',            'gói',   45000, 3, 'Bánh tráng dẻo phết sa tế tôm.'),
  (31,  7, 'Hạt điều rang muối 500 g',            'hũ',   220000, 4, 'Hạt điều rang củi, còn vỏ lụa.'),
  (32,  7, 'Hạt điều vỏ lụa 500 g',               'hũ',   210000, 4, 'Hạt điều sấy giữ vỏ lụa.'),
  (33,  7, 'Hạt điều tẩm mật ong 250 g',          'hũ',   130000, 3, 'Hạt điều rang tẩm mật ong.'),
  (34,  7, 'Bơ hạt điều 200 g',                   'hũ',   110000, 3, 'Bơ xay từ hạt điều rang.'),
  (35,  7, 'Sữa hạt điều 1 lít',                  'chai',  65000, 3, 'Sữa hạt điều không đường.'),
  (36,  8, 'Tiêu đen hạt 500 g',                  'gói',  140000, 4, 'Tiêu chín phơi khô, sàng chọn.'),
  (37,  8, 'Tiêu sọ trắng 250 g',                 'gói',  150000, 4, 'Tiêu ngâm bóc vỏ, phơi trắng.'),
  (38,  8, 'Tiêu xanh muối 300 g',                'hũ',    80000, 3, 'Tiêu xanh ngâm muối.'),
  (39,  8, 'Tiêu đỏ chín cây 200 g',              'gói',  180000, 5, 'Tiêu chín đỏ trên cây, hái chọn.'),
  (40,  8, 'Tiêu xay nguyên chất 100 g',          'hũ',    45000, 3, 'Tiêu đen xay mịn.'),
  (41,  9, 'Nước mắm cá cơm 40 độ đạm 500 ml',    'chai',  95000, 4, 'Nước mắm ủ chượp cá cơm.'),
  (42,  9, 'Mắm ruốc Long Hải 300 g',             'hũ',    60000, 3, 'Ruốc ủ muối truyền thống.'),
  (43,  9, 'Cá khô Long Hải 500 g',               'gói',  170000, 3, 'Cá biển phơi khô.'),
  (44,  9, 'Mực một nắng 500 g',                  'gói',  450000, 4, 'Mực câu phơi một nắng.'),
  (45,  9, 'Mắm cá thu 400 g',                    'hũ',   120000, 3, 'Chưa duyệt: chờ bổ sung phiếu kiểm nghiệm.'),
  (46, 10, 'Trà mãng cầu xiêm 200 g',             'hộp',   90000, 3, 'Trà túi lọc từ mãng cầu sấy.'),
  (47, 10, 'Mãng cầu xiêm sấy dẻo 250 g',         'gói',   75000, 4, 'Mãng cầu xiêm sấy dẻo ít đường.'),
  (48, 10, 'Dưa lưới Hóc Môn 1 trái',             'trái',  80000, 3, 'Dưa lưới trồng nhà màng.'),
  (49, 10, 'Bột mãng cầu xiêm 200 g',             'hộp',   95000, 3, 'Bột mãng cầu sấy lạnh.'),
  (50, 10, 'Nước cốt mãng cầu 500 ml',            'chai',  70000, 3, 'Bị từ chối: nhãn thiếu hạn sử dụng.'),
  (51, 11, 'Mật ong hoa nhãn 500 ml',             'chai', 180000, NULL, 'Mật ong nuôi ong lấy mật hoa nhãn.'),
  (52, 11, 'Mật ong hoa cà phê 500 ml',           'chai', 170000, NULL, 'Mật ong hoa cà phê.'),
  (53, 11, 'Phấn hoa 200 g',                      'hũ',   150000, NULL, 'Phấn hoa sấy khô.'),
  (54, 11, 'Sáp ong 100 g',                       'hộp',   90000, NULL, 'Sáp ong lọc sạch.'),
  (55, 11, 'Mật ong chanh đào 500 ml',            'chai', 160000, NULL, 'Chanh đào ngâm mật ong.'),
  (56, 12, 'Gạo thơm Bình Chánh 5 kg',            'bao',  150000, NULL, 'Gạo thơm vụ đông xuân.'),
  (57, 12, 'Gạo lứt đỏ 2 kg',                     'túi',   90000, NULL, 'Gạo lứt đỏ.'),
  (58, 12, 'Gạo nếp cái hoa vàng 2 kg',           'túi',   80000, NULL, 'Gạo nếp.'),
  (59, 12, 'Bột gạo lứt 500 g',                   'gói',   60000, NULL, 'Bột gạo lứt rang.'),
  (60, 12, 'Cốm gạo 300 g',                       'gói',   45000, NULL, 'Cốm gạo rang.');

INSERT INTO products
  (supplier_id, name, description, unit, price_vnd, ocop_rating, image_url,
   approval_status, rejection_reason, reviewed_by_user_id, reviewed_at, created_by_user_id, created_at)
SELECT ncc, name, description, don_vi, price_vnd,
       CASE WHEN stt IN (45, 50) OR ncc > 10 THEN NULL ELSE ocop_rating END,
       'https://picsum.photos/seed/ocop-sp-' || stt || '/600/600',
       CASE
         WHEN stt = 50 THEN 'TU_CHOI'
         WHEN stt = 45 OR ncc > 10 THEN 'CHO_DUYET'
         ELSE 'DA_DUYET'
       END,
       CASE WHEN stt = 50 THEN 'Nhãn sản phẩm thiếu hạn sử dụng.' END,
       CASE WHEN stt = 45 OR ncc > 10 THEN NULL ELSE 1 END,
       CASE WHEN stt = 45 OR ncc > 10 THEN NULL ELSE TIMESTAMPTZ '2026-02-10 09:00+07' + (stt || ' hours')::interval END,
       2,
       TIMESTAMPTZ '2026-02-06 09:00+07' + (stt || ' hours')::interval
FROM sample_products
ORDER BY stt;

-- ---------------------------------------------------------------------------
-- 100 lô cho 48 sản phẩm đã duyệt (mỗi sản phẩm 2–3 lô), mỗi lô 4 bước.
-- Mã truy xuất: 20 ký tự hex in hoa, sinh ngẫu nhiên.
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE approved_products ON COMMIT DROP AS
SELECT sp.id, sp.supplier_id, ncc.sourcing_region_id,
       row_number() OVER (ORDER BY sp.id) - 1 AS chi_so
FROM products sp
JOIN suppliers ncc ON ncc.id = sp.supplier_id
WHERE sp.approval_status = 'DA_DUYET' AND ncc.approval_status = 'DA_DUYET';

INSERT INTO production_batches
  (product_id, traceability_code, produced_on, expires_on, quantity, available_quantity,
   sourcing_region_id, producer_name, site_image_url, notes, created_by_user_id, created_at)
SELECT sp.id,
       upper(substr(md5(gen_random_uuid()::text), 1, 20)),
       DATE '2026-03-01' + i,
       DATE '2026-03-01' + i + 365,
       100 + (i * 37) % 200,
       100 + (i * 37) % 200,
       -- Lô 7, 27, 47... lấy nguyên liệu từ vùng khác để minh họa doanh số theo vùng của lô.
       CASE WHEN i % 20 = 7 THEN (sp.sourcing_region_id % 4) + 1 ELSE sp.sourcing_region_id END,
       'Tổ sản xuất ' || chr(65 + (i % 5)) || ' (mẫu)',
       'https://picsum.photos/seed/ocop-lo-' || i || '/800/500',
       'Lô mẫu số ' || i,
       2,
       TIMESTAMPTZ '2026-03-01 08:00+07' + (i || ' days')::interval
FROM generate_series(1, 100) AS i
JOIN approved_products sp ON sp.chi_so = (i - 1) % (SELECT count(*) FROM approved_products)
ORDER BY i;

INSERT INTO traceability_steps (batch_id, position, name, description, occurred_at, image_url)
SELECT lo.id, b.position, b.name,
       b.name || ' cho ' || sp.name || ' – ' || lo.notes || ' (dữ liệu mẫu).',
       lo.produced_on::timestamp AT TIME ZONE 'Asia/Ho_Chi_Minh' + b.lech,
       'https://picsum.photos/seed/ocop-lo-' || lo.id || '-b' || b.position || '/800/500'
FROM production_batches lo
JOIN products sp ON sp.id = lo.product_id
CROSS JOIN (VALUES
  (1, 'Thu hoạch',  INTERVAL '-3 days 7 hours'),
  (2, 'Sơ chế',     INTERVAL '-2 days 8 hours'),
  (3, 'Đóng gói',   INTERVAL '9 hours'),
  (4, 'Kiểm nghiệm',INTERVAL '2 days 10 hours')
) AS b (position, name, lech)
ORDER BY lo.id, b.position;

-- ---------------------------------------------------------------------------
-- 50 đơn hàng của 5 khách, mỗi đơn 1–3 dòng; mỗi dòng ghi lô thực tế đã giao.
-- ---------------------------------------------------------------------------
INSERT INTO orders
  (customer_id, status, delivery_method, delivery_fee_vnd, subtotal_vnd, total_vnd,
   recipient_name, recipient_phone, delivery_address, created_at, updated_at)
SELECT 3 + (n % 5),
       (ARRAY['DA_NHAN','DA_NHAN','DA_NHAN','DA_NHAN','DA_GIAO','DA_GIAO',
              'DANG_GIAO','DA_XAC_NHAN','CHO_XAC_NHAN','DA_HUY'])[(n % 10) + 1],
       (ARRAY['TIEU_CHUAN','NHANH','NHAN_TAI_CHO'])[(n % 3) + 1],
       (ARRAY[30000, 50000, 0])[(n % 3) + 1],
       0,
       (ARRAY[30000, 50000, 0])[(n % 3) + 1],
       'Khách mẫu ' || (1 + n % 5),
       '091100000' || (1 + n % 5),
       (ARRAY['Quận 1', 'Quận 3', 'TP. Thủ Đức', 'Quận 7', 'TP. Vũng Tàu'])[(n % 5) + 1]
         || ', địa chỉ mẫu số ' || n,
       TIMESTAMPTZ '2026-07-01 10:00+07' + (n * 42 || ' hours')::interval,
       TIMESTAMPTZ '2026-07-01 10:00+07' + (n * 42 + 30 || ' hours')::interval
FROM generate_series(1, 50) AS n
ORDER BY n;

INSERT INTO order_items (order_id, product_id, batch_id, quantity, unit_price_vnd)
SELECT dh.id, lo.product_id, lo.id, 1 + (dh.id + k) % 3, sp.price_vnd
FROM orders dh
CROSS JOIN generate_series(1, 3) AS k
JOIN production_batches lo ON lo.id = ((dh.id * 7 + k * 13) % 100) + 1
JOIN products sp ON sp.id = lo.product_id
WHERE k <= 1 + dh.id % 3
ORDER BY dh.id, k;

UPDATE orders dh
SET subtotal_vnd = t.subtotal_vnd,
    total_vnd = t.subtotal_vnd + dh.delivery_fee_vnd
FROM (
  SELECT order_id, sum(quantity * unit_price_vnd) AS subtotal_vnd
  FROM order_items GROUP BY order_id
) t
WHERE t.order_id = dh.id;

-- Trừ tồn của lô theo các đơn chưa hủy.
UPDATE production_batches lo
SET available_quantity = lo.quantity - t.da_ban
FROM (
  SELECT ct.batch_id, sum(ct.quantity) AS da_ban
  FROM order_items ct
  JOIN orders dh ON dh.id = ct.order_id
  WHERE dh.status <> 'DA_HUY'
  GROUP BY ct.batch_id
) t
WHERE t.batch_id = lo.id;

-- Lịch sử trạng thái: đi lần lượt từ CHO_XAC_NHAN tới trạng thái hiện tại.
INSERT INTO order_status_history (order_id, status, notes, changed_by_user_id, changed_at)
SELECT dh.id, s.status, 'Dữ liệu mẫu',
       CASE WHEN s.status IN ('CHO_XAC_NHAN', 'DA_NHAN') THEN dh.customer_id ELSE 2 END,
       dh.created_at + ((s.buoc - 1) * 6 || ' hours')::interval
FROM orders dh
CROSS JOIN LATERAL unnest(
  CASE dh.status
    WHEN 'DA_HUY' THEN ARRAY['CHO_XAC_NHAN', 'DA_HUY']
    ELSE (ARRAY['CHO_XAC_NHAN','DA_XAC_NHAN','DANG_GIAO','DA_GIAO','DA_NHAN'])[1:
           array_position(ARRAY['CHO_XAC_NHAN','DA_XAC_NHAN','DANG_GIAO','DA_GIAO','DA_NHAN'], dh.status)]
  END
) WITH ORDINALITY AS s (status, buoc)
ORDER BY dh.id, s.buoc;

-- ---------------------------------------------------------------------------
-- Tương tác: đánh giá cho đơn đã nhận, báo cáo vi phạm, yêu thích, theo dõi, giỏ.
-- ---------------------------------------------------------------------------
INSERT INTO reviews (customer_id, product_id, order_id, rating, comment, created_at)
SELECT DISTINCT ON (dh.id)
       dh.customer_id, ct.product_id, dh.id, 3 + dh.id % 3,
       (ARRAY['Đúng mô tả, đóng gói cẩn thận.', 'Hàng tốt, giao hơi chậm.', 'Rất hài lòng, sẽ mua lại.'])[(dh.id % 3) + 1],
       dh.updated_at + INTERVAL '1 day'
FROM orders dh
JOIN order_items ct ON ct.order_id = dh.id
WHERE dh.status = 'DA_NHAN'
ORDER BY dh.id, ct.id;

INSERT INTO review_images (review_id, image_url)
SELECT id, 'https://picsum.photos/seed/ocop-dg-' || id || '/600/600'
FROM reviews WHERE id % 2 = 1;

INSERT INTO issue_reports
  (reporter_id, product_id, batch_id, report_type, description, image_url, status,
   resolution, handled_by_user_id, handled_at, created_at)
SELECT dh.customer_id, ct.product_id, ct.batch_id,
       (ARRAY['SAI_MO_TA', 'HANG_GIA', 'SAI_MO_TA', 'KHAC', 'HANG_GIA'])[r.stt],
       (ARRAY['Trọng lượng thực tế thấp hơn trên nhãn.',
              'Tem QR trên bao bì bị dán đè, nghi hàng giả.',
              'Màu sắc khác ảnh mô tả.',
              'Bao bì bị rách khi nhận.',
              'Mùi vị khác lần mua trước.'])[r.stt],
       'https://picsum.photos/seed/ocop-bc-' || r.stt || '/600/600',
       (ARRAY['MOI', 'DANG_XU_LY', 'DA_XU_LY', 'BAC_BO', 'MOI'])[r.stt],
       (ARRAY[NULL, NULL, 'Đã yêu cầu nhà cung cấp cập nhật ảnh mô tả.',
              'Lỗi do vận chuyển, không phải hàng giả.', NULL])[r.stt],
       CASE WHEN r.stt IN (2, 3, 4) THEN 2 END,
       CASE WHEN r.stt IN (3, 4) THEN dh.updated_at + INTERVAL '3 days' END,
       dh.updated_at + INTERVAL '2 days'
FROM (VALUES (1, 1), (2, 2), (3, 3), (4, 4), (5, 11)) AS r (stt, order_id)
JOIN orders dh ON dh.id = r.order_id
JOIN LATERAL (
  SELECT product_id, batch_id FROM order_items WHERE order_id = dh.id ORDER BY id LIMIT 1
) ct ON TRUE
ORDER BY r.stt;

INSERT INTO product_favorites (user_id, product_id)
SELECT u, sp FROM generate_series(3, 7) AS u
CROSS JOIN LATERAL (VALUES (1 + (u * 7) % 44), (1 + (u * 11) % 44), (11)) AS v (sp)
ON CONFLICT DO NOTHING;

INSERT INTO supplier_follows (user_id, supplier_id)
SELECT u, n FROM generate_series(3, 7) AS u
CROSS JOIN LATERAL (VALUES (1 + u % 10), (3)) AS v (n)
ON CONFLICT DO NOTHING;

INSERT INTO cart_items (user_id, product_id, quantity) VALUES
  (3, 1, 2), (3, 31, 1), (4, 12, 1);

COMMIT;
