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
            XFile? videoFile = await imagePicker.pickVideo(
              source: ImageSource.gallery,
            );
            if (videoFile != null) {
              await vapController.stop();
              await vapController.play(
                path: videoFile.path,
                sourceType: VapSourceType.file,
              );
            }
          },
          child: Icon(Icons.file_copy),
        ),
      ),
    );
  }
}
