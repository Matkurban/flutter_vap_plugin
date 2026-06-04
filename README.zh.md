# flutter_vap_plugin

基于腾讯 VAP 封装的 Flutter 插件，支持在 Android 和 iOS 平台播放 VAP 视频。

## 环境要求

- Flutter **3.44.0** 及以上（Dart **3.12** 及以上）
- iOS：QGVAPlayer 在 SPM 解析时会从 GitHub [Tencent/vap](https://github.com/Tencent/vap)（标签 `iOS1.0.19`）自动拉取；CocoaPods 路径则由 Pod 从同一仓库下载。
- iOS 同时支持 CocoaPods 与 Swift Package Manager，可通过以下命令启用 SPM：
  ```bash
  flutter config --enable-swift-package-manager
  ```

## 功能特性
- 支持本地文件、asset、网络视频源
- 支持循环播放repeatCount
- 提供播放开始、完成、销毁、渲染帧、失败、配置就绪等回调
- Android/iOS 平台均支持

## 安装
在 `pubspec.yaml` 添加依赖：

```yaml
dependencies:
  flutter_vap_plugin: '^lastVersion'
```

## 使用方法
请参考 example 目录下的示例代码：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_vap_plugin/flutter_vap_plugin.dart';
import 'package:image_picker/image_picker.dart';

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
              onPressed: () async {
                await vapController.stop();
                vapController.play(
                  path: "assets/videos/video1.mp4",
                  sourceType: VapSourceType.asset,
                  repeatCount: 1,
                );
              },
              child: Text("1"),
            ),
            TextButton(
              onPressed: () async {
                await vapController.stop();
                vapController.play(
                  path: "assets/videos/video2.mp4",
                  sourceType: VapSourceType.asset,
                  repeatCount: 1,
                );
              },
              child: Text("2"),
            ),
            TextButton(
              onPressed: () async {
                await vapController.stop();
                vapController.play(
                  path: "assets/videos/video3.mp4",
                  sourceType: VapSourceType.asset,
                  repeatCount: 1,
                );
              },
              child: Text("3"),
            ),
          ],
        ),
        body: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: FlutterVapView(
            controller: vapController,
            scaleType: VapScaleType.fitXY,
            onCreateView: () {
              // 现在可以在这里播放
            },
            onVideoStart: () {
              debugPrint('VAP - 视频开始播放');
            },
            onVideoFinish: () {
              debugPrint('VAP - 视频播放完成');
            },
            onVideoDestroy: () {
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
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            ImagePicker imagePicker = ImagePicker();
            XFile? videoFile = await imagePicker.pickVideo(source: ImageSource.gallery);
            if (videoFile != null) {
              await vapController.stop();
              await vapController.play(path: videoFile.path, sourceType: VapSourceType.file);
            }
          },
          child: Icon(Icons.file_copy),
        ),
      ),
    );
  }
}

```

## 参数说明
- `path`：VAP 视频路径（支持本地、asset、）
- `sourceType`：视频源类型（file/asset）
- `repeatCount`：循环播放次数（默认为 1）
- 其余为回调函数

## 重播

- 使用 `vapController.repaly()` 方法重新播放视频

## 反馈与支持
如有其他需求或问题，请提交 issue 或联系作者。

