# sqlite3-ohos.dart

**中文** | [English](README_EN.md)

> [!TIP]
>
> 这是 [sqlite.dart](https://github.com/simolus3/sqlite3.dart) 的分支版本之一，基于 **[鸿蒙突击队 / Flutter 3.22.0](https://gitee.com/harmonycommando_flutter/flutter/tree/oh-3.22.0)** 对 HarmonyOS 进行了适配，并补充了中文文档说明。

本存储库集成了 SQLite 相关的 Dart/Flutter 包，这些包通过 `dart:ffi` 实现了在 Dart 中使用 SQLite 的功能。

[`sqlite3`](sqlite3) 是本存储库的核心包，包含了所有的 Dart API 及其实现。作为不依赖于 Flutter 的纯 Dart 包，[`sqlite3`](sqlite3) 既可以在 Flutter 中使用，也可以在独立的 Dart 程序中使用。

`sqlite3_flutter_libs` 和 `sqlcipher_flutter_libs` 中没有任何 Dart 代码。Flutter 开发者可以引入这些依赖以在程序中包含原生库，加载原生库后即可通过  Dart API 操作 SQLite 数据库，具体请参阅 [`sqlite3`](sqlite3) 的说明。

示例用法：[`sqlite3/example/main.dart`](sqlite3/example/main.dart)

## HarmonyOS 适配

| 包                                                | 适配情况                                   |
| ------------------------------------------------- | ------------------------------------------ |
| [`sqlite3`](sqlite3)                               | 已经可用，请参阅 [相关说明](sqlite3#sqlite3) |
| [`sqlite3_flutter_libs`](sqlite3_flutter_libs)     | 已经可用，同上                             |
| [`sqlcipher_flutter_libs`](sqlcipher_flutter_libs) | 暂未适配                                   |
| [`sqlite3_web`](sqlite3_web)                       | 无关                                       |
| [`integration_tests`](integration_tests)           | 示例程序，暂未适配                         |
