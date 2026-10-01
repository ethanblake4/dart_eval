import 'package:dart_eval/stdlib/core.dart' show $Map;

/// Native storage whose reads already produce canonical guest values.
///
/// Internal boxing uses this final wrapper so indexed dispatch can trust its
/// inherited Map adapter without bypassing external wrapper overrides.
final class TypedNativeMap<K, V> extends $Map<K, V> {
  TypedNativeMap.wrap(super.$value, {super.runtimeTypeId, super.runtime})
    : super.wrap();
}
