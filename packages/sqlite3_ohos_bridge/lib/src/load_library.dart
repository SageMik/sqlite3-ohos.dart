import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:meta/meta.dart';

@internal
DynamicLibrary defaultOpen() {
  if (Platform.isAndroid) {
    try {
      return DynamicLibrary.open('libsqlite3.so');
      // ignore: avoid_catching_errors
    } on ArgumentError {
      // On some (especially old) Android devices, we somehow can't dlopen
      // libraries shipped with the apk. We need to find the full path of the
      // library (/data/data/<id>/lib/libsqlite3.so) and open that one.
      // For details, see https://github.com/simolus3/moor/issues/420
      final appIdAsBytes = File('/proc/self/cmdline').readAsBytesSync();

      // app id ends with the first \0 character in here.
      final endOfAppId = max(appIdAsBytes.indexOf(0), 0);
      final appId = String.fromCharCodes(appIdAsBytes.sublist(0, endOfAppId));

      return DynamicLibrary.open('/data/data/$appId/lib/libsqlite3.so');
    }
  } else if (Platform.isLinux) {
    // Recent versions of the `sqlite3_flutter_libs` package bundle sqlite3 with
    // the app, let's see if that's the case here.
    final self = DynamicLibrary.executable();
    if (self.providesSymbol(
        'sqlite3_flutter_libs_plugin_register_with_registrar')) {
      return self;
    }

    // Fall-back to system's libsqlite3 otherwise.
    return DynamicLibrary.open('libsqlite3.so');
  } else if (Platform.isIOS) {
    // Prefer loading a dynamically-linked framework bundled by the
    // sqlite3_flutter_libs package.
    //
    // If that is unavailable, we can try looking up symbols in the current
    // process. They'll likely be available there because sqlite3 is part of
    // Apple SDKs, but we only want to do that as a fallback because the one
    // shipped with sqlite3_flutter_libs is more recent and supports more
    // features.
    return _tryLoadingFromSqliteFlutterLibs() ?? DynamicLibrary.process();
  } else if (Platform.isMacOS) {
    if (_tryLoadingFromSqliteFlutterLibs() case final opened?) {
      return opened;
    }

    DynamicLibrary result;

    result = DynamicLibrary.process();

    // Check if the process includes sqlite3. If it doesn't, fallback to the
    // library from the system.
    if (!result.providesSymbol('sqlite3_version')) {
      //No embed Sqlite3 library found with sqlite3_version function
      //Load pre installed library on MacOS
      result = DynamicLibrary.open('/usr/lib/libsqlite3.dylib');
    }
    return result;
  } else if (Platform.isWindows) {
    try {
      // Compability with older versions of package:sqlite3 that did this
      return DynamicLibrary.open('sqlite3.dll');
    } on ArgumentError catch (_) {
      // Load the OS distribution of sqlite3 as a fallback
      // This is used as the backend for .NET based Database APIs
      // and several Windows apps & features,
      // but you may still want to bring your own copy of sqlite3
      // since it's undocumented functionality.
      // https://github.com/microsoft/win32metadata/issues/824#issuecomment-1067220882
      return DynamicLibrary.open('winsqlite3.dll');
    }
  }

  throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
}

DynamicLibrary? _tryLoadingFromSqliteFlutterLibs() {
  const paths = [
    // With sqlite3_flutter_libs and CocoaPods, we depend on
    // https://github.com/clemensg/sqlite3pod, which builds a dynamic SQLite
    // framework.
    'sqlite3.framework/sqlite3',
    // With sqlite3_flutter_libs and SwiftPM, we depend on
    // https://github.com/simolus3/CSQLite/, which builds a dynamic framework
    // named CSQLite exporting SQLite symbols.
    'CSQLite.framework/CSQLite',
  ];

  for (final path in paths) {
    try {
      return DynamicLibrary.open(path);
      // Ignoring the error because its the only way to know if it was sucessful
      // or not...
      // ignore: avoid_catching_errors
    } on ArgumentError catch (_) {}
  }

  return null;
}