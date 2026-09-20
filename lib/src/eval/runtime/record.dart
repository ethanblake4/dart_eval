import 'package:dart_eval/src/eval/runtime/class.dart';
import 'package:dart_eval/src/eval/runtime/exception.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

class $Record implements $Instance {
  final List<Object?> fields;
  final Map<String, int> mapping;
  final int typeId;
  final Runtime runtime;

  const $Record(this.fields, this.mapping, this.typeId, this.runtime);

  @override
  int $getRuntimeType(Runtime runtime) =>
      runtime.importRuntimeType(this.runtime, typeId);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    final index = mapping[identifier];
    if (index != null) {
      final value = fields[index];
      if (value != null && value is! $Value) {
        throw InvalidUnboxedValueException(
          'Record field "$identifier" is not a \$Value',
          value,
        );
      }
      return value as $Value?;
    }
    throw EvalUnknownPropertyException(identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    throw EvalUnknownPropertyException(identifier);
  }

  @override
  $Record get $value => this;

  @override
  $Record get $reified => this;
}
