import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vap_plugin/flutter_vap_type.dart';

typedef VapErrorCallback = void Function(int errorType, String errorMsg);
typedef VapFrameCallback = void Function(int frameIndex);
typedef VapCallback = void Function();

class FlutterVapPlugin extends StatefulWidget {
  const FlutterVapPlugin({
    super.key,
    required this.path,
    required this.sourceType,
    this.repeatCount = 1,  // 添加循环次数参数，-1表示无限循环
    this.onVideoStart,
    this.onVideoComplete,
    this.onVideoDestroy,
    this.onVideoRender,
    this.onFailed,
    this.onVideoConfigReady,
  });

  final String path;
  final FlutterVapType sourceType;
  final int repeatCount;  // 添加循环次数属性
  final VapCallback? onVideoStart;
  final VapCallback? onVideoComplete;
  final VapCallback? onVideoDestroy;
  final VapFrameCallback? onVideoRender;
  final VapErrorCallback? onFailed;
  final VapCallback? onVideoConfigReady;

  @override
  State<FlutterVapPlugin> createState() => _FlutterVapPluginState();
}

class _FlutterVapPluginState extends State<FlutterVapPlugin> {
  MethodChannel? _channel;

  Future<void> stopPlay() async {
    await _channel?.invokeMethod('stop');
  }

  void _onPlatformViewCreated(int id) {
    _channel = MethodChannel('flutter_vap_plugin_$id');
    _channel?.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onVideoStart':
        widget.onVideoStart?.call();
        break;
      case 'onVideoComplete':
        widget.onVideoComplete?.call();
        break;
      case 'onVideoDestroy':
        widget.onVideoDestroy?.call();
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
      case 'onVideoConfigReady':
        widget.onVideoConfigReady?.call();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final params = {
      "path": widget.path,
      "sourceType": widget.sourceType.name,
      "repeatCount": widget.repeatCount,  // 添加循环次数参数
    };

    if (Platform.isAndroid) {
      return AndroidView(
        viewType: "flutter_vap_plugin",
        layoutDirection: TextDirection.ltr,
        creationParams: params,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    } else if (Platform.isIOS) {
      return UiKitView(
        viewType: "flutter_vap_plugin",
        layoutDirection: TextDirection.ltr,
        creationParams: params,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    } else {
      return const Center(child: Text('Unsupported platform'));
    }
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }
}
