import 'package:dart_eval/src/eval/runtime/record.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

/// Field layouts belong to the program and are shared by all its records.
abstract final class TypedRecords {
  static final _layouts =
      Expando<Map<int, (Map<String, int>, int, bool)>>();

  @pragma('vm:never-inline')
  static $Record create(
    Runtime runtime,
    Object? fields,
    int index, {
    int? actualOwnerType,
    List<int> callableTypeArguments = const [],
  }) {
    final layouts = _layouts[runtime] ??= {};
    var layout = layouts[index];
    if (layout == null) {
      final descriptor = runtime.typedConstant(index) as List;
      // Field names are stored as an ordered list (index i is the name of
      // field i); the map is rebuilt here for property lookups.
      final names =
          runtime.typedConstant(descriptor[0] as int) as List<Object?>;
      layout = (
        Map<String, int>.unmodifiable({
          for (var i = 0; i < names.length; i++) names[i] as String: i,
        }),
        descriptor[1] as int,
        // A third element marks the record's field types as fixed — the
        // declared record type is already the runtime type.
        descriptor.length > 2 && descriptor[2] == 0,
      );
      layouts[index] = layout;
    }
    final resolvedTemplate = runtime.resolveTypedEnvironmentType(
      layout.$2,
      actualOwnerType: actualOwnerType,
      callableTypeArguments: callableTypeArguments,
    );
    final fieldList = fields as List<Object?>;
    return $Record(
      fieldList,
      layout.$1,
      layout.$3
          ? resolvedTemplate
          : runtime.reifyRecordType(resolvedTemplate, fieldList, layout.$1),
      runtime,
    );
  }

  @pragma('vm:never-inline')
  static void assertType(Runtime runtime, Object? value, int typeId) {
    if (!runtime.isTypedValueType(value, typeId)) throw TypeError();
  }
}
