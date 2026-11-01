package vn.edu.vhu.ltdd.gugugaga.admin.ui.lo;

import android.graphics.Bitmap;
import android.graphics.Color;
import android.util.Log;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.EncodeHintType;
import com.google.zxing.WriterException;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel;

import java.util.EnumMap;
import java.util.Map;

import vn.edu.vhu.ltdd.gugugaga.admin.AppConfig;

/**
 * Vẽ ảnh QR từ đường dẫn truy xuất của lô. Thư viện zxing core tính ma trận đen/trắng (Java thuần),
 * lớp này đổi ma trận thành Bitmap của Android. Đặt ở tầng ui vì Bitmap là lớp giao diện Android
 * (util chỉ được dùng Java thuần — quy tắc UTIL_THUAN).
 */
final class MaQr {
    private MaQr() { }

    /** @return Bitmap vuông cạnh `canh` px, hoặc null nếu nội dung không mã hóa được. */
    static Bitmap tao(String noiDung, int canh) {
        if (noiDung == null || noiDung.isEmpty()) return null;
        Map<EncodeHintType, Object> goiY = new EnumMap<>(EncodeHintType.class);
        goiY.put(EncodeHintType.CHARACTER_SET, "UTF-8");
        // Mức sửa lỗi M: tem dán bị trầy một phần vẫn quét được.
        goiY.put(EncodeHintType.ERROR_CORRECTION, ErrorCorrectionLevel.M);
        goiY.put(EncodeHintType.MARGIN, 2);
        try {
            BitMatrix m = new QRCodeWriter().encode(noiDung, BarcodeFormat.QR_CODE, canh, canh, goiY);
            int w = m.getWidth();
            int h = m.getHeight();
            int[] diem = new int[w * h];
            for (int y = 0; y < h; y++) {
                int dong = y * w;
                for (int x = 0; x < w; x++) diem[dong + x] = m.get(x, y) ? Color.BLACK : Color.WHITE;
            }
            return Bitmap.createBitmap(diem, w, h, Bitmap.Config.ARGB_8888);
        } catch (WriterException | IllegalArgumentException e) {
            Log.w(AppConfig.TAG, "Không tạo được mã QR", e);
            return null;
        }
    }
}
