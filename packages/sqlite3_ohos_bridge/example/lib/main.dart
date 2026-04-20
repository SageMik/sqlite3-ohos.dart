import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3_ohos_bridge/sqlite3_ohos_bridge.dart';

import 'main_view_model.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final MainViewModel viewModel;

  @override
  void initState() {
    open.overrideForAll(() {
      // if (Platform.isAndroid) {
      //   return DynamicLibrary.open('libsqlite3x.so');
      // }
      return Sqlite3OhosBridge.openLibrary();
    });
    viewModel = MainViewModel();
    super.initState();
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Sqlite3OhosBridge 示例'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: AnimatedBuilder(
            animation: viewModel,
            builder: (context, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        spacing: 4,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SQLite ${viewModel.sqliteVersion}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            viewModel.osVersionLabel.isEmpty
                                ? '${Platform.operatingSystem} · ${Platform.operatingSystemVersion}'
                                : viewModel.osVersionLabel,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: viewModel.add,
                          child: const Text('新增'),
                        ),
                      ),
                      Expanded(
                        child: FilledButton(
                          onPressed: viewModel.updateOne,
                          child: const Text('更新选中'),
                        ),
                      ),
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: viewModel.deleteOne,
                          child: Text(
                            viewModel.selectedId != null ? '删除选中' : '删除末行',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: SingleChildScrollView(
                        child: DataTable(
                          dividerThickness: 0,
                          showCheckboxColumn: false,
                          headingRowHeight: 44,
                          columns: const [
                            DataColumn(label: Text('')),
                            DataColumn(label: Text('ID')),
                            DataColumn(label: Text('NAME')),
                          ],
                          rows: [
                            for (final r in viewModel.rows)
                              DataRow(
                                selected: r['id'] == viewModel.selectedId,
                                onSelectChanged: (v) {
                                  if (v != true) return;
                                  viewModel.select(r['id'] as int);
                                },
                                cells: [
                                  DataCell(
                                    Radio<int>(
                                      value: r['id'] as int,
                                      groupValue: viewModel.selectedId,
                                      onChanged: (v) {
                                        if (v == null) return;
                                        viewModel.select(v);
                                      },
                                    ),
                                  ),
                                  DataCell(Text('${r['id']}')),
                                  DataCell(Text('${r['name']}')),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
