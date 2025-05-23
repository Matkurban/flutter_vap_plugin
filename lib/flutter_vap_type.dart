enum FlutterVapType {
  file('file'),
  asset('asset'),
  network('network');

  final String name;

  const FlutterVapType(this.name);
}
