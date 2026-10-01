import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/stdlib/core.dart' show $List;

/// Native storage whose reads already produce canonical guest values.
///
/// Internal boxing uses this final wrapper so indexed dispatch can trust its
/// inherited List adapter without bypassing external wrapper overrides.
final class TypedNativeList<E> extends $List<E> {
  TypedNativeList.wrap(List<E> value, {int? runtimeTypeId, Runtime? runtime})
    : super.wrap(value, runtimeTypeId: runtimeTypeId, runtime: runtime);
}
