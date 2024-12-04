# sqlite3

**中文** | [English](README_EN.md)

通过 `dart:ffi` 提供 [SQLite](https://www.sqlite.org/index.html) 的 Dart 绑定。

本库是 [sqlite.dart](https://github.com/simolus3/sqlite3.dart) 的分支版本之一，在原版支持 Android, iOS, Windows, MacOS, Linux, Web 的基础上，**新增了 HarmonyOS 适配**。

HarmonyOS 适配基于 **[鸿蒙先锋队/flutter](https://gitee.com/harmonycommando_flutter/flutter)（Flutter 版本：3.22）**，已成功在 Mac Arm 鸿蒙模拟器 上运行。

## 目录

- [快速开始](#快速开始)
    - [导入 `sqlite3`](#导入-sqlite3)
        - [另一种 Harmony 适配方案](#另一种-HarmonyOS-适配方案)
    - [导入 `sqlite3_flutter_libs` (可选)](#导入-sqlite3_flutter_libs-可选)
      - [支持平台](#支持平台)
    - [通过 `sqlite3` 操作数据库](#通过-sqlite3-操作数据库)
- [自行提供 SQLite 原生库](#自行提供-SQLite-原生库)
  - [获取](#获取)
  - [覆盖](#覆盖)

## 快速开始

### 导入 `sqlite3`

在 `pubspec.yaml` 中引入本分支版本：

```yaml
dependencies:
  sqlite3:
    git:
      url: "https://github.com/SageMik/sqlite3-ohos.dart"
      path: "sqlite3"
      ref: b8e37186ebdae03367ba132fb9c5c37b3b5f8d4f
```

#### 另一种 HarmonyOS 适配方案

如果您希望支持 HarmonyOS 平台，除了引入本分支版本外，也可以通过简单的代码判断实现。如此可以保留对原版 `sqlite3` 的依赖引用，但可能会比引入本分支版本更繁琐。

具体而言，新建内容如下的文件，并将项目中**所有使用到 `package:sqlite3/sqlite3.dart` 的 `sqlite3` 的地方，替换为该文件的 `sqlite3` 变量**，即可支持 HarmonyOS 平台。从原理上讲，这段代码基本概括了本分支版本的主要工作。

```dart
import 'dart:ffi';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart' as s3;
import 'package:sqlite3/sqlite3.dart' hide sqlite3;
import 'package:sqlite3/src/ffi/implementation.dart';

Sqlite3? _sqlite3;

Sqlite3 get sqlite3 {
 return _sqlite3 ??= Platform.operatingSystem == 'ohos'
     ? FfiSqlite3(DynamicLibrary.open("libsqlite3.so"))
     : s3.sqlite3;
}
```

### 导入 `sqlite3_flutter_libs` (可选)

### 支持平台

为了支持 `sqlite3` 操作数据库，您需要确保您的环境中存在可访问的 SQLite3 原生库。

例如，对于 Android 和 HarmonyOS 平台，需要根据实际情况提供 `arm64-v8a`, `x86_64` 等架构的 `libsqlite3.so` ；对于 Windows 平台，则需要提供 `x64` 架构的 `sqlite3.dll` 。

这也意味着，您能够在任何可以通过 `DynamicLibrary` 加载原生库获取到 SQLite3 符号的平台上使用 `sqlite3` 。

如果您是 Flutter 开发者，推荐直接引入 `sqlite3_flutter_libs` ，该库包含了如下平台的 SQLite 原生库：

- HarmonyOS
- Android
- iOS
- Windows
- MacOS
- Linux

引入后，原生库会被包含在应用中并随应用分发。因此您无需进行任何额外的配置，即可通过 `sqlite3` 在上述平台操作 SQLite 数据库。

```yaml
dependencies:
  sqlite3_flutter_libs:
    git:
      url: "https://github.com/SageMik/sqlite3-ohos.dart"
      path: "sqlite3_flutter_libs"
      ref: b8e37186ebdae03367ba132fb9c5c37b3b5f8d4f
```

若非如此，或者您希望自行编译提供 SQLite 原生库，请参考下文 [自行提供 SQLite 原生库](#自行提供-SQLite-原生库) 。

此外，不同平台 SQLite 原生库的提供情况还有一部分差异，也请参阅 [自行提供 SQLite 原生库](#自行提供-SQLite-原生库) 。

### 通过 `sqlite3` 操作数据库

1. 导入 `package:sqlite3/sqlite3.dart` 。 
2. 使用 `final db = sqlite3.open()` 打开数据库文件，或使用 `sqlite3.openInMemory()` 打开一个临时的内存数据库。 
3. 使用 `db.execute()` 执行语句，`db.prepare()` 预编译语句。 
4. 使用完毕，通过 `dispose()` 关闭数据库或已编译的语句。

更多示例请参考 [`example`](example) ，在 Flutter 上的简单使用请参考 [`../integration_tests/flutter_libs`](../integration_tests/flutter_libs) 。

### 自行提供 SQLite 原生库

#### 获取

除了**通过 `sqlite3_flutter_libs` 引入 SQLite 原生库**，您还可以在不同平台上通过不同的方式获取 SQLite 原生库，例如：

- **Android**：可以引入 [sqlite-android](https://github.com/requery/sqlite-android) 提供的 `libsqlite3x.so` 原生库。
- **iOS**：`sqlite3` 默认使用系统内置的 SQLite 。
- **MacOS**：同上，`sqlite3` 默认使用系统内置的 SQLite 。

如果您希望自行编译 SQLite 原生库，通过调整不同的编译选项自定义您的原生库，请参考 [SQLite 官方编译指南](https://sqlite.org/howtocompile.html)，或参考 `sqlite3_flutter_libs` 的在不同平台的编译实现，例如：

- **Android**：[sqlite-native-libraries](https://github.com/simolus3/sqlite-native-libraries) 中 [`sqlite3-native-library/cpp/CMakeLists.txt`](https://github.com/simolus3/sqlite-native-libraries/blob/master/sqlite3-native-library/cpp/CMakeLists.txt) 。
- **HarmonyOS**：[sqlite_ohos](https://github.com/SageMik/sqlite3_ohos/tree/main/sqlite3_native_library) 中 [`sqlite3_native_library/src/main/cpp/CMakeLists.txt`](https://github.com/SageMik/sqlite3_ohos/blob/main/sqlite3_native_library/src/main/cpp/CMakeLists.txt)（与 Android 实现保持一致）。

#### 覆盖

在获取 SQLite 原生库后，您需要覆盖本库查找 SQLite3 的方式（默认查找方式请参考 [`lib/src/ffi/load_library.dart`](lib/src/ffi/load_library.dart) ）。 例如，假定您获取了 Linux 平台下的 `sqlite3.so`，您可以通过如下代码使用指定的原生库：

```dart
import 'dart:ffi';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  open.overrideFor(OperatingSystem.linux, _openOnLinux);

  final db = sqlite3.openInMemory();
  
  // 操作数据库

  db.dispose();
}

DynamicLibrary _openOnLinux() {
  final scriptDir = File(Platform.script.toFilePath()).parent;
  final libraryNextToScript = File(join(scriptDir.path, 'sqlite3.so'));
  return DynamicLibrary.open(libraryNextToScript.path);
}
```