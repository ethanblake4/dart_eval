class EvalGenericParam {
  EvalGenericParam(this.name, {this.extensionOf});

  final String name;
  final String? extensionOf;
}

class EvalGenericsList {
  const EvalGenericsList(this.generics);
  final List<EvalGenericParam> generics;

  static const EvalGenericsList empty = EvalGenericsList([]);
}