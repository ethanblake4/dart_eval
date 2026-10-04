import 'dart:typed_data';

import 'package:dart_eval/dart_eval_bridge.dart' show $Instance;
import 'package:dart_eval/stdlib/core.dart' show $List;
import 'package:dart_eval/stdlib/typed_data.dart';

/// Native typed lists have concrete SDK classes even when an API declares List.
/// Keep their original backing and dispatch instead of erasing that class in a
/// canonical List view.
$Instance? wrapNativeTypedList(Object? value) => switch (value) {
  Uint8List() => $Uint8List.wrap(value),
  Uint8ClampedList() => $Uint8ClampedList.wrap(value),
  Int8List() => $Int8List.wrap(value),
  Uint16List() => $Uint16List.wrap(value),
  Int16List() => $Int16List.wrap(value),
  Uint32List() => $Uint32List.wrap(value),
  Int32List() => $Int32List.wrap(value),
  Uint64List() => $Uint64List.wrap(value),
  Int64List() => $Int64List.wrap(value),
  Float32List() => $Float32List.wrap(value),
  Float64List() => $Float64List.wrap(value),
  _ => null,
};

/// Native storage whose reads already produce canonical guest values.
///
/// Internal boxing uses this final wrapper so indexed dispatch can trust its
/// inherited List adapter without bypassing external wrapper overrides.
final class TypedNativeList<E> extends $List<E> {
  TypedNativeList.wrap(
    super.$value, {
    super.runtimeTypeId,
    super.runtime,
    super.isolateGrowable,
    super.isolateReadOnly,
  }) : super.wrap();
}
