
package vn.edu.vhu.ltdd.gugugaga.admin.ui.nhacungcap;

import android.app.DatePickerDialog;
import android.net.Uri;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.fragment.app.Fragment;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.data.AnhRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.data.KetQuaApi;
import vn.edu.vhu.ltdd.gugugaga.admin.data.NhaCungCapRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.model.KetQuaTaiAnh;
import vn.edu.vhu.ltdd.gugugaga.admin.model.NhaCungCap;
import vn.edu.vhu.ltdd.gugugaga.admin.model.VungNguyenLieu;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauTaoNhaCungCap;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.MainActivity;

public class TaoNhaCungCapFragment extends Fragment {

    private EditText edtTenNhaCungCap;
    private EditText edtNguoiDaiDien;
    private EditText edtSoDienThoai;
    private EditText edtDiaChi;

    private Spinner spVungNguyenLieu;
    private TextView tvTrangThaiTaiVung;

    private ImageView imgAnhCoSo;
    private Button btnChonAnhCoSo;
    private Button btnThemChungNhan;
    private Button btnLuuNhaCungCap;

    private LinearLayout layoutDanhSachChungNhan;
    private TextView tvChuaCoChungNhan;

    private AnhRepository anhRepository;
    private NhaCungCapRepository nhaCungCapRepository;

    private String anhCoSoUrl;

    private final List<VungNguyenLieu> danhSachVung =
            new ArrayList<>();

    private final List<YeuCauTaoNhaCungCap.ChungNhan> danhSachChungNhan =
            new ArrayList<>();

    private final ExecutorService executor =
            Executors.newSingleThreadExecutor();

    private ActivityResultLauncher<String> chonAnhLauncher;
    private ActivityResultLauncher<String> chonAnhChungNhanLauncher;

    // Chứng nhận đang được chọn ảnh
    private YeuCauTaoNhaCungCap.ChungNhan chungNhanDangChonAnh;

    // Số ảnh chứng nhận đang upload
    private int soAnhChungNhanDangTai = 0;

    private boolean dangTaiVung = false;

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Chọn ảnh cơ sở
        chonAnhLauncher = registerForActivityResult(
                new ActivityResultContracts.GetContent(),
                uri -> {
                    if (uri != null) {
                        xuLyAnh(uri);
                    }
                }
        );

        // Chọn ảnh cho từng chứng nhận
        chonAnhChungNhanLauncher = registerForActivityResult(
                new ActivityResultContracts.GetContent(),
                uri -> {
                    YeuCauTaoNhaCungCap.ChungNhan chungNhan =
                            chungNhanDangChonAnh;

                    chungNhanDangChonAnh = null;

                    if (uri != null && chungNhan != null) {
                        xuLyAnhChungNhan(uri, chungNhan);
                    }
                }
        );

        if (savedInstanceState != null) {
            anhCoSoUrl = savedInstanceState.getString("anhCoSoUrl");
        }
    }

    @Nullable
    @Override
    public View onCreateView(
            @NonNull LayoutInflater inflater,
            @Nullable ViewGroup container,
            @Nullable Bundle savedInstanceState
    ) {
        return inflater.inflate(
                R.layout.fragment_tao_nha_cung_cap,
                container,
                false
        );
    }

    @Override
    public void onViewCreated(
            @NonNull View view,
            @Nullable Bundle savedInstanceState
    ) {
        super.onViewCreated(view, savedInstanceState);

        ((MainActivity) requireActivity()).datTieuDe(
                R.string.tieu_de_nha_cung_cap
        );

        anhRepository = new AnhRepository(requireContext());

        nhaCungCapRepository =
                new NhaCungCapRepository(requireContext());

        edtTenNhaCungCap =
                view.findViewById(R.id.edtTenNhaCungCap);

        edtNguoiDaiDien =
                view.findViewById(R.id.edtNguoiDaiDien);

        edtSoDienThoai =
                view.findViewById(R.id.edtSoDienThoai);

        edtDiaChi =
                view.findViewById(R.id.edtDiaChi);

        spVungNguyenLieu =
                view.findViewById(R.id.spVungNguyenLieu);

        tvTrangThaiTaiVung =
                view.findViewById(R.id.tvTrangThaiTaiVung);

        imgAnhCoSo =
                view.findViewById(R.id.imgAnhCoSo);

        btnChonAnhCoSo =
                view.findViewById(R.id.btnChonAnhCoSo);

        btnThemChungNhan =
                view.findViewById(R.id.btnThemChungNhan);

        btnLuuNhaCungCap =
                view.findViewById(R.id.btnLuuNhaCungCap);

        layoutDanhSachChungNhan =
                view.findViewById(R.id.layoutDanhSachChungNhan);

        tvChuaCoChungNhan =
                view.findViewById(R.id.tvChuaCoChungNhan);

        btnChonAnhCoSo.setOnClickListener(v ->
                chonAnhLauncher.launch("image/*")
        );

        btnThemChungNhan.setOnClickListener(v ->
                hienDialogThemChungNhan()
        );

        btnLuuNhaCungCap.setOnClickListener(v ->
                luuHoSo()
        );

        hienDanhSachChungNhan();
        taiDanhSachVung();
    }

    // =====================================
    // TẢI DANH SÁCH VÙNG NGUYÊN LIỆU
    // =====================================

    private void taiDanhSachVung() {

        dangTaiVung = true;

        tvTrangThaiTaiVung.setText(
                "Đang tải danh sách vùng nguyên liệu..."
        );

        spVungNguyenLieu.setEnabled(false);

        nhaCungCapRepository.dsVungNguyenLieu(
                new KetQuaApi<List<VungNguyenLieu>>() {

                    @Override
                    public void thanhCong(
                            List<VungNguyenLieu> ketQua
                    ) {
                        if (!isAdded()) return;

                        dangTaiVung = false;
                        danhSachVung.clear();

                        if (ketQua == null || ketQua.isEmpty()) {
                            tvTrangThaiTaiVung.setText(
                                    "Chưa có vùng nguyên liệu."
                            );

                            spVungNguyenLieu.setEnabled(false);
                            return;
                        }

                        for (VungNguyenLieu vung : ketQua) {
                            if (vung != null
                                    && vung.id > 0
                                    && vung.ten != null
                                    && !vung.ten.trim().isEmpty()) {

                                danhSachVung.add(vung);
                            }
                        }

                        if (danhSachVung.isEmpty()) {
                            tvTrangThaiTaiVung.setText(
                                    "Dữ liệu vùng nguyên liệu không hợp lệ."
                            );

                            spVungNguyenLieu.setEnabled(false);
                            return;
                        }

                        ArrayAdapter<VungNguyenLieu> adapter =
                                new ArrayAdapter<>(
                                        requireContext(),
                                        android.R.layout.simple_spinner_item,
                                        danhSachVung
                                );

                        adapter.setDropDownViewResource(
                                android.R.layout.simple_spinner_dropdown_item
                        );

                        spVungNguyenLieu.setAdapter(adapter);
                        spVungNguyenLieu.setEnabled(true);

                        tvTrangThaiTaiVung.setText(
                                "Đã tải " + danhSachVung.size()
                                        + " vùng nguyên liệu."
                        );
                    }

                    @Override
                    public void loi(String thongDiep) {
                        if (!isAdded()) return;

                        dangTaiVung = false;
                        spVungNguyenLieu.setEnabled(false);

                        tvTrangThaiTaiVung.setText(
                                "Không tải được danh sách vùng."
                        );

                        Toast.makeText(
                                requireContext(),
                                thongDiep,
                                Toast.LENGTH_LONG
                        ).show();
                    }

                    @Override
                    public void hetPhien() {
                        if (!isAdded()) return;

                        dangTaiVung = false;
                        spVungNguyenLieu.setEnabled(false);

                        tvTrangThaiTaiVung.setText(
                                "Không thể tải danh sách vùng."
                        );

                        Toast.makeText(
                                requireContext(),
                                "Không thể tải danh sách vùng nguyên liệu.",
                                Toast.LENGTH_LONG
                        ).show();
                    }
                }
        );
    }

    // =====================================
    // CHỌN VÀ UPLOAD ẢNH CƠ SỞ
    // =====================================

    private void xuLyAnh(Uri uri) {
        try {
            imgAnhCoSo.setImageURI(uri);
            imgAnhCoSo.setVisibility(View.VISIBLE);

            String mimeType = requireContext()
                    .getContentResolver()
                    .getType(uri);

            if (!laAnhHopLe(mimeType)) {
                Toast.makeText(
                        requireContext(),
                        "Chỉ hỗ trợ ảnh JPG, PNG hoặc WEBP.",
                        Toast.LENGTH_SHORT
                ).show();

                return;
            }

            btnChonAnhCoSo.setEnabled(false);
            btnChonAnhCoSo.setText("Đang tải ảnh lên...");

            executor.execute(() -> {
                try (
                        InputStream input = requireContext()
                                .getContentResolver()
                                .openInputStream(uri);

                        ByteArrayOutputStream output =
                                new ByteArrayOutputStream()
                ) {
                    if (input == null) {
                        throw new IOException("Không đọc được ảnh.");
                    }

                    byte[] buffer = new byte[8192];
                    int length;

                    while ((length = input.read(buffer)) != -1) {
                        output.write(buffer, 0, length);

                        if (output.size() > 5 * 1024 * 1024) {
                            throw new IOException(
                                    "Ảnh không được vượt quá 5 MB."
                            );
                        }
                    }

                    byte[] data = output.toByteArray();

                    if (!isAdded()) return;

                    requireActivity().runOnUiThread(() ->
                            anhRepository.taiLen(
                                    data,
                                    mimeType,
                                    "nha-cung-cap",
                                    new KetQuaApi<KetQuaTaiAnh>() {

                                        @Override
                                        public void thanhCong(
                                                KetQuaTaiAnh ketQua
                                        ) {
                                            if (!isAdded()) return;

                                            if (ketQua == null
                                                    || ketQua.url == null
                                                    || ketQua.url.trim().isEmpty()) {

                                                ketThucUploadAnhCoSo();

                                                Toast.makeText(
                                                        requireContext(),
                                                        "Máy chủ không trả về URL ảnh.",
                                                        Toast.LENGTH_LONG
                                                ).show();

                                                return;
                                            }

                                            anhCoSoUrl = ketQua.url;

                                            ketThucUploadAnhCoSo();

                                            Toast.makeText(
                                                    requireContext(),
                                                    "Upload ảnh thành công!",
                                                    Toast.LENGTH_SHORT
                                            ).show();
                                        }

                                        @Override
                                        public void loi(String thongDiep) {
                                            if (!isAdded()) return;

                                            ketThucUploadAnhCoSo();

                                            Toast.makeText(
                                                    requireContext(),
                                                    thongDiep,
                                                    Toast.LENGTH_LONG
                                            ).show();
                                        }

                                        @Override
                                        public void hetPhien() {
                                            if (!isAdded()) return;

                                            ketThucUploadAnhCoSo();

                                            Toast.makeText(
                                                    requireContext(),
                                                    "Phiên đăng nhập hết hạn.",
                                                    Toast.LENGTH_LONG
                                            ).show();
                                        }
                                    }
                            )
                    );

                } catch (Exception e) {
                    if (!isAdded()) return;

                    requireActivity().runOnUiThread(() -> {
                        if (!isAdded()) return;

                        ketThucUploadAnhCoSo();

                        Toast.makeText(
                                requireContext(),
                                e.getMessage() == null
                                        ? "Không thể upload ảnh."
                                        : e.getMessage(),
                                Toast.LENGTH_LONG
                        ).show();
                    });
                }
            });

        } catch (Exception e) {
            Toast.makeText(
                    requireContext(),
                    "Không thể đọc ảnh đã chọn.",
                    Toast.LENGTH_SHORT
            ).show();
        }
    }

    private boolean laAnhHopLe(String mimeType) {
        return mimeType != null
                && (mimeType.equals("image/jpeg")
                || mimeType.equals("image/png")
                || mimeType.equals("image/webp"));
    }

    private void ketThucUploadAnhCoSo() {
        btnChonAnhCoSo.setEnabled(true);
        btnChonAnhCoSo.setText("Chọn ảnh cơ sở");
    }

    // =====================================
    // CHỌN VÀ UPLOAD ẢNH CHỨNG NHẬN
    // =====================================

    private void xuLyAnhChungNhan(
            Uri uri,
            YeuCauTaoNhaCungCap.ChungNhan chungNhan
    ) {
        if (!danhSachChungNhan.contains(chungNhan)) {
            return;
        }

        String mimeType = requireContext()
                .getContentResolver()
                .getType(uri);

        if (!laAnhHopLe(mimeType)) {
            Toast.makeText(
                    requireContext(),
                    "Chỉ hỗ trợ ảnh JPG, PNG hoặc WEBP.",
                    Toast.LENGTH_SHORT
            ).show();

            return;
        }

        soAnhChungNhanDangTai++;

        Toast.makeText(
                requireContext(),
                "Đang tải ảnh chứng nhận lên...",
                Toast.LENGTH_SHORT
        ).show();

        executor.execute(() -> {
            try (
                    InputStream input = requireContext()
                            .getContentResolver()
                            .openInputStream(uri);

                    ByteArrayOutputStream output =
                            new ByteArrayOutputStream()
            ) {
                if (input == null) {
                    throw new IOException("Không đọc được ảnh.");
                }

                byte[] buffer = new byte[8192];
                int length;

                while ((length = input.read(buffer)) != -1) {
                    output.write(buffer, 0, length);

                    if (output.size() > 5 * 1024 * 1024) {
                        throw new IOException(
                                "Ảnh không được vượt quá 5 MB."
                        );
                    }
                }

                byte[] data = output.toByteArray();

                if (!isAdded()) return;

                requireActivity().runOnUiThread(() ->
                        anhRepository.taiLen(
                                data,
                                mimeType,
                                "nha-cung-cap",
                                new KetQuaApi<KetQuaTaiAnh>() {

                                    @Override
                                    public void thanhCong(
                                            KetQuaTaiAnh ketQua
                                    ) {
                                        if (!isAdded()) return;

                                        ketThucUploadAnhChungNhan();

                                        if (ketQua == null
                                                || ketQua.url == null
                                                || ketQua.url.trim().isEmpty()) {

                                            Toast.makeText(
                                                    requireContext(),
                                                    "Máy chủ không trả về URL ảnh.",
                                                    Toast.LENGTH_LONG
                                            ).show();

                                            return;
                                        }

                                        if (danhSachChungNhan.contains(chungNhan)) {
                                            chungNhan.anhUrl = ketQua.url;
                                            hienDanhSachChungNhan();
                                        }

                                        Toast.makeText(
                                                requireContext(),
                                                "Upload ảnh chứng nhận thành công!",
                                                Toast.LENGTH_SHORT
                                        ).show();
                                    }

                                    @Override
                                    public void loi(String thongDiep) {
                                        if (!isAdded()) return;

                                        ketThucUploadAnhChungNhan();

                                        Toast.makeText(
                                                requireContext(),
                                                thongDiep,
                                                Toast.LENGTH_LONG
                                        ).show();
                                    }

                                    @Override
                                    public void hetPhien() {
                                        if (!isAdded()) return;

                                        ketThucUploadAnhChungNhan();

                                        Toast.makeText(
                                                requireContext(),
                                                "Phiên đăng nhập hết hạn.",
                                                Toast.LENGTH_LONG
                                        ).show();
                                    }
                                }
                        )
                );

            } catch (Exception e) {
                if (!isAdded()) return;

                requireActivity().runOnUiThread(() -> {
                    if (!isAdded()) return;

                    ketThucUploadAnhChungNhan();

                    Toast.makeText(
                            requireContext(),
                            e.getMessage() == null
                                    ? "Không thể upload ảnh chứng nhận."
                                    : e.getMessage(),
                            Toast.LENGTH_LONG
                    ).show();
                });
            }
        });
    }

    private void ketThucUploadAnhChungNhan() {
        if (soAnhChungNhanDangTai > 0) {
            soAnhChungNhanDangTai--;
        }
    }

    // =====================================
    // THÊM CHỨNG NHẬN
    // =====================================

    private void hienDialogThemChungNhan() {

        LinearLayout form = new LinearLayout(requireContext());
        form.setOrientation(LinearLayout.VERTICAL);
        form.setPadding(40, 16, 40, 8);

        EditText edtLoai = new EditText(requireContext());
        edtLoai.setHint("Loại chứng nhận");
        edtLoai.setSingleLine(true);

        EditText edtSoHieu = new EditText(requireContext());
        edtSoHieu.setHint("Số hiệu chứng nhận");
        edtSoHieu.setSingleLine(true);

        Button btnNgayCap = new Button(requireContext());
        btnNgayCap.setText("Chọn ngày cấp");

        Button btnNgayHetHan = new Button(requireContext());
        btnNgayHetHan.setText(
                "Chọn ngày hết hạn (không bắt buộc)"
        );

        final String[] ngayCap = {null};
        final String[] ngayHetHan = {null};

        form.addView(edtLoai);
        form.addView(edtSoHieu);
        form.addView(btnNgayCap);
        form.addView(btnNgayHetHan);

        btnNgayCap.setOnClickListener(v ->
                chonNgay(ngay -> {
                    ngayCap[0] = ngay;
                    btnNgayCap.setText("Ngày cấp: " + ngay);
                })
        );

        btnNgayHetHan.setOnClickListener(v ->
                chonNgay(ngay -> {
                    ngayHetHan[0] = ngay;
                    btnNgayHetHan.setText("Ngày hết hạn: " + ngay);
                })
        );

        AlertDialog dialog = new AlertDialog.Builder(requireContext())
                .setTitle("Thêm chứng nhận")
                .setView(form)
                .setNegativeButton("Hủy", null)
                .setPositiveButton("Thêm", null)
                .create();

        dialog.setOnShowListener(d -> {
            dialog.getButton(AlertDialog.BUTTON_POSITIVE)
                    .setOnClickListener(v -> {

                        String loai = edtLoai.getText()
                                .toString().trim();

                        String soHieu = edtSoHieu.getText()
                                .toString().trim();

                        if (loai.isEmpty()) {
                            edtLoai.setError(
                                    "Vui lòng nhập loại chứng nhận"
                            );
                            return;
                        }

                        if (soHieu.isEmpty()) {
                            edtSoHieu.setError(
                                    "Vui lòng nhập số hiệu"
                            );
                            return;
                        }

                        if (ngayCap[0] == null) {
                            Toast.makeText(
                                    requireContext(),
                                    "Vui lòng chọn ngày cấp.",
                                    Toast.LENGTH_SHORT
                            ).show();
                            return;
                        }

                        if (ngayHetHan[0] != null
                                && ngayHetHan[0].compareTo(ngayCap[0]) <= 0) {

                            Toast.makeText(
                                    requireContext(),
                                    "Ngày hết hạn phải sau ngày cấp.",
                                    Toast.LENGTH_SHORT
                            ).show();
                            return;
                        }

                        YeuCauTaoNhaCungCap.ChungNhan chungNhan =
                                new YeuCauTaoNhaCungCap.ChungNhan();

                        chungNhan.loai = loai;
                        chungNhan.soHieu = soHieu;
                        chungNhan.ngayCap = ngayCap[0];
                        chungNhan.ngayHetHan = ngayHetHan[0];
                        chungNhan.anhUrl = null;

                        danhSachChungNhan.add(chungNhan);

                        hienDanhSachChungNhan();
                        dialog.dismiss();
                    });
        });

        dialog.show();
    }

    private interface NgayDaChon {
        void nhan(String ngay);
    }

    private void chonNgay(NgayDaChon callback) {

        Calendar calendar = Calendar.getInstance();

        DatePickerDialog picker = new DatePickerDialog(
                requireContext(),
                (datePicker, year, month, day) -> {
                    String ngay = String.format(
                            Locale.US,
                            "%04d-%02d-%02d",
                            year,
                            month + 1,
                            day
                    );

                    callback.nhan(ngay);
                },
                calendar.get(Calendar.YEAR),
                calendar.get(Calendar.MONTH),
                calendar.get(Calendar.DAY_OF_MONTH)
        );

        picker.show();
    }

    // =====================================
    // HIỂN THỊ DANH SÁCH CHỨNG NHẬN
    // =====================================

    private void hienDanhSachChungNhan() {

        layoutDanhSachChungNhan.removeAllViews();

        boolean rong = danhSachChungNhan.isEmpty();

        tvChuaCoChungNhan.setVisibility(
                rong ? View.VISIBLE : View.GONE
        );

        for (int i = 0; i < danhSachChungNhan.size(); i++) {

            YeuCauTaoNhaCungCap.ChungNhan cn =
                    danhSachChungNhan.get(i);

            LinearLayout item = new LinearLayout(requireContext());
            item.setOrientation(LinearLayout.VERTICAL);
            item.setPadding(20, 16, 20, 16);

            TextView tv = new TextView(requireContext());

            String noiDung =
                    "Chứng nhận " + (i + 1)
                            + "\nLoại: " + cn.loai
                            + "\nSố hiệu: " + cn.soHieu
                            + "\nNgày cấp: " + cn.ngayCap
                            + "\nNgày hết hạn: "
                            + (cn.ngayHetHan == null
                            ? "Không có"
                            : cn.ngayHetHan)
                            + "\nẢnh: "
                            + (cn.anhUrl == null
                            ? "Chưa có"
                            : "Đã tải lên");

            tv.setText(noiDung);
            tv.setTextSize(15);

            // Nút chọn hoặc đổi ảnh chứng nhận
            Button btnChonAnh = new Button(requireContext());

            btnChonAnh.setText(
                    cn.anhUrl == null
                            ? "Chọn ảnh chứng nhận"
                            : "Đổi ảnh chứng nhận"
            );

            btnChonAnh.setOnClickListener(v -> {
                chungNhanDangChonAnh = cn;
                chonAnhChungNhanLauncher.launch("image/*");
            });

            // Nút xóa chứng nhận
            Button btnXoa = new Button(requireContext());
            btnXoa.setText("Xóa chứng nhận");

            final int viTri = i;

            btnXoa.setOnClickListener(v -> {
                danhSachChungNhan.remove(viTri);
                hienDanhSachChungNhan();
            });

            item.addView(tv);
            item.addView(btnChonAnh);
            item.addView(btnXoa);

            layoutDanhSachChungNhan.addView(item);
        }
    }

    // =====================================
    // LƯU HỒ SƠ NHÀ CUNG CẤP
    // =====================================

    private void luuHoSo() {

        String ten = edtTenNhaCungCap.getText()
                .toString().trim();

        String nguoiDaiDien = edtNguoiDaiDien.getText()
                .toString().trim();

        String soDienThoai = edtSoDienThoai.getText()
                .toString().trim();

        String diaChi = edtDiaChi.getText()
                .toString().trim();

        if (ten.isEmpty()) {
            edtTenNhaCungCap.setError(
                    "Vui lòng nhập tên nhà cung cấp"
            );
            edtTenNhaCungCap.requestFocus();
            return;
        }

        if (nguoiDaiDien.isEmpty()) {
            edtNguoiDaiDien.setError(
                    "Vui lòng nhập người đại diện"
            );
            edtNguoiDaiDien.requestFocus();
            return;
        }

        if (soDienThoai.isEmpty()) {
            edtSoDienThoai.setError(
                    "Vui lòng nhập số điện thoại"
            );
            edtSoDienThoai.requestFocus();
            return;
        }

        if (diaChi.isEmpty()) {
            edtDiaChi.setError(
                    "Vui lòng nhập địa chỉ cơ sở"
            );
            edtDiaChi.requestFocus();
            return;
        }

        if (dangTaiVung) {
            Toast.makeText(
                    requireContext(),
                    "Đang tải danh sách vùng nguyên liệu, vui lòng chờ.",
                    Toast.LENGTH_SHORT
            ).show();
            return;
        }

        if (soAnhChungNhanDangTai > 0) {
            Toast.makeText(
                    requireContext(),
                    "Đang tải ảnh chứng nhận, vui lòng chờ.",
                    Toast.LENGTH_SHORT
            ).show();
            return;
        }

        if (danhSachVung.isEmpty()
                || spVungNguyenLieu.getSelectedItem() == null) {

            Toast.makeText(
                    requireContext(),
                    "Vui lòng tải và chọn vùng nguyên liệu hợp lệ.",
                    Toast.LENGTH_LONG
            ).show();
            return;
        }

        VungNguyenLieu vungDuocChon =
                (VungNguyenLieu) spVungNguyenLieu.getSelectedItem();

        if (vungDuocChon.id <= 0) {
            Toast.makeText(
                    requireContext(),
                    "Vùng nguyên liệu được chọn không hợp lệ.",
                    Toast.LENGTH_LONG
            ).show();
            return;
        }

        YeuCauTaoNhaCungCap yeuCau =
                new YeuCauTaoNhaCungCap();

        yeuCau.ten = ten;
        yeuCau.nguoiDaiDien = nguoiDaiDien;
        yeuCau.soDienThoai = soDienThoai;
        yeuCau.vungId = vungDuocChon.id;
        yeuCau.diaChi = diaChi;
        yeuCau.anhCoSoUrl = anhCoSoUrl;
        yeuCau.chungNhan =
                new ArrayList<>(danhSachChungNhan);

        btnLuuNhaCungCap.setEnabled(false);
        btnLuuNhaCungCap.setText("Đang lưu hồ sơ...");

        nhaCungCapRepository.taoHoSo(
                yeuCau,
                new KetQuaApi<NhaCungCap>() {

                    @Override
                    public void thanhCong(NhaCungCap ketQua) {
                        if (!isAdded()) return;

                        btnLuuNhaCungCap.setEnabled(true);
                        btnLuuNhaCungCap.setText("Lưu hồ sơ");

                        Toast.makeText(
                                requireContext(),
                                "Tạo hồ sơ nhà cung cấp thành công!",
                                Toast.LENGTH_LONG
                        ).show();

                        requireActivity()
                                .getOnBackPressedDispatcher()
                                .onBackPressed();
                    }

                    @Override
                    public void loi(String thongDiep) {
                        if (!isAdded()) return;

                        btnLuuNhaCungCap.setEnabled(true);
                        btnLuuNhaCungCap.setText("Lưu hồ sơ");

                        Toast.makeText(
                                requireContext(),
                                thongDiep,
                                Toast.LENGTH_LONG
                        ).show();
                    }

                    @Override
                    public void hetPhien() {
                        if (!isAdded()) return;

                        btnLuuNhaCungCap.setEnabled(true);
                        btnLuuNhaCungCap.setText("Lưu hồ sơ");

                        Toast.makeText(
                                requireContext(),
                                "Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.",
                                Toast.LENGTH_LONG
                        ).show();
                    }
                }
        );
    }

    @Override
    public void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);
        outState.putString("anhCoSoUrl", anhCoSoUrl);
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        executor.shutdown();
    }
}
