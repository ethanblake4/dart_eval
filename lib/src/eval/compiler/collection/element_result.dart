import '../type.dart';

/// Types contributed by a collection element, separate from its evaluation.
final class CollectionElementResult {
  const CollectionElementResult(this.types, {this.completesNormally = true});

  final List<TypeRef> types;
  final bool completesNormally;
}
