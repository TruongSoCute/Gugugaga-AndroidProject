import '../models/issue_report.dart';
import 'api_client.dart';

/// Phản ánh hàng giả / sai mô tả của khách.
class IssueReportRepository {
  IssueReportRepository(this._api);

  final ApiClient _api;

  /// POST /bao-cao-vi-pham. Có maTruyXuat thì phản ánh gắn đúng lô khách đang cầm.
  Future<void> guiPhanAnh({
    required int sanPhamId,
    required String loai,
    required String noiDung,
    String? maTruyXuat,
    String? anhUrl,
  }) async {
    await _api.post('/bao-cao-vi-pham', body: {
      'sanPhamId': sanPhamId,
      'loai': loai,
      'noiDung': noiDung.trim(),
      if (maTruyXuat != null && maTruyXuat.isNotEmpty) 'maTruyXuat': maTruyXuat,
      if (anhUrl != null && anhUrl.isNotEmpty) 'anhUrl': anhUrl,
    });
  }

  /// GET /bao-cao-vi-pham: phản ánh của chính mình, kèm trạng thái và kết quả xử lý.
  Future<List<IssueReport>> dsCuaToi() async {
    final json = await _api.get('/bao-cao-vi-pham', query: {'kichThuoc': '100'}) as Map<String, dynamic>;
    return (json['duLieu'] as List<dynamic>)
        .map((e) => IssueReport.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
