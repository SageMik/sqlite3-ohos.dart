import 'dart:ffi';

import 'package:flutter_platform_utils/flutter_platform_utils.dart';
import 'package:sqlite3_ohos_bridge/src/load_library.dart';

class Sqlite3OhosBridge {
  Sqlite3OhosBridge._();

  static DynamicLibrary openLibrary() {
    if (PlatformUtils.isOhos) {
      return DynamicLibrary.open('libsqlite3.so');
    }
    return defaultOpen();
  }
}
