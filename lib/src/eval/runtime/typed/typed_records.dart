import 'package:dart_eval/src/eval/runtime/record.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

/// Field layouts belong to the program and are shared by all its records.
abstract final class TypedRecords {
  static final _layouts = Expando<Map<int, (Map<String, int>, int)>>();

  @pragma('vm:never-inline')
  static $Record create(Runtime runtime, Object? fields, int index) {
    final layouts = _layouts[runtime] ??= {};
    var layout = layouts[index];
    if (layout == null) {
      final descriptor = runtime.typedConstant(index) as List;
      layout = (
        Map<String, int>.unmodifiable(
          runtime.typedConstant(descriptor[0] as int) as Map,
        ),
        descriptor[1] as int,
      );
      layouts[index] = layout;
    }
    return $Record(fields as List<Object?>, layout.$1, layout.$2);
  }

  @pragma('vm:never-inline')
  static void assertType(Runtime runtime, Object? value, int typeId) {
    if (!runtime.isTypedValueType(value, typeId)) throw TypeError();
  }
}
