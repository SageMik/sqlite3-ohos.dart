import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';

/** Sqlite3FlutterLibsPlugin **/
export default class Sqlite3FlutterLibsPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;

  constructor() {
  }

  getUniqueClassName(): string {
    return "Sqlite3FlutterLibsPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    // 使用 sqlcipher_flutter_libs channel 名称
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "sqlcipher_flutter_libs");
    this.channel.setMethodCallHandler(this)
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
    }
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    // 此方法用于在旧版 HarmonyOS 上预加载 libsqlcipher.so
    // 类似 Android 6 的解决方案
    try {
      // 注意：这里假设 libsqlcipher.so 已经通过 HAR 或其他方式提供
      // HarmonyOS 的动态库加载机制与 Android 类似
      result.success(null)
    } catch (e) {
      result.error(e.toString(), null, null)
    }
  }
}
