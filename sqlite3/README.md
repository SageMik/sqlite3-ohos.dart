# sqlite3

**中文** | [English](README_EN.md)

通过 `dart:ffi` 提供对 [SQLite](https://www.sqlite.org/index.html) 的 Dart 绑定。

## 使用本库

### 引入/迁移

本库是 [sqlite.dart](https://github.com/simolus3/sqlite3.dart) 的分支版本之一，基于 [鸿蒙先锋队/flutter](https://gitee.com/harmonycommando_flutter/flutter)（Flutter 版本：3.22）对 HarmonyOS 进行了适配，目前已成功在 Mac Arm 鸿蒙模拟器 上运行。

由于尚未发布版本，因此需要在 `pubspec.yaml` 中通过 Git 的方式引入或从原版迁移：

```yaml
dependencies:
  
  sqlite3:
    git:
      url: "https://github.com/SageMik/sqlite3-ohos.dart"
      path: "sqlite3"
      ref: b8e37186ebdae03367ba132fb9c5c37b3b5f8d4f

  # sqlite3_flutter_libs 根据实际使用情况决定是否引入
  sqlite3_flutter_libs:
    git:
      url: "https://github.com/SageMik/sqlite3-ohos.dart"
      path: "sqlite3_flutter_libs"
      ref: b8e37186ebdae03367ba132fb9c5c37b3b5f8d4f
```

> [!TIP]
>
> 一种不需要从原版 `sqlite3` 迁移至本分支版本，但可能会稍显麻烦的 HarmonyOS 适配方案请参阅 [此处](#继续使用原版-sqlite3-的适配方案) 。

### 使用

1. 确保您的环境中存在可访问的 SQLite3 原生共享库（参见下文的 [支持平台](#支持平台) ）。
2. 导入 `package:sqlite3/sqlite3.dart` 。
3. 使用 `final db = sqlite3.open()` 打开数据库文件，或使用 `sqlite3.openInMemory()` 打开一个临时的内存数据库。
4. 使用 `db.execute()` 执行语句，`db.prepare()` 预编译语句。
5. 使用完毕，通过 `dispose()` 关闭数据库或已编译的语句。

更详尽的示例参见 [此处](example) 。

## 支持平台

您能够在任何可以通过 `DynamicLibrary` 获取 SQLite3 符号的平台上使用本库。此外，本库还支持在 Web 上访问编译为 WebAssembly 的 SQLite3 。Web 目前仅正式支持 `dartdevc` 和 `dart2js` ，对 `dart2wasm` 的支持 [是实验性且不完整的](https://github.com/simolus3/sqlite3.dart/issues/230) 。

### HarmonyOS

#### 继续使用原版 `sqlite3` 的适配方案

新建 `sqlite3.dart` 文件，内容如下：

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

首先，将项目中所有使用到 `package:sqlite3/sqlite3.dart` 中的 `sqlite3` 变量的地方，替换为上述文件的 `sqlite3` 变量。

然后，如果您能够自行编译或获取 HarmonyOS 版本的 `libsqlite3.so` ，则无需引入 `sqlite3_flutter_libs` ，反之仍需在 `pubspec.yaml` 引入 `sqlite3_flutter_libs` ，以让 `DynamicLibrary.open` 访问 SQLite 原生库：

```dart
sqlite3_flutter_libs:
  git:
    url: "https://github.com/SageMik/sqlite3-ohos.dart"
    path: "sqlite3_flutter_libs"
    ref: b8e37186ebdae03367ba132fb9c5c37b3b5f8d4f
```

### Android

### iOS

### Linux

### MacOS

### Windows

### Web

### 自行提供 SQLite 原生库

除了使用操作系统提供的 `sqlite3` 库外，您还可以随应用一起发布自定义的 `sqlite3` 库。
您可以重写此包查找 `sqlite3` 的方式，改为使用自定义库。
例如，如果您发布的 `sqlite3.so` 文件与应用程序相邻，可以使用以下代码：
