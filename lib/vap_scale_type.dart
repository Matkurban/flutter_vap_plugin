/// Enum representing different video scaling types for VapPlayer.
/// 视频缩放类型的枚举，用于 VapPlayer。
enum VapScaleType {
  /// Scale the video to fit the view's dimensions, ignoring aspect ratio.
  /// 缩放视频以适合视图的尺寸，忽略纵横比。
  fitXY("FIT_XY"),

  /// Scale the video to fit the view's dimensions while maintaining aspect ratio.
  /// 缩放视频以适合视图的尺寸，同时保持纵横比。
  fitCenter("FIT_CENTER"),

  /// Scale the video to fill the view's dimensions, cropping if necessary.
  /// 缩放视频以填充视图的尺寸，必要时裁剪。
  centerCrop("CENTER_CROP");

  final String name;

  const VapScaleType(this.name);
}
