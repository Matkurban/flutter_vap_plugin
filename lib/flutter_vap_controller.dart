import 'package:flutter/services.dart';

/// 用于控制VAP视频播放的控制器
class FlutterVapController {
  MethodChannel? _channel;

  /// 由插件内部调用，外部无需手动设置
  void bindChannel(MethodChannel channel) {
    _channel = channel;
  }

  /// 播放视频
  Future<void> play() async {
    await _channel?.invokeMethod('play');
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
