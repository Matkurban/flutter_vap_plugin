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
              vapController.replay();
            },
            onVideoDestroy: () {
              debugPrint('VAP - 视频播放器销毁');
            },
            onVideoRender: (frameIndex) {
              debugPrint('VAP - 视频渲染帧: $frameIndex');
            },
            onFailed: (errorType, errorMsg) {
              debugPrint('VAP - 播放失败: [$errorType] $errorMsg');
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
