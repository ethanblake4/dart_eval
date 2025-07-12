class BindgenContext {
  final String uri;
  final Set<String> imports = {};
  final Set<String> knownTypes = {};
  final Set<String> unknownTypes = {};
  final bool all;
  final Map<String, String> libOverrides = {};
  bool implicitSupers = false;

  BindgenContext(this.uri, {required this.all});
}
