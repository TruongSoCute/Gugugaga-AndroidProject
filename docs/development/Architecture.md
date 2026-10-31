# Kiến trúc mã nguồn

Nguồn và cách phân biệt yêu cầu: xem [README](../README.md).

**Đề xuất.** Đề không quy định kiến trúc mã nguồn; đây là lựa chọn của nhóm và cần cả nhóm thống nhất. Backend hiện đã theo kiến trúc này, và quy tắc phụ thuộc được **kiểm tra bằng máy** trong `npm test`.

## Backend: miền nghiệp vụ phân tầng

Backend chia theo **miền nghiệp vụ** (`backend/src/domains/<miền>/`). Trong mỗi miền, code chỉ phụ thuộc theo một chiều:

```
types → config → repo → service → routes → index
```

Các mối quan tâm xuyên suốt (CSDL, JWT/vai trò, bcrypt, sinh số ngẫu nhiên, log, xử lý lỗi HTTP) chỉ đi vào qua một cửa là `providers/`. Hàm thuần dùng chung nằm trong `utils/`. `app.js` (App Wiring) tạo Providers, ghép các miền và gắn đường dẫn.

```
backend/src/
  app.js, server.js, config.js   App Wiring
  providers/   db (pg, transaction), auth (JWT, vai trò), password (bcrypt),
               random (crypto), logger, http (lỗi, 404)
  utils/       errors, validator, sql, http
  domains/
    he-thong/  tai-khoan/  danh-muc/  nha-cung-cap/  san-pham/  truy-xuat/
      types.js  repo.js  service.js  routes.js  index.js
```

| Tầng | Chứa gì | Được dùng |
| --- | --- | --- |
| `types` | Kiểm tra dữ liệu vào, hằng trạng thái; hàm thuần | `utils` |
| `config` | Cấu hình riêng của miền, nếu có (tùy chọn) | `types`, `utils` |
| `repo` | Chỉ câu SQL tham số hóa `$1, $2…`; nhận `q` là pool hoặc client transaction | `types`, `config`, `utils` |
| `service` | Quy tắc nghiệp vụ, transaction (`db.withTransaction`), lỗi 404/409 | tầng trước, `utils`, `providers` |
| `routes` | Runtime + UI của backend: đọc request, gắn quyền (`auth.nhanSu`, `auth.quanTri`), gọi service, trả JSON | `types`, `service`, `utils`, `providers`, `express` |
| `index` | Tạo service và router cho `app.js` | các tầng trong miền, `providers` |

## Quy tắc bắt buộc với code backend

`backend/scripts/check-architecture.js` kiểm tra các quy tắc sau. Mỗi quy tắc có mã lỗi tương ứng.

1. Trong một miền, mỗi tầng chỉ được require tầng **đứng trước** nó (`TANG_NGUOC`).
2. `routes` không require `repo`; truy cập dữ liệu phải qua `service` (`ROUTES_GOI_REPO`).
3. Chỉ `service`, `routes` và `index` được dùng `providers`; `types`, `config` và `repo` thì không (`PROVIDER_SAI_TANG`).
4. Miền không require miền khác. Nếu cần service của miền khác, truyền nó vào ở `app.js` (`LIEN_MIEN`). Miền cũng không require App Wiring (`MIEN_GOI_WIRING`).
5. `utils` chỉ require `utils` và không dùng thư viện nào (`UTILS_PHU_THUOC`). `providers` chỉ require `providers` và `utils` (`PROVIDER_PHU_THUOC`).
6. `pg` chỉ dùng trong `providers/db.js`, `jsonwebtoken` trong `providers/auth.js`, `bcryptjs` trong `providers/password.js`, `crypto` trong `providers/random.js`. Trong miền, chỉ `routes` được dùng `express`; không dùng thư viện ngoài nào khác (`THU_VIEN_SAI_CHO`).
7. Không `require` động, không dùng `import`/`export` ES module (`REQUIRE_DONG`, `IMPORT_ES`). Không require file ngoài `src` (`NGOAI_SRC`).
8. Mọi file `.js` trong `src` phải thuộc một vị trí ở trên; tên file trong miền chỉ là `types`, `config`, `repo`, `service`, `routes` hoặc `index` (`TEP_NGOAI_KIEN_TRUC`).

Chạy riêng phần kiểm tra này (không cần CSDL):

```bash
cd backend && npm run check:arch
```

Khi gặp vi phạm, **sửa code cho đúng tầng**. Không nới quy tắc, không sửa script kiểm tra và không thêm ngoại lệ để vượt qua. Muốn đổi quy tắc thì cả nhóm phải thống nhất trước, rồi cập nhật cùng lúc tài liệu này, `check-architecture.js` và `test/kien-truc.test.js`.

## Cách thêm hoặc sửa chức năng backend

1. Xác định chức năng thuộc miền nào. Miền mới (ví dụ `don-hang`) thì tạo thư mục `domains/don-hang/`.
2. Viết từ tầng trước ra tầng sau:
   - `types.js`: hàm `parse...` kiểm tra body/query bằng `utils/validator`; chỉ nhận trường được khai báo, nên trường lạ như `vaiTro` hay `trangThai` do client gửi bị bỏ qua.
   - `repo.js`: mỗi câu SQL là một hàm `(q, ...)`, luôn dùng tham số `$n`.
   - `service.js`: `module.exports = function createXService({ db, ... }, deps)`. Kiểm tra quy tắc nghiệp vụ và dùng `db.withTransaction` khi nhiều thay đổi phải cùng thành công.
   - `routes.js`: đọc request, gọi `parse...`, gắn quyền, gọi service, trả JSON với mã HTTP phù hợp.
   - `index.js`: tạo service và router.
3. Ghép trong `app.js`. Nếu miền cần service của miền khác, truyền vào qua tham số `deps`.
4. Thêm test trong `backend/test/` cho các trường hợp thành công, sai quyền, dữ liệu không hợp lệ và không tìm thấy. Chạy `npm test`; lệnh này đã gồm kiểm tra kiến trúc.
5. Cập nhật [API](API.md) và các tài liệu liên quan cho khớp hành vi thực tế.

## Lý do áp dụng

- Miền đơn hàng sắp làm có nhiều quy tắc: khóa dòng, trừ tồn, gán lô, chuyển trạng thái. Tách `repo`/`service` giúp code dễ đọc và dễ kiểm thử.
- Mỗi thành viên phụ trách một miền, nên ít xung đột merge và mỗi người có commit rõ ràng.
- Khi bảo vệ, dễ trả lời câu hỏi: SQL nằm ở `repo`, quy tắc nghiệp vụ ở `service`, quyền ở `providers/auth` và nơi gắn quyền trong `routes`.
- Kiểm tra bằng máy giữ cho code do nhiều người và AI viết vẫn theo cùng một quy tắc.

## Hai app (Đề xuất, không kiểm tra bằng máy)

Hai app không quyết định nghiệp vụ, vì backend kiểm tra mọi quyền và trạng thái. Do đó app không cần tầng service.

- **Android Java/XML:** làm theo kỹ thuật đã học trong lab, xem [Labs Android](Labs_Android.md).
  - **Màn hình:** một `MainActivity` chứa các Fragment và `BottomNavigationView` (A8). Chi tiết mở bằng `newInstance` + arguments và `addToBackStack`. Fragment trao đổi kết quả qua Fragment Result API.
  - **Thư mục:** `model/` (lớp dữ liệu, tiền dùng `int`), `data/` (`ApiService` Retrofit, `ApiClient`, `TokenStore`, các repository mỏng bọc `ApiService`), `ui/<miền>/` (Fragment, Adapter RecyclerView + ViewHolder).
  - **Providers của app:** `ApiClient` (interceptor gắn token, timeout 90 giây) và `TokenStore` (`SharedPreferences`) theo Phụ lục 2. Nhận 401 thì đăng xuất về màn hình đăng nhập.
  - **Gọi API:** Fragment/Activity gọi qua repository, xử lý đủ đang tải / thành công / lỗi mạng.
  - **ViewModel:** C.1 không bắt buộc. Lab A2 giới thiệu ViewModel là thứ "sẽ dùng ở đồ án", còn A8 dùng để giữ trạng thái tab. Đề xuất: dùng ViewModel giữ danh sách tải từ API để khỏi gọi lại khi xoay; dữ liệu form đang nhập dở vẫn lưu bằng Bundle (`onSaveInstanceState`), vì ViewModel mất khi tiến trình bị hủy.
- **Flutter:** `lib/data/` (`ApiClient` dùng chung, `TokenStore` trên `shared_preferences`, các `*_repository.dart`), `models/`, `screens/`, `widgets/`, `utils/`. Màn hình không gọi `http`/`dio` trực tiếp mà qua repository.
