class BindgenContext {
  final String uri;
  final Set<String> imports = {};
  final Set<String> knownTypes = {};
  final Set<String> unknownTypes = {};
  final bool wrap;
  final bool all;
  final Map<String, String> libOverrides = {};

  BindgenContext(this.uri, {required this.wrap, required this.all});
}
