import 'dart:ffi';

import 'package:flutter_platform_utils/flutter_platform_utils.dart';
import 'package:sqlite3_ohos_bridge/src/load_library.dart';

/// 基于 [`sqlite3`](https://github.com/simolus3/sqlite3.dart/tree/sqlite3-2.9.4/sqlite3) 的桥接实现，用于扩展 `sqlite3` 对鸿蒙平台的支持。
///
///
class Sqlite3OhosBridge {
  Sqlite3OhosBridge._();

  /// 用于在鸿蒙平台加载 SQLite 原生库。
  ///
  /// 在打开数据库前添加如下代码，即可在 [`sqlite3`](https://github.com/simolus3/sqlite3.dart/tree/sqlite3-2.9.4/sqlite3) 既有平台支持的基础上，将 Flutter 访问 SQLite 的能力扩展到鸿蒙平台：
  /// ```dart
  /// import 'package:sqlite3/open.dart';
  ///
  /// open.overrideForAll(Sqlite3OhosBridge.openLibrary);
  /// ```
  ///
  /// 若已有针对原生平台的 [open.overrideFor]，也需要修改为 [open.overrideForAll] 的形式，例如：
  /// ```dart
  /// // 原有代码
  /// // open.overrideFor(OperatingSystem.android, () => DynamicLibrary.open("libsqlite3x.so"));
  ///
  /// // 改造后代码
  /// open.overrideForAll(() {
  ///   if (Platform.isAndroid) {
  ///     return DynamicLibrary.open('libsqlite3x.so');
  ///   }
  ///   return Sqlite3OhosBridge.openLibrary();
  /// });
  /// ```
  ///
  /// 鸿蒙平台的 SQLite 原生库由 [`sqlite-native-library`](https://github.com/SageMik/sqlite-native-libraries) 提供。
  static DynamicLibrary openLibrary() {
    if (PlatformUtils.isOhos) {
      return DynamicLibrary.open('libsqlite3.so');
    }
    return defaultOpen();
  }
}
