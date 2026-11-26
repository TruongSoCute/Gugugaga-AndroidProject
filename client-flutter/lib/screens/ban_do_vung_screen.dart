import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/vung.dart';

/// Bản đồ vùng nguyên liệu OCOP sử dụng OpenStreetMap (không cần khóa API).
/// Chọn một điểm trên bản đồ để xem thông tin vùng, hoặc lọc sản phẩm theo vùng đó.
class BanDoVungScreen extends StatefulWidget {
  const BanDoVungScreen({
    super.key,
    required this.dsVung,
    this.vungIdChonSan,
    this.choPhepLoc = false,
  });

  final List<Vung> dsVung;
  final int? vungIdChonSan;
  final bool choPhepLoc;

  @override
  State<BanDoVungScreen> createState() => _BanDoVungScreenState();
}

class _BanDoVungScreenState extends State<BanDoVungScreen> {
  static const _tamMacDinh = LatLng(10.7769, 106.7009); // TP.HCM
  Vung? _vungDangChon;

  List<Vung> get _vungCoToaDo => widget.dsVung.where((v) => v.coToaDo).toList();

  @override
  void initState() {
    super.initState();
    final coToaDo = _vungCoToaDo;
    if (coToaDo.isEmpty) return;
    if (widget.vungIdChonSan != null) {
      for (final v in coToaDo) {
        if (v.id == widget.vungIdChonSan) {
          _vungDangChon = v;
          break;
        }
      }
    }
    _vungDangChon ??= coToaDo.first;
  }

  @override
  Widget build(BuildContext context) {
    final coToaDo = _vungCoToaDo;
    if (coToaDo.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bản đồ vùng nguyên liệu')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Chưa có tọa độ vùng nguyên liệu để hiển thị.', textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final tam = _vungDangChon != null
        ? LatLng(_vungDangChon!.viDo!, _vungDangChon!.kinhDo!)
        : _tamMacDinh;

    return Scaffold(
      appBar: AppBar(title: const Text('Bản đồ vùng nguyên liệu')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: tam,
              initialZoom: widget.vungIdChonSan != null ? 11.5 : 8.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'vn.edu.vhu.ltdd.gugugaga.ocop_client',
              ),
              MarkerLayer(
                markers: [
                  for (final v in coToaDo)
                    Marker(
                      point: LatLng(v.viDo!, v.kinhDo!),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        key: Key('markerVung_${v.id}'),
                        onTap: () => setState(() => _vungDangChon = v),
                        child: Icon(
                          Icons.location_pin,
                          size: _vungDangChon?.id == v.id ? 42 : 34,
                          color: _vungDangChon?.id == v.id
                              ? Theme.of(context).colorScheme.primary
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                ],
              ),
              const SimpleAttributionWidget(
                source: Text('OpenStreetMap contributors'),
              ),
            ],
          ),
          if (_vungDangChon != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: _TheThongTinVung(
                vung: _vungDangChon!,
                choPhepLoc: widget.choPhepLoc,
                onLoc: () => Navigator.pop(context, _vungDangChon!.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _TheThongTinVung extends StatelessWidget {
  const _TheThongTinVung({
    required this.vung,
    required this.choPhepLoc,
    required this.onLoc,
  });

  final Vung vung;
  final bool choPhepLoc;
  final VoidCallback onLoc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vung.ten, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Tọa độ: ${vung.viDo!.toStringAsFixed(4)}, ${vung.kinhDo!.toStringAsFixed(4)}',
              style: theme.textTheme.bodySmall,
            ),
            if (vung.moTa != null && vung.moTa!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(vung.moTa!, style: theme.textTheme.bodyMedium),
            ],
            if (choPhepLoc) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onLoc,
                  icon: const Icon(Icons.filter_alt_outlined),
                  label: const Text('Lọc sản phẩm vùng này'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
