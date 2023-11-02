class BindgenContext {
  final String uri;
  final Set<String> imports = {};
  final bool wrap;
  final bool all;

  BindgenContext(this.uri, {required this.wrap, required this.all});
}
