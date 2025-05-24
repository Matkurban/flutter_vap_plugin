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
  flutter_vap_plugin: ^0.0.1
```

## Usage
See the example in the `example` directory:

```dart
FlutterVapPlugin(
  path: 'https://yourdomain.com/video.vap',
  sourceType: FlutterVapType.network,
  repeatCount: 1, // -1 for infinite loop
  onVideoStart: () { /* ... */ },
  onVideoComplete: () { /* ... */ },
  onVideoDestroy: () { /* ... */ },
  onVideoRender: (frameIndex) { /* ... */ },
  onFailed: (errorType, errorMsg) { /* ... */ },
  onVideoConfigReady: () { /* ... */ },
)
```

## Parameters
- `path`: VAP video path (local, asset, or network)
- `sourceType`: video source type (file/asset/network)
- `repeatCount`: loop count, -1 for infinite
- Other parameters are callback functions

## Feedback & Support
For other requirements or issues, please submit an issue or contact the author.
