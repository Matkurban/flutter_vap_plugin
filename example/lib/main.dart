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
                  path: "assets/videos/test1.mp4",
                  sourceType: VapSourceType.asset,
                );
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
