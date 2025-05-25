# flutter_vap_plugin

基于腾讯 VAP 封装的 Flutter 插件，支持在 Android 和 iOS 平台播放 VAP 视频。

## 功能特性
- 支持本地文件、asset、网络视频源
- 支持循环播放（repeatCount，-1 表示无限循环）
- 提供播放开始、完成、销毁、渲染帧、失败、配置就绪等回调
- Android/iOS 平台均支持

## 安装
在 `pubspec.yaml` 添加依赖：

```yaml
dependencies:
  flutter_vap_plugin: ^0.0.1
```

## 使用方法
请参考 example 目录下的示例代码：

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

## 参数说明
- `path`：VAP 视频路径（支持本地、asset、网络）
- `sourceType`：视频源类型（file/asset/network）
- `repeatCount`：循环次数，-1 为无限循环
- 其余为回调函数

## 反馈与支持
如有其他需求或问题，请提交 issue 或联系作者。

