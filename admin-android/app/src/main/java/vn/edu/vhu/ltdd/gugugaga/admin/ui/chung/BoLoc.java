package vn.edu.vhu.ltdd.gugugaga.admin.ui.chung;

import android.view.View;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Spinner;

import androidx.annotation.ArrayRes;

/** Spinner lọc trạng thái: nhãn và giá trị gửi API lấy từ arrays.xml (Lab A6). */
public final class BoLoc {
    public interface KhiChon {
        /** @param giaTri mã gửi lên API, hoặc null khi chọn "Tất cả". */
        void chon(String giaTri);
    }

    private BoLoc() { }

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
