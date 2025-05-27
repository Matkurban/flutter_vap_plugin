import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vap_plugin/flutter_vap_controller.dart';
import 'package:flutter_vap_plugin/vap_scale_type.dart';

typedef VapErrorCallback = void Function(int errorType, String errorMsg);
typedef VapFrameCallback = void Function(int frameIndex);
typedef VapCallback = void Function();

class FlutterVapView extends StatefulWidget {
  const FlutterVapView({
    super.key,
    required this.controller,
    this.onVideoStart,
    this.onVideoFinish,
    this.onVideoStop,
    this.onVideoRender,
    this.onFailed,
    this.scaleType = VapScaleType.fitXY,
  });

  /// 外部控制器，必填
  final FlutterVapController controller;
  // Callback when video starts playing
  // 视频开始播放回调
  final VapCallback? onVideoStart;
  // Callback when video playback completes
  // 视频播放完成回调
  final VapCallback? onVideoFinish;
  // Callback when video is destroyed
  // 视频销毁回调
  final VapCallback? onVideoStop;
  // Callback for each rendered frame, returns current frame index
  // 渲染帧回调，返回当前帧索引
  final VapFrameCallback? onVideoRender;
  // Callback when playback fails, returns error type and message
  // 播放失败回调，返回错误类型和信息
  final VapErrorCallback? onFailed;

  /// 视频缩放类型，默认 fitXY
  /// Video scaling type, default is fitXY
  final VapScaleType scaleType;

  @override
  State<FlutterVapView> createState() => _FlutterVapViewState();
}

class _FlutterVapViewState extends State<FlutterVapView> {
  MethodChannel? _channel;

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  void _onPlatformViewCreated(int id) {
    _channel = MethodChannel('flutter_vap_plugin_$id');
    _channel?.setMethodCallHandler(_handleMethodCall);
    widget.controller.bindChannel(_channel!);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onVideoStart':
        widget.onVideoStart?.call();
        break;
      case 'onVideoFinish':
        widget.onVideoFinish?.call();
        break;
      case 'onVideoStop':
        widget.onVideoStop?.call();
        break;
      case 'onVideoRender':
        final frameIndex = call.arguments['frameIndex'] as int;
        widget.onVideoRender?.call(frameIndex);
        break;
      case 'onFailed':
        final errorType = call.arguments['errorType'] as int;
        final errorMsg = call.arguments['errorMsg'] as String;
        widget.onFailed?.call(errorType, errorMsg);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return AndroidView(
        viewType: "flutter_vap_plugin",
        layoutDirection: TextDirection.ltr,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
        creationParams: <String, dynamic>{'scaleType': widget.scaleType.name},
      );
    } else if (Platform.isIOS) {
      return UiKitView(
        viewType: "flutter_vap_plugin",
        layoutDirection: TextDirection.ltr,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
        creationParams: <String, dynamic>{'scaleType': widget.scaleType.name},
      );
    } else {
      return const Center(child: Text('Unsupported platform'));
    }
  }
}
