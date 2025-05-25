import 'package:flutter/services.dart';
import 'package:flutter_vap_plugin/vap_source_type.dart';

/// 用于控制VAP视频播放的控制器
class FlutterVapController {
  MethodChannel? _channel;

  /// 由插件内部调用，外部无需手动设置
  void bindChannel(MethodChannel channel) {
    _channel = channel;
  }

  /// 播放视频，必传 path/sourceType/repeatCount
  Future<void> play({required String path, required VapSourceType sourceType, int repeatCount = 1}) async {
    await _channel?.invokeMethod('play', {'path': path, 'sourceType': sourceType.type, 'repeatCount': repeatCount});
  }

  /// 停止播放
  Future<void> stop() async {
    await _channel?.invokeMethod('stop');
  }

  /// 销毁播放器实例
  Future<void> destroy() async {
    await _channel?.invokeMethod('destroy');
  }
}
