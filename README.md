# flutter_vap_plugin

[中文文档](README.zh.md)

A Flutter plugin based on Tencent's VAP, supporting VAP video playback on Android and iOS.

## Features
- Supports local file, asset, and network video sources
- Loop playback support `repeatCount`
- Callbacks for video start, complete, destroy, render frame, failure, and config ready
- Android and iOS support

## Installation
Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_vap_plugin: ^0.1.1
```

## Usage
See the example below:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_vap_plugin/flutter_vap_plugin.dart';
import 'package:flutter_vap_plugin/vap_scale_type.dart';

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
                vapController.play(path: "assets/videos/test1.mp4", sourceType: VapSourceType.asset, repeatCount: 3);
              },
              child: Text("播放资源1"),
            ),
          ],
        ),
        body: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: FlutterVapView(
            controller: vapController,
            scaleType: VapScaleType.fitXY,
            onVideoStart: () {
              debugPrint('VAP - 视频开始播放');
            },
            onVideoFinish: () {
              debugPrint('VAP - 视频播放完成');
            },
            onVideoStop: () {
              debugPrint('VAP - 视频播放器停止播放');
            },
            onVideoRender: (frameIndex) {
              debugPrint('VAP - 视频渲染帧: $frameIndex');
            },
            onFailed: (errorType, errorMsg) {
              debugPrint('VAP - 播放失败: [$errorType] $errorMsg');
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
- `repeatCount`: number of times to repeat the video (default is 1)
- Other parameters are callback functions

## Replay

- To play a loop, call the `replay` method of the controller

## Feedback & Support
For other requirements or issues, please submit an issue or contact the author.
