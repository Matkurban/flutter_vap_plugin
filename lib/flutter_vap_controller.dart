import 'package:flutter/services.dart';
import 'package:flutter_vap_plugin/vap_source_type.dart';

/// 用于控制VAP视频播放的控制器
class FlutterVapController {
  MethodChannel? _channel;
  String? _lastPath;
  VapSourceType? _lastSourceType;

  /// 由插件内部调用，外部无需手动设置
  void bindChannel(MethodChannel channel) {
    _channel = channel;
  }

  /// 播放视频，必传 path/sourceType
  Future<void> play({
    required String path,
    required VapSourceType sourceType,
  }) async {
    _lastPath = path;
    _lastSourceType = sourceType;
    await _channel?.invokeMethod('play', {
      'path': path,
      'sourceType': sourceType.type,
    });
  }

  /// 重新播放最后一次播放的视频
  Future<void> replay() async {
    if (_lastPath != null && _lastSourceType != null) {
      await play(path: _lastPath!, sourceType: _lastSourceType!);
    }
  }

  /// 停止播放
  Future<void> stop() async {
    await _channel?.invokeMethod('stop');
  }
}
