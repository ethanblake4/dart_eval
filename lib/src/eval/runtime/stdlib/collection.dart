import 'package:dart_eval/src/eval/runtime/class.dart';
import 'package:dart_eval/src/eval/runtime/exception.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/runtime/stdlib/base.dart';

class EvalList implements EvalInstance {

  EvalList(this.$value);

  @override
  final List<EvalValue> $value;

  EvalInstance evalSuperclass = EvalObject();

  @override
  EvalValue? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case '[]':
    }
    return evalSuperclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, EvalValue value) {
    throw EvalUnknownPropertyException(identifier);
  }

  @override
  List get $reified => $value.map((e) => e.$reified).toList();
}