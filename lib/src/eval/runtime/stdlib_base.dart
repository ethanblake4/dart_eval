import 'package:dart_eval/src/eval/runtime/exception.dart';
import 'package:dart_eval/src/eval/runtime/function.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

import 'class.dart';

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
  EvalInstance? get evalSuperclass => null;

  @override
  EvalValue? $getProperty(Runtime runtime, String identifier) {
    throw UnimplementedError();
  }

  @override
  void $setProperty(Runtime runtime, String identifier, EvalValue value) {
    throw UnimplementedError();
  }
}

class EvalBool implements EvalInstance {
  EvalBool(this.$value);

  @override
  bool $value;

  @override
  EvalValue? $getProperty(Runtime runtime, String identifier) {
    switch(identifier) {}
    return evalSuperclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, EvalValue value) {

  }

  @override
  EvalInstance evalSuperclass = EvalObject();

  @override
  bool get $reified => $value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is EvalNum && runtimeType == other.runtimeType && $value == other.$value;

  @override
  int get hashCode => $value.hashCode;

  @override
  String toString() {
    return 'EvalBool{${$value}}';
  }
}

class EvalNum<T extends num> implements EvalInstance {
  EvalNum(this.$value);

  @override
  T $value;

  @override
  EvalValue? $getProperty(Runtime runtime, String identifier) {
    switch(identifier) {
      case '+':
        return __plus;
      case '-':
        return __minus;
      case '<':
        return __lt;
    }
    return evalSuperclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, EvalValue value) {
    throw UnimplementedError();
  }

  @override
  EvalInstance evalSuperclass = EvalObject();

  @override
  T get $reified => $value;

  static const EvalFunctionImpl __plus = EvalFunctionImpl(_plus);
  static EvalValue? _plus(Runtime runtime, EvalValue? target, List<EvalValue?> args) {
    final other = args[0];
    final _evalResult = target!.$value + other!.$value;

    if (_evalResult is int) {
      return EvalInt(_evalResult);
    }
    if (_evalResult is double) {
      return EvalDouble(_evalResult);
    }

    throw UnimplementedError();
  }

  static const EvalFunctionImpl __minus = EvalFunctionImpl(_minus);
  static EvalValue? _minus(Runtime runtime, EvalValue? target, List<EvalValue?> args) {
    final other = args[0];
    final _evalResult = target!.$value - other!.$value;

    if (_evalResult is int) {
      return EvalInt(_evalResult);
    }
    if (_evalResult is double) {
      return EvalDouble(_evalResult);
    }

    throw UnimplementedError();
  }

  static const EvalFunctionImpl __lt = EvalFunctionImpl(_lt);
  static EvalValue? _lt(Runtime runtime, EvalValue? target, List<EvalValue?> args) {
    final other = args[0];
    final _evalResult = target!.$value < other!.$value;

    if (_evalResult is bool) {
      return EvalBool(_evalResult);
    }

    throw UnimplementedError();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is EvalNum && runtimeType == other.runtimeType && $value == other.$value;

  @override
  int get hashCode => $value.hashCode;
}

class EvalInt extends EvalNum<int> {

  EvalInt(int evalValue) : super(evalValue);

  @override
  EvalValue? $getProperty(Runtime runtime, String identifier) {
    return super.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, EvalValue value) {
    return super.$setProperty(runtime, identifier, value);
  }

  @override
  EvalInstance get evalSuperclass => throw UnimplementedError();

  @override
  int get $reified => $value;

  @override
  String toString() {
    return $value.toString();
  }
}

class EvalDouble extends EvalNum<double> {

  EvalDouble(double evalValue) : super(evalValue);

  @override
  EvalValue? $getProperty(Runtime runtime, String identifier) {
    return super.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, EvalValue value) {
    return super.$setProperty(runtime, identifier, value);
  }

  @override
  EvalInstance get evalSuperclass => throw UnimplementedError();

  @override
  double get $reified => $value;
}

class EvalInvocation implements EvalInstance {

  EvalInvocation.getter(this.positionalArguments);

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


class EvalList implements EvalInstance {

  EvalList(this.$value);

  @override
  final List<EvalValue> $value;

  @override
  EvalInstance evalSuperclass = EvalObject();

  @override
  EvalValue? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case '[]':
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, EvalValue value) {
    throw EvalUnknownPropertyException(identifier);
  }

  @override
  List get $reified => $value.map((e) => e.$reified).toList();
}