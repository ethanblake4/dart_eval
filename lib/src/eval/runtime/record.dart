import 'package:dart_eval/src/eval/runtime/class.dart';
import 'package:dart_eval/src/eval/runtime/exception.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

class $Record implements $Instance {
  final List<Object?> fields;
  final Map<String, int> mapping;
  final int typeId;

  const $Record(this.fields, this.mapping, this.typeId);

  @override
  int $getRuntimeType(Runtime runtime) => typeId;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    final index = mapping[identifier];
    if (index != null) {
      final value = fields[index];
      if (value is! $Value) {
        throw InvalidUnboxedValueException(
            'Record field "$identifier" is not a \$Value');
      }
      return value;
    }
    throw EvalUnknownPropertyException(identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    throw EvalUnknownPropertyException(identifier);
  }

  @override
  $Value? get $value => null;

  @override
  $Value? get $reified => null;
}
