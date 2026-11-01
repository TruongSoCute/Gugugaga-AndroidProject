// Kiểm tra kiến trúc app Client bằng máy (docs/development/Architecture.md, mục Hai app).
// Dart không có ArchUnit, nên test này đọc các dòng `import` trong lib/ và đối chiếu quy tắc.
// Khi bị đỏ: sửa code cho đúng tầng, không nới quy tắc khi nhóm chưa thống nhất.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Tầng của một file theo thư mục con trong lib/.
String? tangCua(String duongDan) {
  final p = duongDan.replaceAll('\\', '/');
  const tang = ['data', 'models', 'screens', 'widgets', 'utils'];
  for (final t in tang) {
    if (p.startsWith('lib/$t/')) return t;
  }
  if (p == 'lib/main.dart' || p == 'lib/config.dart') return 'goc';
  return null;
}

/// Các tầng nội bộ mà mỗi tầng được import (ngoài chính nó).
const _duocImport = <String, Set<String>>{
  'goc': {'screens', 'goc'},
  'screens': {'screens', 'widgets', 'data', 'models', 'utils', 'goc'},
  'widgets': {'widgets', 'models', 'utils'},
  'data': {'data', 'models', 'goc'},
  'models': {'models'},
  'utils': {'utils'},
};

/// Gói ngoài chỉ được dùng ở đúng file (một chỗ quản lý gọi mạng và token).
const _chuGoi = <String, String>{
  'package:http/': 'lib/data/api_client.dart',
  'package:shared_preferences/': 'lib/data/token_store.dart',
  'package:dio/': 'lib/data/api_client.dart',
};

final _import = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''', multiLine: true);

/// Trả danh sách vi phạm cho tập file {đường dẫn tương đối: nội dung}.
List<String> kiemTra(Map<String, String> files) {
  final loi = <String>[];
  for (final e in files.entries) {
    final nguon = e.key;
    final tangNguon = tangCua(nguon);
    if (tangNguon == null) {
      loi.add('$nguon: file nằm ngoài các thư mục data/models/screens/widgets/utils');
      continue;
    }
    for (final m in _import.allMatches(e.value)) {
      final dich = m.group(1)!;
      // Gói ngoài bị giới hạn chỗ dùng.
      for (final g in _chuGoi.entries) {
        if (dich.startsWith(g.key) && nguon != g.value) {
          loi.add('$nguon: "$dich" chỉ được dùng trong ${g.value}');
        }
      }
      if (dich == 'dart:io' && nguon != 'lib/data/api_client.dart') {
        loi.add('$nguon: dart:io (mạng/tệp) chỉ dùng trong lib/data/api_client.dart');
      }
      // models và utils là Dart thuần, không dùng Flutter.
      if ((tangNguon == 'models' || tangNguon == 'utils') && dich.startsWith('package:flutter/')) {
        loi.add('$nguon: $tangNguon không được dùng Flutter ($dich)');
      }
      // data không biết giao diện.
      if (tangNguon == 'data' && dich.startsWith('package:flutter/')) {
        loi.add('$nguon: data không được dùng Flutter UI ($dich)');
      }
      // Import nội bộ (tương đối hoặc package:ocop_client/).
      String? dichNoiBo;
      if (dich.startsWith('package:ocop_client/')) {
        dichNoiBo = 'lib/${dich.substring('package:ocop_client/'.length)}';
      } else if (!dich.contains(':')) {
        dichNoiBo = Uri.parse(nguon).resolve(dich).path;
      }
      if (dichNoiBo != null) {
        final tangDich = tangCua(dichNoiBo);
        if (tangDich != null && !_duocImport[tangNguon]!.contains(tangDich)) {
          loi.add('$nguon: tầng $tangNguon không được import tầng $tangDich ($dich)');
        }
      }
    }
  }
  return loi;
}

void main() {
  test('lib/ tuân thủ kiến trúc', () {
    final files = <String, String>{
      for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')))
        f.path.replaceAll('\\', '/'): f.readAsStringSync(),
    };
    expect(files, isNotEmpty);
    expect(kiemTra(files), isEmpty);
  });

  test('bắt được vi phạm trên ví dụ sai', () {
    final loi = kiemTra({
      'lib/screens/sai.dart': "import 'package:http/http.dart' as http;\nimport 'package:shared_preferences/shared_preferences.dart';",
      'lib/models/sai.dart': "import 'package:flutter/material.dart';\nimport '../data/api_client.dart';",
      'lib/data/sai.dart': "import '../screens/khung_chinh.dart';",
      'lib/widgets/sai.dart': "import 'package:ocop_client/data/api_client.dart';",
      'lib/la.dart': '',
    });
    expect(loi.where((l) => l.startsWith('lib/screens/sai.dart')).length, 2);
    expect(loi.where((l) => l.startsWith('lib/models/sai.dart')).length, 2);
    expect(loi.any((l) => l.startsWith('lib/data/sai.dart') && l.contains('tầng screens')), isTrue);
    expect(loi.any((l) => l.startsWith('lib/widgets/sai.dart') && l.contains('tầng data')), isTrue);
    expect(loi.any((l) => l.startsWith('lib/la.dart')), isTrue);
  });
}
