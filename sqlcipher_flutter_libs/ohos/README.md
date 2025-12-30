# SQLCipher HarmonyOS 插件

本目录包含 SQLCipher 在 HarmonyOS 平台的插件实现。

## 当前状态

**✅ 已完成**：HarmonyOS 平台的 SQLCipher 原生库（`libsqlcipher.so`）已经编译完成并包含在 `libs/` 目录中。

**注意**：`openssl/` 目录仅用于编译阶段，已被排除在版本控制之外（通过 `.gitignore`）。

## 使用方法

```dart
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  // 在 HarmonyOS 上覆盖动态库加载
  open.overrideFor(OperatingSystem.ohos, openCipherOnOhos);

  final db = sqlite3.open('encrypted.db');

  // 验证 SQLCipher 可用
  if (db.select('PRAGMA cipher_version;').isEmpty) {
    throw StateError('SQLCipher 不可用！');
  }

  // 设置加密密钥
  db.execute("PRAGMA key = 'your_passphrase';");

  // 正常使用加密数据库
}
```

## 重新编译指南

如果需要重新编译 `libsqlcipher.so`：

### 1. 编译 OpenSSL

```bash
export OHOS_NDK=/path/to/harmonyos-sdk/native
./build_openssl.sh
```

### 2. 修改 sqlite3.ArkTS 项目

克隆 [sqlite3.ArkTS](https://github.com/SageMik/sqlite3.ArkTS) 并修改 CMakeLists.txt:

- 下载 SQLCipher 源码（v4.5.7）
- 添加 OpenSSL 静态链接
- 添加编译宏 `SQLITE_HAS_CODEC` 等

详细配置参考 Linux/Windows 平台的 CMakeLists.txt。

### 3. 编译并复制产物

```bash
# 在 DevEco Studio 中编译生成 libsqlcipher.so
# 复制到此目录
cp libs/arm64-v8a/libsqlcipher.so sqlcipher_flutter_libs/ohos/libs/arm64-v8a/
cp libs/x86_64/libsqlcipher.so sqlcipher_flutter_libs/ohos/libs/x86_64/
```

**重要**：编译完成后可以删除 `openssl/` 目录，因为 OpenSSL 已静态链接进 `.so` 文件。

## 技术细节

- **SQLCipher 版本**: 4.5.7
- **OpenSSL 版本**: 3.x (静态链接)
- **支持架构**: arm64-v8a, x86_64
- **关键编译宏**: `SQLITE_HAS_CODEC`, `SQLITE_ENABLE_FTS5`, `SQLITE_ENABLE_JSON1`

## 参考资料

- [SQLCipher 官方文档](https://www.zetetic.net/sqlcipher/)
- [sqlite3.ArkTS](https://github.com/SageMik/sqlite3.ArkTS)
- [sqlcipher_flutter_libs Linux 实现](../linux/CMakeLists.txt)
- [sqlcipher_flutter_libs Windows 实现](../windows/CMakeLists.txt)
