/// Enum for VAP video source type
/// VAP 视频源类型枚举
enum VapSourceType {
  /// Local file source
  /// 本地文件
  file('file'),

  /// Asset source
  /// 资源文件
  asset('asset');

  /// Source type name string
  /// 源类型名称字符串
  final String type;

  const VapSourceType(this.type);
}
