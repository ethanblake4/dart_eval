import 'package:dart_eval/stdlib/core.dart' show $List;

/// Native storage whose reads already produce canonical guest values.
///
/// Internal boxing uses this final wrapper so indexed dispatch can trust its
/// inherited List adapter without bypassing external wrapper overrides.
final class TypedNativeList<E> extends $List<E> {
  TypedNativeList.wrap(super.$value, {super.runtimeTypeId, super.runtime})
    : super.wrap();
}
