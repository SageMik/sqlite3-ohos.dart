import 'dart:math';
import 'dart:ffi';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:device_info_plus_ohos/device_info_plus_ohos.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_platform_utils/flutter_platform_utils.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_ohos_bridge/sqlite3_ohos_bridge.dart';

class MainViewModel extends ChangeNotifier {
  late final String sqliteVersion;
  String osVersionLabel = "Loading...";

  MainViewModel()
      : _db = (() {
          open.overrideFor(OperatingSystem.android, () => DynamicLibrary.open("libsqlite3x.so"));
          open.overrideForAll(() {
            if (Platform.isAndroid) { // [Android SQLite 覆盖]
              return DynamicLibrary.open('libsqlite3x.so');
            }
            return Sqlite3OhosBridge.openLibrary();
          });
          return sqlite3.openInMemory();
        })() {
    _db.execute(
      'CREATE TABLE IF NOT EXISTS items(id INTEGER PRIMARY KEY, name TEXT NOT NULL)',
    );
    sqliteVersion =
        (_db.select('SELECT sqlite_version() AS v').first['v'] as String?) ??
            '';
    _loadOsVersion().then((it) {
      osVersionLabel = it;
      notifyListeners();
    });
    _refresh();
  }

  final Database _db;
  final Random _rng = Random();

  int? selectedId;
  List<Map<String, Object?>> rows = const [];

  @override
  void dispose() {
    _db.dispose();
    super.dispose();
  }

  void add() {
    _db.execute('INSERT INTO items(name) VALUES(?)', [_randZh()]);
    _refresh();
    notifyListeners();
  }

  void updateOne() {
    final id = selectedId;
    if (id == null) return;
    _db.execute('UPDATE items SET name = ? WHERE id = ?', [_randZh(), id]);
    _refresh();
    notifyListeners();
  }

  void deleteOne() {
    final id = selectedId ?? (rows.isEmpty ? null : rows.last['id'] as int);
    if (id == null) return;
    _db.execute('DELETE FROM items WHERE id = ?', [id]);
    _refresh();
    notifyListeners();
  }

  void select(int id) {
    selectedId = id;
    notifyListeners();
  }

  void _refresh() {
    final r = _db.select('SELECT id, name FROM items ORDER BY id');
    rows = r
        .map((x) => {'id': x['id'], 'name': x['name']})
        .toList(growable: false);
    if (selectedId != null && !rows.any((x) => x['id'] == selectedId)) {
      selectedId = null;
    }
  }

  static const _w = [
    '事情',
    '工作',
    '学习',
    '生活',
    '手机',
    '电脑',
    '网络',
    '系统',
    '功能',
    '页面',
    '按钮',
    '数据',
    '表格',
    '列表',
  ];

  String _randZh() => _w[_rng.nextInt(_w.length)] + _w[_rng.nextInt(_w.length)];

  static Future<String> _loadOsVersion() async {
    try {
      if (PlatformUtils.isOhos) {
        final ohosInfo = await DeviceInfoOhosPlugin().ohosDeviceInfo;
        final incrementalVersion = ohosInfo.incrementalVersion;
        final apiVersion = ohosInfo.sdkApiVersion;
        final abi = ohosInfo.abiList;
        return 'HarmonyOS NEXT $incrementalVersion (API $apiVersion) · $abi';
      } else if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final release = androidInfo.version.release;
        final sdkInt = androidInfo.version.sdkInt;
        final abi = androidInfo.supportedAbis.first;
        return 'Android $release (SDK $sdkInt) · $abi';
      }
    } catch (_) {}
    return 'Unknown';
  }
}
