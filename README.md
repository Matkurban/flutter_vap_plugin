# flutter_vap_plugin

[中文文档请点击这里 (README.zh.md)](README.zh.md)

A Flutter plugin based on Tencent's VAP, supporting VAP video playback on Android and iOS.

## Features
- Supports local file, asset, and network video sources
- Loop playback support (`repeatCount`, -1 for infinite loop)
- Callbacks for video start, complete, destroy, render frame, failure, and config ready
- Android and iOS support

## Installation
Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_vap_plugin: ^0.0.8
```

## Usage
See the example below:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_vap_plugin/flutter_vap_plugin.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final FlutterVapController vapController = FlutterVapController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
          actions: [
            TextButton(
              onPressed: () {
                vapController.play(
                  path: "https://baimiaoxing.oss-cn-hangzhou.aliyuncs.com/system/test1.mp4",
                  sourceType: VapSourceType.network,
                );
              },
              child: Text("播放1"),
            ),
            TextButton(
              onPressed: () {
                vapController.play(
                  path: "https://baimiaoxing.oss-cn-hangzhou.aliyuncs.com/system/test2.mp4",
                  sourceType: VapSourceType.network,
                );
              },
              child: Text("播放2"),
            ),
          ],
        ),
        body: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: FlutterVapView(
            controller: vapController,
            onVideoStart: () {
              debugPrint('VAP - 视频开始播放');
            },
            onVideoComplete: () {
              debugPrint('VAP - 视频播放完成');
            },
            onVideoDestroy: () {
              debugPrint('VAP - 视频播放器销毁');
            },
            onVideoRender: (frameIndex) {
              debugPrint('VAP - 视频渲染帧: $frameIndex');
            },
            onFailed: (errorType, errorMsg) {
              debugPrint('VAP - 播放失败: [errorType] $errorMsg');
            },
            onVideoConfigReady: () {
              debugPrint('VAP - 视频配置就绪');
            },
          ),
        ),
      ),
    );
  }
}
```

## Parameters
- `path`: VAP video path (local, asset, or network)
- `sourceType`: video source type (file/asset/network)
- Other parameters are callback functions

## Replay

- To play a loop, call the `replay` method of the controller

## Feedback & Support
For other requirements or issues, please submit an issue or contact the author.
