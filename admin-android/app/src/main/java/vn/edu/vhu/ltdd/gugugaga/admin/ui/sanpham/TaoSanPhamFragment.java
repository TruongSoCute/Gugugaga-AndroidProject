
package vn.edu.vhu.ltdd.gugugaga.admin.ui.sanpham;

import android.net.Uri;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.Spinner;
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.data.AnhRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.data.KetQuaApi;
import vn.edu.vhu.ltdd.gugugaga.admin.data.NhaCungCapRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.data.SanPhamRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.model.KetQuaTaiAnh;
import vn.edu.vhu.ltdd.gugugaga.admin.model.NhaCungCap;
import vn.edu.vhu.ltdd.gugugaga.admin.model.SanPham;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauTaoSanPham;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.MainActivity;

public class TaoSanPhamFragment extends Fragment {

    private Spinner spNhaCungCap;

    private EditText edtTenSanPham;
    private EditText edtMoTa;
    private EditText edtDonViTinh;
    private EditText edtGia;

    private ImageView imgAnhSanPham;

    private Button btnChonAnhSanPham;
    private Button btnLuuSanPham;

    private NhaCungCapRepository nhaCungCapRepository;
    private SanPhamRepository sanPhamRepository;
    private AnhRepository anhRepository;

    private final List<NhaCungCap> danhSachNhaCungCap =
            new ArrayList<>();

    private String anhSanPhamUrl;

    private boolean dangTaiAnh = false;
    private boolean daTaiDanhSachNhaCungCap = false;

    private final ExecutorService executor =
            Executors.newSingleThreadExecutor();

    private ActivityResultLauncher<String> chonAnhLauncher;

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        chonAnhLauncher = registerForActivityResult(
                new ActivityResultContracts.GetContent(),
                uri -> {
                    if (uri != null) {
                        xuLyAnh(uri);
                    }
                }
        );

        if (savedInstanceState != null) {
            anhSanPhamUrl = savedInstanceState.getString("anhSanPhamUrl");
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
                R.layout.fragment_tao_san_pham,
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

        ((MainActivity) requireActivity())
                .datTieuDe(R.string.tieu_de_san_pham);

        nhaCungCapRepository =
                new NhaCungCapRepository(requireContext());

        sanPhamRepository =
                new SanPhamRepository(requireContext());

        anhRepository =
                new AnhRepository(requireContext());

        spNhaCungCap =
                view.findViewById(R.id.spNhaCungCap);

        edtTenSanPham =
                view.findViewById(R.id.edtTenSanPham);

        edtMoTa =
                view.findViewById(R.id.edtMoTa);

        edtDonViTinh =
                view.findViewById(R.id.edtDonViTinh);

        edtGia =
                view.findViewById(R.id.edtGia);

        imgAnhSanPham =
                view.findViewById(R.id.imgAnhSanPham);

        btnChonAnhSanPham =
                view.findViewById(R.id.btnChonAnhSanPham);

        btnLuuSanPham =
                view.findViewById(R.id.btnLuuSanPham);

        btnChonAnhSanPham.setOnClickListener(v ->
                chonAnhLauncher.launch("image/*")
        );

        btnLuuSanPham.setOnClickListener(v ->
                taoSanPham()
        );

        taiDanhSachNhaCungCap();
    }

    // =====================================
    // TẢI DANH SÁCH NHÀ CUNG CẤP
    // =====================================

    private void taiDanhSachNhaCungCap() {

        nhaCungCapRepository.danhSach(
                null,
                new KetQuaApi<List<NhaCungCap>>() {

                    @Override
                    public void thanhCong(List<NhaCungCap> duLieu) {

                        if (!isAdded()) return;

                        danhSachNhaCungCap.clear();

                        if (duLieu != null) {
                            for (NhaCungCap ncc : duLieu) {

                                if (ncc != null
                                        && "DA_DUYET".equalsIgnoreCase(
                                        ncc.trangThaiDuyet
                                )) {
                                    danhSachNhaCungCap.add(ncc);
                                }
                            }
                        }

                        hienThiDanhSachNhaCungCap();
                    }

                    @Override
                    public void loi(String thongDiep) {

                        if (!isAdded()) return;

                        Toast.makeText(
                                requireContext(),
                                thongDiep,
                                Toast.LENGTH_LONG
                        ).show();
                    }

                    @Override
                    public void hetPhien() {

                        if (!isAdded()) return;

                        Toast.makeText(
                                requireContext(),
                                "Phiên đăng nhập đã hết hạn.",
                                Toast.LENGTH_LONG
                        ).show();
                    }
                }
        );
    }

    private void hienThiDanhSachNhaCungCap() {

        List<String> tenNhaCungCap = new ArrayList<>();

        for (NhaCungCap ncc : danhSachNhaCungCap) {
            tenNhaCungCap.add(ncc.ten);
        }

        if (tenNhaCungCap.isEmpty()) {
            tenNhaCungCap.add("Chưa có nhà cung cấp được duyệt");
        }

        ArrayAdapter<String> adapter =
                new ArrayAdapter<>(
                        requireContext(),
                        android.R.layout.simple_spinner_item,
                        tenNhaCungCap
                );

        adapter.setDropDownViewResource(
                android.R.layout.simple_spinner_dropdown_item
        );

        spNhaCungCap.setAdapter(adapter);

        daTaiDanhSachNhaCungCap = true;

        if (danhSachNhaCungCap.isEmpty()) {
            spNhaCungCap.setEnabled(false);
            btnLuuSanPham.setEnabled(false);

            Toast.makeText(
                    requireContext(),
                    "Cần có nhà cung cấp đã được duyệt trước khi tạo sản phẩm.",
                    Toast.LENGTH_LONG
            ).show();
        }
    }

    // =====================================
    // CHỌN VÀ UPLOAD ẢNH
    // =====================================

    private void xuLyAnh(Uri uri) {

        String mimeType = requireContext()
                .getContentResolver()
                .getType(uri);

        if (mimeType == null
                || !(mimeType.equals("image/jpeg")
                || mimeType.equals("image/png")
                || mimeType.equals("image/webp"))) {

            Toast.makeText(
                    requireContext(),
                    "Chỉ hỗ trợ ảnh JPG, PNG hoặc WEBP.",
                    Toast.LENGTH_SHORT
            ).show();

            return;
        }

        try {
            imgAnhSanPham.setImageURI(uri);
        } catch (Exception e) {
            Toast.makeText(
                    requireContext(),
                    "Không thể hiển thị ảnh.",
                    Toast.LENGTH_SHORT
            ).show();
            return;
        }

        btnChonAnhSanPham.setEnabled(false);
        btnChonAnhSanPham.setText("Đang tải ảnh lên...");

        dangTaiAnh = true;

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

                byte[] duLieuAnh = output.toByteArray();

                if (!isAdded()) return;

                requireActivity().runOnUiThread(() -> {

                    anhRepository.taiLen(
                            duLieuAnh,
                            mimeType,
                            "san-pham",
                            new KetQuaApi<KetQuaTaiAnh>() {

                                @Override
                                public void thanhCong(KetQuaTaiAnh ketQua) {

                                    if (!isAdded()) return;

                                    anhSanPhamUrl = ketQua.url;
                                    ketThucUploadAnh();

                                    Toast.makeText(
                                            requireContext(),
                                            "Tải ảnh thành công!",
                                            Toast.LENGTH_SHORT
                                    ).show();
                                }

                                @Override
                                public void loi(String thongDiep) {

                                    if (!isAdded()) return;

                                    ketThucUploadAnh();

                                    Toast.makeText(
                                            requireContext(),
                                            thongDiep,
                                            Toast.LENGTH_LONG
                                    ).show();
                                }

                                @Override
                                public void hetPhien() {

                                    if (!isAdded()) return;

                                    ketThucUploadAnh();

                                    Toast.makeText(
                                            requireContext(),
                                            "Phiên đăng nhập đã hết hạn.",
                                            Toast.LENGTH_LONG
                                    ).show();
                                }
                            }
                    );
                });

            } catch (Exception e) {

                if (!isAdded()) return;

                requireActivity().runOnUiThread(() -> {

                    ketThucUploadAnh();

                    Toast.makeText(
                            requireContext(),
                            e.getMessage(),
                            Toast.LENGTH_LONG
                    ).show();
                });
            }
        });
    }

    private void ketThucUploadAnh() {

        dangTaiAnh = false;

        btnChonAnhSanPham.setEnabled(true);
        btnChonAnhSanPham.setText("Chọn ảnh sản phẩm");
    }

    // =====================================
    // TẠO SẢN PHẨM
    // =====================================

    private void taoSanPham() {

        if (dangTaiAnh) {
            Toast.makeText(
                    requireContext(),
                    "Vui lòng chờ tải ảnh hoàn tất.",
                    Toast.LENGTH_SHORT
            ).show();
            return;
        }

        if (danhSachNhaCungCap.isEmpty()) {
            Toast.makeText(
                    requireContext(),
                    "Chưa có nhà cung cấp được duyệt.",
                    Toast.LENGTH_SHORT
            ).show();
            return;
        }

        String ten = edtTenSanPham.getText()
                .toString().trim();

        String moTa = edtMoTa.getText()
                .toString().trim();

        String donViTinh = edtDonViTinh.getText()
                .toString().trim();

        String giaText = edtGia.getText()
                .toString().trim();

        if (ten.isEmpty()) {
            edtTenSanPham.setError(
                    "Vui lòng nhập tên sản phẩm."
            );
            edtTenSanPham.requestFocus();
            return;
        }

        if (giaText.isEmpty()) {
            edtGia.setError(
                    "Vui lòng nhập giá sản phẩm."
            );
            edtGia.requestFocus();
            return;
        }

        int gia;

        try {
            gia = Integer.parseInt(giaText);

            if (gia < 1 || gia > 1000000000) {
                throw new NumberFormatException();
            }

        } catch (NumberFormatException e) {

            edtGia.setError(
                    "Giá phải từ 1 đến 1.000.000.000 VNĐ."
            );
            edtGia.requestFocus();
            return;
        }

        int viTri = spNhaCungCap.getSelectedItemPosition();

        if (viTri < 0 || viTri >= danhSachNhaCungCap.size()) {
            Toast.makeText(
                    requireContext(),
                    "Vui lòng chọn nhà cung cấp.",
                    Toast.LENGTH_SHORT
            ).show();
            return;
        }

        NhaCungCap nhaCungCap =
                danhSachNhaCungCap.get(viTri);

        YeuCauTaoSanPham yeuCau =
                new YeuCauTaoSanPham();

        yeuCau.nhaCungCapId = nhaCungCap.id;
        yeuCau.ten = ten;
        yeuCau.moTa = moTa.isEmpty() ? null : moTa;
        yeuCau.donViTinh =
                donViTinh.isEmpty() ? null : donViTinh;
        yeuCau.gia = gia;
        yeuCau.anhUrl = anhSanPhamUrl;

        btnLuuSanPham.setEnabled(false);
        btnLuuSanPham.setText("Đang tạo sản phẩm...");

        sanPhamRepository.tao(
                yeuCau,
                new KetQuaApi<SanPham>() {

                    @Override
                    public void thanhCong(SanPham ketQua) {

                        if (!isAdded()) return;

                        btnLuuSanPham.setEnabled(true);
                        btnLuuSanPham.setText("Tạo sản phẩm");

                        Toast.makeText(
                                requireContext(),
                                "Tạo sản phẩm thành công! Sản phẩm đang chờ duyệt.",
                                Toast.LENGTH_LONG
                        ).show();

                        requireActivity()
                                .getOnBackPressedDispatcher()
                                .onBackPressed();
                    }

                    @Override
                    public void loi(String thongDiep) {

                        if (!isAdded()) return;

                        btnLuuSanPham.setEnabled(true);
                        btnLuuSanPham.setText("Tạo sản phẩm");

                        Toast.makeText(
                                requireContext(),
                                thongDiep,
                                Toast.LENGTH_LONG
                        ).show();
                    }

                    @Override
                    public void hetPhien() {

                        if (!isAdded()) return;

                        btnLuuSanPham.setEnabled(true);
                        btnLuuSanPham.setText("Tạo sản phẩm");

                        Toast.makeText(
                                requireContext(),
                                "Phiên đăng nhập đã hết hạn.",
                                Toast.LENGTH_LONG
                        ).show();
                    }
                }
        );
    }

    @Override
    public void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);
        outState.putString("anhSanPhamUrl", anhSanPhamUrl);
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        executor.shutdown();
    }
}
