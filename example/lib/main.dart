import 'package:flutter/material.dart';
import 'package:flutter_vap_plugin/flutter_vap_controller.dart';
import 'package:flutter_vap_plugin/flutter_vap_plugin.dart';
import 'package:flutter_vap_plugin/flutter_vap_type.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late FlutterVapController vapController;

  late Icon statusIcon = Icon(Icons.play_arrow);

  @override
  void initState() {
    super.initState();
    vapController = FlutterVapController();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
          actions: [
            IconButton(
              onPressed: () {
                if (statusIcon.icon == Icons.play_arrow) {
                  vapController.play();
                } else {
                  vapController.stop();
                }
              },
              icon: statusIcon,
            ),
          ],
        ),
        body: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: FlutterVapPlugin(
            repeatCount: 3,
            controller: vapController,
            path:
                'https://baimiaoxing.oss-cn-hangzhou.aliyuncs.com/system/test1.mp4',
            sourceType: FlutterVapType.network,
            onVideoStart: () {
              debugPrint('VAP - 视频开始播放');
              setState(() {
                statusIcon = const Icon(Icons.pause);
              });
            },
            onVideoComplete: () {
              debugPrint('VAP - 视频播放完成');
              setState(() {
                statusIcon = const Icon(Icons.play_arrow);
              });
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
