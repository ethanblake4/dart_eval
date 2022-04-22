import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

class $num<T extends num> implements $Instance {
  $num(this.$value);

  @override
  T $value;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case '+':
        return __plus;
      case '-':
        return __minus;
      case '*':
        return __mul;
      case '/':
        return __div;
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
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    throw UnimplementedError();
  }

  final $Instance $super = $Object();

  @override
  T get $reified => $value;

  static const $Function __plus = $Function(_plus);
  static $Value? _plus(Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0];
    final _evalResult = target!.$value + other!.$value;

    if (_evalResult is int) {
      return $int(_evalResult);
    }

    if (_evalResult is double) {
      return $double(_evalResult);
    }

    throw UnimplementedError();
  }

  static const $Function __minus = $Function(_minus);
  static $Value? _minus(Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0];
    final _evalResult = target!.$value - other!.$value;

    if (_evalResult is int) {
      return $int(_evalResult);
    }

    if (_evalResult is double) {
      return $double(_evalResult);
    }

    throw UnimplementedError();
  }

  static const $Function __mul = $Function(_mul);
  static $Value? _mul(Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0];
    final _evalResult = target!.$value * other!.$value;

    if (_evalResult is int) {
      return $int(_evalResult);
    }

    if (_evalResult is double) {
      return $double(_evalResult);
    }

    throw UnimplementedError();
  }

  static const $Function __div = $Function(_div);
  static $Value? _div(Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0];
    final _evalResult = target!.$value / other!.$value;

    if (_evalResult is double) {
      return $double(_evalResult);
    }

    throw UnimplementedError();
  }

  static const $Function __lt = $Function(_lt);
  static $Value? _lt(Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0];
    final _evalResult = target!.$value < other!.$value;

    if (_evalResult is bool) {
      return $bool(_evalResult);
    }

    throw UnimplementedError();
  }

  static const $Function __gt = $Function(_gt);
  static $Value? _gt(Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0];
    final _evalResult = target!.$value > other!.$value;

    if (_evalResult is bool) {
      return $bool(_evalResult);
    }

    throw UnimplementedError();
  }

  static const $Function __lteq = $Function(_lteq);
  static $Value? _lteq(Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0];
    final _evalResult = target!.$value <= other!.$value;

    if (_evalResult is bool) {
      return $bool(_evalResult);
    }

    throw UnimplementedError();
  }

  static const $Function __gteq = $Function(_gteq);
  static $Value? _gteq(Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0];
    final _evalResult = target!.$value >= other!.$value;

    if (_evalResult is bool) {
      return $bool(_evalResult);
    }

    throw UnimplementedError();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is $num &&
          runtimeType == other.runtimeType &&
          $value == other.$value;

  @override
  int get hashCode => $value.hashCode;

  @override
  int get $runtimeType => RuntimeTypes.numType;
}

class $int extends $num<int> {
  $int(int evalValue) : super(evalValue);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    return super.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return super.$setProperty(runtime, identifier, value);
  }

  @override
  int get $reified => $value;

  @override
  String toString() {
    return $value.toString();
  }

  @override
  int get $runtimeType => RuntimeTypes.intType;
}

class $double extends $num<double> {
  $double(double evalValue) : super(evalValue);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    return super.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return super.$setProperty(runtime, identifier, value);
  }

  @override
  double get $reified => $value;

  @override
  int get $runtimeType => RuntimeTypes.doubleType;
}
