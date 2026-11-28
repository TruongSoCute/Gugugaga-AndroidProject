package vn.edu.vhu.ltdd.gugugaga.admin.ui.common;

import android.content.Context;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Spinner;

import androidx.annotation.ArrayRes;

import com.google.android.material.chip.Chip;
import com.google.android.material.chip.ChipGroup;

import vn.edu.vhu.ltdd.gugugaga.admin.R;

/** Bộ lọc trạng thái cho danh sách: hỗ trợ ChipGroup hiện đại (Material 3) và Spinner (Lab A6). */
public final class FilterBar {
    public interface KhiChon {
        /** @param giaTri mã gửi lên API, hoặc null khi chọn "Tất cả". */
        void chon(String giaTri);
    }

    private FilterBar() { }

    /** Tạo các Chip lọc cuộn ngang từ arrays.xml; chọn sẵn mục đầu tiên ("Tất cả"). */
    public static void caiDatChip(ChipGroup group, @ArrayRes int nhanRes, @ArrayRes int giaTriRes, KhiChon khiChon) {
        Context ctx = group.getContext();
        String[] nhan = ctx.getResources().getStringArray(nhanRes);
        String[] ma = ctx.getResources().getStringArray(giaTriRes);
        group.removeAllViews();
        group.setSingleSelection(true);
        group.setSelectionRequired(true);

        int n = Math.min(nhan.length, ma.length);
        int idDau = View.NO_ID;
        for (int i = 0; i < n; i++) {
            Chip chip = new Chip(ctx, null, com.google.android.material.R.attr.chipStyle);
            int viewId = View.generateViewId();
            chip.setId(viewId);
            chip.setText(nhan[i]);
            chip.setCheckable(true);
            chip.setTag(ma[i]);
            group.addView(chip);
            if (i == 0) idDau = viewId;
        }

        final boolean[] daKhoiTao = {false};
        group.setOnCheckedStateChangeListener((g, checkedIds) -> {
            if (checkedIds.isEmpty()) return;
            View v = g.findViewById(checkedIds.get(0));
            if (daKhoiTao[0]) Animations.nhayNhe(v);
            String chon = v != null && v.getTag() instanceof String ? (String) v.getTag() : "";
            khiChon.chon(chon.isEmpty() ? null : chon);
        });

        if (idDau != View.NO_ID) {
            group.check(idDau);
        }
        daKhoiTao[0] = true;
    }

    public static void caiDat(Spinner sp, @ArrayRes int nhan, @ArrayRes int giaTri, KhiChon khiChon) {
        ArrayAdapter<CharSequence> a = ArrayAdapter.createFromResource(sp.getContext(), nhan,
                android.R.layout.simple_spinner_item);
        a.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        sp.setAdapter(a);
        String[] ma = sp.getResources().getStringArray(giaTri);
        // OnItemSelectedListener có 2 phương thức nên không viết bằng lambda được (Lab A6).
        // onItemSelected chạy ngay khi setAdapter: ViewModel tự bỏ qua nếu bộ lọc không đổi.
        sp.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                String chon = ma[position];
                khiChon.chon(chon.isEmpty() ? null : chon);
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) { }
        });
    }
}
