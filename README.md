# sqlite3.dart

中文 | [English](README_EN.md)

该项目包含通过 `dart:ffi` 从 Dart 使用 SQLite 的 Dart 包。

此仓库中的主要包是 [`sqlite3`](sqlite3)，其中包含所有 Dart API 及其实现。
`package:sqlite3` 是一个纯 Dart 包，不依赖于 Flutter。
它既可以在 Flutter 应用程序中使用，也可以在独立的 Dart 应用程序中使用。

`sqlite3_flutter_libs` 和 `sqlcipher_flutter_libs` 包中没有任何 Dart 代码。Flutter 用户可以依赖其中一个包，在他们的应用程序中包含原生库。

## 示例用法

一个包含纯 Dart 基本用法示例的文件可以在这里找到 [这里](sqlite3/example/main.dart)。
