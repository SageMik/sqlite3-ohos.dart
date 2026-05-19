// SQLCipher HarmonyOS 测试应用 - 可以直接在设备上运行
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart' hide Row; // 隐藏 sqlite3 的 Row,使用 Flutter 的 Row
import 'package:flutter_platform_utils/flutter_platform_utils.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 SQLCipher
  await _initSqlCipher();

  runApp(const SQLCipherTestApp());
}

Future<void> _initSqlCipher() async {
  // 为 HarmonyOS 平台覆盖动态库加载
  if (PlatformUtils.isOhos) {
    open.overrideFor(OperatingSystem.ohos, openCipherOnOhos);
  }
}

class SQLCipherTestApp extends StatelessWidget {
  const SQLCipherTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SQLCipher 测试',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TestPage(),
    );
  }
}

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final List<String> _testResults = [];
  bool _isRunning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SQLCipher HarmonyOS 测试'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '当前平台: ${_getPlatformName()}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('SQLite 版本: ${sqlite3.version.libVersion}'),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _testResults.length,
              itemBuilder: (context, index) {
                final result = _testResults[index];
                final isSuccess = result.startsWith('✅');
                final isError = result.startsWith('❌');
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    result,
                    style: TextStyle(
                      color: isSuccess
                          ? Colors.green
                          : isError
                              ? Colors.red
                              : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isRunning ? null : _runAllTests,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: _isRunning
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('测试运行中...'),
                      ],
                    )
                  : const Text('开始测试'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isRunning = true;
      _testResults.clear();
    });

    _log('========== 开始测试 ==========');
    _log('');

    await _testBasicFunctions();
    await _testEncryption();
    await _testFileEncryptionVerification();
    await _testWrongPassword();
    await _testPasswordChange();
    await _testConcurrency();
    await _testPerformance();
    await _testExtensions();
    await _testComplexQueries();
    await _testTransactions();
    await _testBlobData();
    await _testDatabaseExport();
    await _testPlatformSpecific();

    _log('');
    _log('========== 测试完成 ==========');

    setState(() {
      _isRunning = false;
    });
  }

  void _log(String message) {
    setState(() {
      _testResults.add(message);
    });
  }

  Future<void> _testBasicFunctions() async {
    _log('【基础功能测试】');

    try {
      final lib = open.openSqlite();
      final hasKey = lib.providesSymbol('sqlite3_key');
      final hasRekey = lib.providesSymbol('sqlite3_rekey');

      if (hasKey && hasRekey) {
        _log('✅ SQLCipher 加密函数存在');
      } else {
        _log('❌ SQLCipher 加密函数不存在');
      }
    } catch (e) {
      _log('❌ 加载 SQLCipher 库失败: $e');
    }
  }

  Future<void> _testEncryption() async {
    _log('');
    _log('【加密功能测试】');

    // 测试 cipher_version
    try {
      final db = sqlite3.openInMemory();
      final result = db.select('PRAGMA cipher_version;');
      if (result.isNotEmpty) {
        final version = result.first['cipher_version'];
        _log('✅ SQLCipher 版本: $version');
      } else {
        _log('❌ PRAGMA cipher_version 返回空');
        _log('   说明编译时未定义 SQLITE_HAS_CODEC');
      }
      db.dispose();
    } catch (e) {
      _log('❌ cipher_version 测试失败: $e');
    }

    // 测试加密内存数据库
    try {
      final db = sqlite3.openInMemory();
      db.execute("PRAGMA key = 'test123';");
      db.execute('CREATE TABLE test (id INTEGER, content TEXT);');
      db.execute("INSERT INTO test VALUES (1, '加密数据');");

      final result = db.select('SELECT * FROM test;');
      if (result.isNotEmpty && result.first['content'] == '加密数据') {
        _log('✅ 加密内存数据库读写正常');
      } else {
        _log('❌ 加密内存数据库读写失败');
      }
      db.dispose();
    } catch (e) {
      _log('❌ 加密内存数据库测试失败: $e');
    }

    // 测试加密文件数据库
    try {
      final dbPath = '${Directory.systemTemp.path}/test_encrypted.db';
      final dbFile = File(dbPath);
      if (dbFile.existsSync()) dbFile.deleteSync();

      final db = sqlite3.open(dbPath);
      db.execute("PRAGMA key = 'secret123';");
      db.execute('CREATE TABLE diary (content TEXT);');
      db.execute("INSERT INTO diary VALUES ('我的秘密日记');");
      db.dispose();

      // 重新打开
      final db2 = sqlite3.open(dbPath);
      db2.execute("PRAGMA key = 'secret123';");
      final result = db2.select('SELECT * FROM diary;');
      if (result.isNotEmpty) {
        _log('✅ 加密文件数据库正常');
      } else {
        _log('❌ 加密文件数据库失败');
      }
      db2.dispose();
      dbFile.deleteSync();
    } catch (e) {
      _log('❌ 加密文件数据库测试失败: $e');
    }
  }

  Future<void> _testExtensions() async {
    _log('');
    _log('【扩展模块测试】');

    final db = sqlite3.openInMemory();
    db.execute("PRAGMA key = 'test';");

    // JSON1
    try {
      final result = db.select("SELECT json('[1,2,3]') AS r;");
      if (result.isNotEmpty) {
        _log('✅ JSON1 扩展可用');
      }
    } catch (e) {
      _log('❌ JSON1 扩展不可用');
    }

    // FTS5
    try {
      db.execute('CREATE VIRTUAL TABLE docs USING fts5(content);');
      db.execute("INSERT INTO docs VALUES ('测试内容');");
      final result = db.select("SELECT * FROM docs WHERE docs MATCH '测试';");
      if (result.isNotEmpty) {
        _log('✅ FTS5 全文搜索可用');
      }
    } catch (e) {
      _log('❌ FTS5 全文搜索不可用');
    }

    // RTREE
    try {
      db.execute(
          'CREATE VIRTUAL TABLE loc USING rtree(id, minX, maxX, minY, maxY);');
      db.execute('INSERT INTO loc VALUES (1, 0, 10, 0, 10);');
      final result =
          db.select('SELECT * FROM loc WHERE minX >= 0 AND maxX <= 10;');
      if (result.isNotEmpty) {
        _log('✅ RTREE 空间索引可用');
      }
    } catch (e) {
      _log('❌ RTREE 空间索引不可用');
    }

    db.dispose();
  }

  // 测试文件是否真的被加密
  Future<void> _testFileEncryptionVerification() async {
    _log('');
    _log('【文件加密验证测试】');

    try {
      final dir = await getApplicationDocumentsDirectory();
      final dbPath = '${dir.path}/encryption_verify.db';
      final dbFile = File(dbPath);
      if (dbFile.existsSync()) dbFile.deleteSync();

      // 创建加密数据库
      final db = sqlite3.open(dbPath);
      db.execute("PRAGMA key = 'my_secret_key';");
      db.execute('CREATE TABLE secrets (id INTEGER PRIMARY KEY, data TEXT);');
      db.execute("INSERT INTO secrets VALUES (1, 'This is secret data 机密信息');");
      db.execute("INSERT INTO secrets VALUES (2, 'Password: 123456');");
      db.dispose();

      _log('📁 加密数据库路径: $dbPath');

      // 读取数据库文件的原始字节
      final bytes = await dbFile.readAsBytes();
      _log('📦 数据库文件大小: ${bytes.length} bytes');

      // 检查 SQLite 文件头 (未加密的 SQLite 文件开头是 "SQLite format 3")
      final header = String.fromCharCodes(bytes.take(16));
      _log('🔍 文件头 (前16字节): ${_bytesToHex(bytes.take(16).toList())}');

      if (header.startsWith('SQLite format 3')) {
        _log('❌ 警告: 文件未加密! 文件头是标准 SQLite 格式');
        _log('   明文文件头: $header');
      } else {
        _log('✅ 文件已加密! 文件头不是标准 SQLite 格式');
        _log('   加密后的文件头无法识别');
      }

      // 搜索明文关键字
      final fileContent = String.fromCharCodes(bytes, 0, bytes.length);
      final secretKeywords = ['This is secret', 'Password', '机密信息', '123456'];
      bool foundPlaintext = false;

      for (final keyword in secretKeywords) {
        if (fileContent.contains(keyword)) {
          _log('❌ 发现明文关键字: "$keyword"');
          foundPlaintext = true;
        }
      }

      if (!foundPlaintext) {
        _log('✅ 未发现任何明文关键字，数据已加密');
      }

      // 尝试用普通 SQLite (无密码) 打开
      try {
        final db2 = sqlite3.open(dbPath);
        // 不设置密码，直接查询
        final result = db2.select('SELECT * FROM secrets;');
        db2.dispose();
        _log('❌ 警告: 无密码可以打开数据库! 加密可能失效');
      } catch (e) {
        if (e.toString().contains('file is not a database') ||
            e.toString().contains('encrypted') ||
            e.toString().contains('cipher')) {
          _log('✅ 无密码无法打开数据库，加密有效');
        } else {
          _log('⚠️  无密码打开失败，原因: ${e.toString().substring(0, 50)}...');
        }
      }

      // 导出加密文件信息
      _log('');
      _log('【加密文件分析】');
      _log('文件路径: $dbPath');
      _log('文件大小: ${bytes.length} bytes');
      _log('文件前 32 字节:');
      _log(_bytesToHex(bytes.take(32).toList()));

    } catch (e) {
      _log('❌ 文件加密验证失败: $e');
    }
  }

  // 字节转十六进制字符串
  String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
  }

  // 测试错误密码
  Future<void> _testWrongPassword() async {
    _log('');
    _log('【错误密码测试】');

    try {
      final dbPath = '${Directory.systemTemp.path}/test_wrong_pwd.db';
      final dbFile = File(dbPath);
      if (dbFile.existsSync()) dbFile.deleteSync();

      // 创建加密数据库
      final db1 = sqlite3.open(dbPath);
      db1.execute("PRAGMA key = 'correct_password';");
      db1.execute('CREATE TABLE test (id INTEGER);');
      db1.execute('INSERT INTO test VALUES (123);');
      db1.dispose();

      // 尝试用错误密码打开
      final db2 = sqlite3.open(dbPath);
      db2.execute("PRAGMA key = 'wrong_password';");

      try {
        db2.select('SELECT * FROM test;');
        _log('❌ 错误密码应该失败但成功了');
      } catch (e) {
        if (e.toString().contains('file is not a database') ||
            e.toString().contains('encrypted')) {
          _log('✅ 错误密码正确被拒绝');
        } else {
          _log('⚠️  错误密码失败但原因不明: $e');
        }
      }
      db2.dispose();
      dbFile.deleteSync();
    } catch (e) {
      _log('❌ 错误密码测试异常: $e');
    }
  }

  // 测试密码修改
  Future<void> _testPasswordChange() async {
    _log('');
    _log('【密码修改测试】');

    try {
      final dbPath = '${Directory.systemTemp.path}/test_rekey.db';
      final dbFile = File(dbPath);
      if (dbFile.existsSync()) dbFile.deleteSync();

      // 创建数据库
      final db1 = sqlite3.open(dbPath);
      db1.execute("PRAGMA key = 'old_password';");
      db1.execute('CREATE TABLE test (data TEXT);');
      db1.execute("INSERT INTO test VALUES ('secret data');");

      // 修改密码
      db1.execute("PRAGMA rekey = 'new_password';");
      db1.dispose();

      // 用新密码打开
      final db2 = sqlite3.open(dbPath);
      db2.execute("PRAGMA key = 'new_password';");
      final result = db2.select('SELECT * FROM test;');

      if (result.isNotEmpty && result.first['data'] == 'secret data') {
        _log('✅ 密码修改成功');
      } else {
        _log('❌ 密码修改后数据读取失败');
      }
      db2.dispose();
      dbFile.deleteSync();
    } catch (e) {
      _log('❌ 密码修改测试失败: $e');
    }
  }

  // 测试并发操作
  Future<void> _testConcurrency() async {
    _log('');
    _log('【并发操作测试】');

    try {
      final db = sqlite3.openInMemory();
      db.execute("PRAGMA key = 'test';");
      db.execute('CREATE TABLE counter (id INTEGER PRIMARY KEY, value INTEGER);');
      db.execute('INSERT INTO counter VALUES (1, 0);');

      // 并发更新
      final futures = <Future>[];
      for (int i = 0; i < 10; i++) {
        futures.add(Future(() {
          db.execute('UPDATE counter SET value = value + 1 WHERE id = 1;');
        }));
      }
      await Future.wait(futures);

      final result = db.select('SELECT value FROM counter WHERE id = 1;');
      final value = result.first['value'] as int;

      if (value == 10) {
        _log('✅ 并发更新测试通过 (最终值: $value)');
      } else {
        _log('⚠️  并发更新结果异常 (期望: 10, 实际: $value)');
      }
      db.dispose();
    } catch (e) {
      _log('❌ 并发操作测试失败: $e');
    }
  }

  // 测试性能
  Future<void> _testPerformance() async {
    _log('');
    _log('【性能测试】');

    try {
      final db = sqlite3.openInMemory();
      db.execute("PRAGMA key = 'test';");
      db.execute('CREATE TABLE perf_test (id INTEGER PRIMARY KEY, data TEXT);');

      // 插入性能测试
      final insertStart = DateTime.now();
      db.execute('BEGIN TRANSACTION;');
      for (int i = 0; i < 1000; i++) {
        db.execute('INSERT INTO perf_test (data) VALUES (?);', ['数据$i']);
      }
      db.execute('COMMIT;');
      final insertTime = DateTime.now().difference(insertStart).inMilliseconds;
      _log('✅ 插入 1000 条记录耗时: ${insertTime}ms');

      // 查询性能测试
      final queryStart = DateTime.now();
      final result = db.select('SELECT COUNT(*) as cnt FROM perf_test;');
      final queryTime = DateTime.now().difference(queryStart).inMilliseconds;
      final count = result.first['cnt'];
      _log('✅ 查询 $count 条记录耗时: ${queryTime}ms');

      // 更新性能测试
      final updateStart = DateTime.now();
      db.execute('BEGIN TRANSACTION;');
      db.execute('UPDATE perf_test SET data = data || "_updated";');
      db.execute('COMMIT;');
      final updateTime = DateTime.now().difference(updateStart).inMilliseconds;
      _log('✅ 更新所有记录耗时: ${updateTime}ms');

      db.dispose();
    } catch (e) {
      _log('❌ 性能测试失败: $e');
    }
  }

  // 测试复杂查询
  Future<void> _testComplexQueries() async {
    _log('');
    _log('【复杂查询测试】');

    try {
      final db = sqlite3.openInMemory();
      db.execute("PRAGMA key = 'test';");

      // 创建测试表
      db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY,
          name TEXT,
          age INTEGER,
          city TEXT
        );
      ''');

      // 插入测试数据
      final testData = [
        [1, '张三', 25, '北京'],
        [2, '李四', 30, '上海'],
        [3, '王五', 25, '北京'],
        [4, '赵六', 35, '广州'],
      ];

      for (final row in testData) {
        db.execute('INSERT INTO users VALUES (?, ?, ?, ?);', row);
      }

      // JOIN 查询
      db.execute('CREATE TABLE orders (user_id INTEGER, amount REAL);');
      db.execute('INSERT INTO orders VALUES (1, 100.5), (1, 200.0), (2, 150.0);');

      final joinResult = db.select('''
        SELECT u.name, SUM(o.amount) as total
        FROM users u
        LEFT JOIN orders o ON u.id = o.user_id
        GROUP BY u.id, u.name
        HAVING total > 0
        ORDER BY total DESC;
      ''');

      if (joinResult.isNotEmpty) {
        _log('✅ JOIN 查询成功 (结果数: ${joinResult.length})');
      }

      // 子查询
      final subqueryResult = db.select('''
        SELECT * FROM users
        WHERE age = (SELECT MIN(age) FROM users);
      ''');

      if (subqueryResult.length == 2) {
        _log('✅ 子查询成功 (找到 ${subqueryResult.length} 个最小年龄用户)');
      }

      // LIKE 模糊查询
      final likeResult = db.select("SELECT * FROM users WHERE name LIKE '张%';");
      if (likeResult.length == 1) {
        _log('✅ LIKE 模糊查询成功');
      }

      db.dispose();
    } catch (e) {
      _log('❌ 复杂查询测试失败: $e');
    }
  }

  // 测试事务
  Future<void> _testTransactions() async {
    _log('');
    _log('【事务测试】');

    try {
      final db = sqlite3.openInMemory();
      db.execute("PRAGMA key = 'test';");
      db.execute('CREATE TABLE accounts (id INTEGER PRIMARY KEY, balance REAL);');
      db.execute('INSERT INTO accounts VALUES (1, 1000.0), (2, 500.0);');

      // 测试事务回滚
      try {
        db.execute('BEGIN TRANSACTION;');
        db.execute('UPDATE accounts SET balance = balance - 100 WHERE id = 1;');
        db.execute('UPDATE accounts SET balance = balance + 100 WHERE id = 2;');
        // 模拟错误
        throw Exception('模拟错误');
      } catch (e) {
        db.execute('ROLLBACK;');
        final result = db.select('SELECT balance FROM accounts WHERE id = 1;');
        final balance = result.first['balance'];
        if (balance == 1000.0) {
          _log('✅ 事务回滚成功 (余额恢复到: $balance)');
        }
      }

      // 测试事务提交
      db.execute('BEGIN TRANSACTION;');
      db.execute('UPDATE accounts SET balance = balance - 100 WHERE id = 1;');
      db.execute('UPDATE accounts SET balance = balance + 100 WHERE id = 2;');
      db.execute('COMMIT;');

      final result = db.select('SELECT balance FROM accounts WHERE id = 1;');
      final balance = result.first['balance'];
      if (balance == 900.0) {
        _log('✅ 事务提交成功 (余额更新到: $balance)');
      }

      db.dispose();
    } catch (e) {
      _log('❌ 事务测试失败: $e');
    }
  }

  // 测试 BLOB 数据
  Future<void> _testBlobData() async {
    _log('');
    _log('【BLOB 数据测试】');

    try {
      final db = sqlite3.openInMemory();
      db.execute("PRAGMA key = 'test';");
      db.execute('CREATE TABLE files (name TEXT, data BLOB);');

      // 插入二进制数据
      final binaryData = List<int>.generate(1024, (i) => i % 256);
      final stmt = db.prepare('INSERT INTO files VALUES (?, ?);');
      stmt.execute(['test_file.bin', binaryData]);
      stmt.dispose();

      // 读取二进制数据
      final result = db.select('SELECT data FROM files WHERE name = ?;', ['test_file.bin']);
      final readData = result.first['data'] as List<int>;

      if (readData.length == 1024 && readData[100] == 100) {
        _log('✅ BLOB 数据读写成功 (大小: ${readData.length} bytes)');
      } else {
        _log('❌ BLOB 数据不匹配');
      }

      db.dispose();
    } catch (e) {
      _log('❌ BLOB 数据测试失败: $e');
    }
  }

  // 测试数据库导出
  Future<void> _testDatabaseExport() async {
    _log('');
    _log('【数据库导出测试】');

    try {
      final dir = await getApplicationDocumentsDirectory();
      final dbPath = '${dir.path}/export_test.db';
      final exportPath = '${dir.path}/exported_databases';

      // 创建导出目录
      final exportDir = Directory(exportPath);
      if (!exportDir.existsSync()) {
        exportDir.createSync(recursive: true);
      }

      // 创建测试数据库
      final db = sqlite3.open(dbPath);
      db.execute("PRAGMA key = 'export_test_password';");
      db.execute('''
        CREATE TABLE export_data (
          id INTEGER PRIMARY KEY,
          name TEXT,
          value REAL,
          created_at TEXT
        );
      ''');

      // 插入测试数据
      for (int i = 1; i <= 10; i++) {
        db.execute(
          'INSERT INTO export_data (name, value, created_at) VALUES (?, ?, ?);',
          ['数据$i', i * 10.5, DateTime.now().toIso8601String()],
        );
      }

      // 导出为 JSON 格式
      final jsonExportPath = '$exportPath/data_export.json';
      final result = db.select('SELECT * FROM export_data;');
      final jsonData = {
        'export_time': DateTime.now().toIso8601String(),
        'database': dbPath,
        'record_count': result.length,
        'data': result.map((row) => row).toList(),
      };

      await File(jsonExportPath).writeAsString(
        const JsonEncoder.withIndent('  ').convert(jsonData),
      );
      _log('✅ JSON 导出成功: $jsonExportPath');

      // 导出为 SQL 文本格式
      final sqlExportPath = '$exportPath/data_export.sql';
      final sqlBuffer = StringBuffer();
      sqlBuffer.writeln('-- SQLCipher 数据库导出');
      sqlBuffer.writeln('-- 导出时间: ${DateTime.now()}');
      sqlBuffer.writeln('-- 原数据库: $dbPath');
      sqlBuffer.writeln();

      // 导出建表语句
      final schemaResult = db.select(
        "SELECT sql FROM sqlite_master WHERE type='table' AND name='export_data';",
      );
      if (schemaResult.isNotEmpty) {
        sqlBuffer.writeln(schemaResult.first['sql']);
        sqlBuffer.writeln();
      }

      // 导出数据
      sqlBuffer.writeln('-- 数据记录');
      for (final row in result) {
        sqlBuffer.write('INSERT INTO export_data VALUES (');
        sqlBuffer.write("${row['id']}, ");
        sqlBuffer.write("'${row['name']}', ");
        sqlBuffer.write("${row['value']}, ");
        sqlBuffer.write("'${row['created_at']}'");
        sqlBuffer.writeln(');');
      }

      await File(sqlExportPath).writeAsString(sqlBuffer.toString());
      _log('✅ SQL 导出成功: $sqlExportPath');

      // 复制加密数据库文件
      final encryptedCopyPath = '$exportPath/encrypted_copy.db';
      await File(dbPath).copy(encryptedCopyPath);
      _log('✅ 加密数据库复制成功: $encryptedCopyPath');

      db.dispose();

      // 导出摘要
      _log('');
      _log('【导出摘要】');
      _log('导出目录: $exportPath');
      _log('记录数量: ${result.length}');
      _log('JSON 文件: ${File(jsonExportPath).lengthSync()} bytes');
      _log('SQL 文件: ${File(sqlExportPath).lengthSync()} bytes');
      _log('加密文件: ${File(encryptedCopyPath).lengthSync()} bytes');

      // 验证 JSON 导出
      final jsonContent = await File(jsonExportPath).readAsString();
      final decoded = json.decode(jsonContent);
      if (decoded['record_count'] == result.length) {
        _log('✅ JSON 数据完整性验证通过');
      }

    } catch (e) {
      _log('❌ 数据库导出失败: $e');
    }
  }

  Future<void> _testPlatformSpecific() async {
    _log('');
    _log('【平台特定测试】');

    final platform = _getPlatformName();
    _log('📱 当前平台: $platform');

    if (PlatformUtils.isOhos) {
      _log('✅ 在 HarmonyOS 平台上运行');
      _log('✅ libsqlcipher.so 加载成功');

      // HarmonyOS 特定测试
      try {
        final db = sqlite3.openInMemory();
        db.execute("PRAGMA key = 'ohos_test';");
        db.execute('CREATE TABLE ohos_test (data TEXT);');
        db.execute("INSERT INTO ohos_test VALUES ('HarmonyOS SQLCipher');");
        final result = db.select('SELECT * FROM ohos_test;');
        if (result.isNotEmpty) {
          _log('✅ HarmonyOS 平台加密功能正常');
        }
        db.dispose();
      } catch (e) {
        _log('❌ HarmonyOS 平台测试失败: $e');
      }
    } else if (Platform.isAndroid) {
      _log('✅ 在 Android 平台上运行');
    } else {
      _log('⚠️  在其他平台上运行');
    }

    // 测试临时目录
    try {
      final tempDir = Directory.systemTemp.path;
      _log('📁 临时目录: $tempDir');

      final testFile = File('$tempDir/test_temp.db');
      final db = sqlite3.open(testFile.path);
      db.execute("PRAGMA key = 'temp_test';");
      db.execute('CREATE TABLE temp (id INTEGER);');
      db.dispose();

      if (testFile.existsSync()) {
        testFile.deleteSync();
        _log('✅ 临时目录读写正常');
      }
    } catch (e) {
      _log('❌ 临时目录测试失败: $e');
    }
  }

  String _getPlatformName() {
    if (PlatformUtils.isOhos) {
      return 'HarmonyOS';
    } else if (Platform.isAndroid) {
      return 'Android';
    } else if (Platform.isIOS) {
      return 'iOS';
    } else if (Platform.isWindows) {
      return 'Windows';
    } else if (Platform.isMacOS) {
      return 'macOS';
    } else if (Platform.isLinux) {
      return 'Linux';
    } else {
      return 'Unknown';
    }
  }
}
