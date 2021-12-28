import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';

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
      case '>':
        return __gt;
      case '<=':
        return __lteq;
      case '>=':
        return __gteq;
    }
    return $super.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, EvalValue value) {
    throw UnimplementedError();
  }

  final EvalInstance $super = EvalObject();

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

  static const EvalFunctionImpl __gt = EvalFunctionImpl(_gt);
  static EvalValue? _gt(Runtime runtime, EvalValue? target, List<EvalValue?> args) {
    final other = args[0];
    final _evalResult = target!.$value > other!.$value;

    if (_evalResult is bool) {
      return EvalBool(_evalResult);
    }

    throw UnimplementedError();
  }

  static const EvalFunctionImpl __lteq = EvalFunctionImpl(_lteq);
  static EvalValue? _lteq(Runtime runtime, EvalValue? target, List<EvalValue?> args) {
    final other = args[0];
    final _evalResult = target!.$value <= other!.$value;

    if (_evalResult is bool) {
      return EvalBool(_evalResult);
    }

    throw UnimplementedError();
  }

  static const EvalFunctionImpl __gteq = EvalFunctionImpl(_gteq);
  static EvalValue? _gteq(Runtime runtime, EvalValue? target, List<EvalValue?> args) {
    final other = args[0];
    final _evalResult = target!.$value >= other!.$value;

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
  double get $reified => $value;
}