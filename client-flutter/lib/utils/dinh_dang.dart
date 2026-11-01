/// Định dạng hiển thị. Tiền lưu bằng số nguyên (đồng), chỉ định dạng khi hiện ra.
class DinhDang {
  DinhDang._();

  /// 320000 -> "320.000 đ"
  static String tien(int dong) {
    final chuoi = dong.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < chuoi.length; i++) {
      if (i > 0 && (chuoi.length - i) % 3 == 0) buf.write('.');
      buf.write(chuoi[i]);
    }
    return '${dong < 0 ? '-' : ''}$buf đ';
  }

  /// "2026-03-02" -> "02/03/2026"
  static String ngay(String yyyyMmDd) {
    final p = yyyyMmDd.split('-');
    if (p.length != 3) return yyyyMmDd;
    return '${p[2]}/${p[1]}/${p[0]}';
  }

  /// Thời điểm ISO (UTC từ backend) -> giờ trên máy: "27/02/2026 07:00"
  static String thoiDiem(String iso) {
    final t = DateTime.tryParse(iso)?.toLocal();
    if (t == null) return iso;
    String hai(int n) => n.toString().padLeft(2, '0');
    return '${hai(t.day)}/${hai(t.month)}/${t.year} ${hai(t.hour)}:${hai(t.minute)}';
  }
}
