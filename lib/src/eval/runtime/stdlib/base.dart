import 'package:dart_eval/src/eval/runtime/class.dart';
import 'package:dart_eval/src/eval/runtime/function.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/runtime/stdlib/collection.dart';

class EvalNull implements EvalValue {
  const EvalNull();

  @override
  Null get $value => null;

  @override
  Null get $reified => null;
}

class EvalObject implements EvalInstance {
  const EvalObject();

  @override
  dynamic get $value => null;

  @override
  dynamic get $reified => $value;

  @override
  EvalValue? $getProperty(Runtime runtime, String identifier) {
    switch(identifier) {
      case '==':
        return __equals;
    }

    throw UnimplementedError();
  }

  static const EvalFunctionImpl __equals = EvalFunctionImpl(_equals);
  static EvalValue? _equals(Runtime runtime, EvalValue? target, List<EvalValue?> args) {
    final other = args[0];
    return EvalBool(target!.$value == other!.$value);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, EvalValue value) {
    throw UnimplementedError();
  }
}

class EvalBool implements EvalInstance {
  EvalBool(this.$value);

  final EvalInstance $super = EvalObject();

  @override
  bool $value;

  @override
  EvalValue? $getProperty(Runtime runtime, String identifier) {
    switch(identifier) {}
    return $super.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, EvalValue value) {

  }

  @override
  bool get $reified => $value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is EvalBool && runtimeType == other.runtimeType && $value == other.$value;

  @override
  int get hashCode => $value.hashCode;

  @override
  String toString() {
    return 'EvalBool{${$value}}';
  }
}

class EvalInvocation implements EvalInstance {

  EvalInvocation.getter(this.positionalArguments);

  final EvalInstance $super = EvalObject();

  final EvalList? positionalArguments;

  @override
  EvalValue? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'positionalArguments':
        return positionalArguments;
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, EvalValue value) {

  }

  @override
  dynamic get $value => throw UnimplementedError();

  @override
  dynamic get $reified => throw UnimplementedError();
}