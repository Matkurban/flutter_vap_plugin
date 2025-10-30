import 'dart:io';

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
  /// 循环播放repeatCount参数只在Android管用
  /// [deleteOnEnd] 决定资源播放完毕后是否应删除该文件。
  Future<void> play({
    required String path,
    required VapSourceType sourceType,
    int repeatCount = 0,
    bool deleteOnEnd = true,
  }) async {
    _lastPath = path;
    _lastSourceType = sourceType;
    if (Platform.isAndroid) {
      await _channel?.invokeMethod('play', {
        'path': path,
        'sourceType': sourceType.type,
        'repeatCount': repeatCount,
        'deleteOnEnd': deleteOnEnd,
      });
    }
    if (Platform.isIOS) {
      await _channel?.invokeMethod('play', {
        'path': path,
        'sourceType': sourceType.type,
      });
    }
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
