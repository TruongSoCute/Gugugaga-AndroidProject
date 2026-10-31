import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/truy_xuat_repository.dart';
import '../models/hanh_trinh_lo.dart';
import '../utils/dinh_dang.dart';
import '../widgets/anh_mang.dart';
import '../widgets/trang_thai_loi.dart';

/// Hành trình của ĐÚNG lô có mã này (điểm nhấn kỹ thuật của đề 5): thông tin lô, sản phẩm,
/// nhà cung cấp + chứng nhận, và các bước truy xuất theo thứ tự (ListView.builder).
class HanhTrinhScreen extends StatefulWidget {
  const HanhTrinhScreen({super.key, required this.maTruyXuat, this.repository});

  final String maTruyXuat;
  final TruyXuatRepository? repository;

  @override
  State<HanhTrinhScreen> createState() => _HanhTrinhScreenState();
}

class _HanhTrinhScreenState extends State<HanhTrinhScreen> {
  late final TruyXuatRepository _repo = widget.repository ?? TruyXuatRepository(ApiClient());

  bool _dangTai = true;
  ApiException? _loi;
  HanhTrinhLo? _lo;

  @override
  void initState() {
    super.initState();
    _tai();
  }

  Future<void> _tai() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    try {
      final lo = await _repo.layHanhTrinh(widget.maTruyXuat);
      if (!mounted) return;
      setState(() {
        _lo = lo;
        _dangTai = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loi = e;
        _dangTai = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hành trình lô hàng')),
      body: _noiDung(),
    );
  }

  Widget _noiDung() {
    if (_dangTai) return const Center(child: CircularProgressIndicator());
    final loi = _loi;
    if (loi != null) {
      if (loi.maHttp == 404) {
        // Mã không tồn tại hoặc lô chưa/không còn được công bố: cảnh báo người mua.
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.gpp_maybe_outlined, size: 56, color: Colors.orange),
                SizedBox(height: 12),
                Text(
                  'Không xác minh được nguồn gốc của mã này.\n'
                  'Hãy kiểm tra lại mã trên bao bì; nếu mã vẫn không đúng, sản phẩm có thể không chính hãng.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }
      return TrangThaiLoi(thongDiep: loi.thongDiep, onThuLai: _tai);
    }
    final lo = _lo!;
    // Phần đầu (thông tin lô) + từng bước: dùng ListView.builder với phần tử 0 là phần đầu.
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: lo.cacBuoc.length + 1,
      itemBuilder: (context, i) => i == 0
          ? _ThongTinLo(lo: lo)
          : _DongBuoc(buoc: lo.cacBuoc[i - 1], cuoi: i == lo.cacBuoc.length),
    );
  }
}

class _ThongTinLo extends StatelessWidget {
  const _ThongTinLo({required this.lo});

  final HanhTrinhLo lo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnhMang(url: lo.anhHienTruongUrl ?? lo.anhSanPhamUrl, height: 180, width: double.infinity),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lo.tenSanPham, style: theme.textTheme.titleLarge),
              if (lo.hangSao != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${'★' * lo.hangSao!} OCOP ${lo.hangSao} sao',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.amber.shade800)),
                ),
              const SizedBox(height: 12),
              _Dong(nhan: 'Mã lô', giaTri: lo.maTruyXuat),
              _Dong(nhan: 'Ngày sản xuất', giaTri: DinhDang.ngay(lo.ngaySanXuat)),
              _Dong(nhan: 'Hạn sử dụng', giaTri: DinhDang.ngay(lo.hanSuDung)),
              _Dong(nhan: 'Vùng nguyên liệu', giaTri: lo.vungNguyenLieu),
              _Dong(nhan: 'Người sản xuất', giaTri: lo.nguoiSanXuat),
              _Dong(nhan: 'Nhà cung cấp', giaTri: lo.tenNhaCungCap),
              _Dong(nhan: 'Địa chỉ', giaTri: lo.diaChiNhaCungCap),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final cn in lo.chungNhan)
                    Chip(
                      avatar: Icon(cn.conHieuLuc ? Icons.verified : Icons.error_outline,
                          size: 18, color: cn.conHieuLuc ? Colors.green : Colors.red),
                      label: Text('${cn.loai} ${cn.soHieu}${cn.conHieuLuc ? '' : ' (hết hạn)'}'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Hành trình (${lo.cacBuoc.length} bước)', style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _Dong extends StatelessWidget {
  const _Dong({required this.nhan, required this.giaTri});

  final String nhan;
  final String giaTri;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(nhan, style: Theme.of(context).textTheme.bodySmall)),
          Expanded(child: Text(giaTri)),
        ],
      ),
    );
  }
}

class _DongBuoc extends StatelessWidget {
  const _DongBuoc({required this.buoc, required this.cuoi});

  final BuocTruyXuat buoc;
  final bool cuoi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 56,
            child: Column(
              children: [
                CircleAvatar(radius: 14, child: Text('${buoc.thuTu}')),
                if (!cuoi) Expanded(child: VerticalDivider(color: theme.colorScheme.outline, thickness: 2)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(buoc.tenBuoc, style: theme.textTheme.titleSmall),
                  Text(DinhDang.thoiDiem(buoc.thoiDiem), style: theme.textTheme.bodySmall),
                  if (buoc.moTa != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(buoc.moTa!)),
                  if (buoc.anhUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AnhMang(url: buoc.anhUrl, height: 140, width: double.infinity),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
