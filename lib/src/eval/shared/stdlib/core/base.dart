import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/exception.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'num.dart';

class $null implements $Value {
  const $null();

  @override
  Null get $value => null;

  @override
  Null get $reified => null;

  @override
  int get $runtimeType => RuntimeTypes.nullType;
}

class $Object implements $Instance {
  const $Object();

  @override
  dynamic get $value => null;

  @override
  dynamic get $reified => $value;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case '==':
        return __equals;
    }

    throw UnimplementedError();
  }

  static const $Function __equals = $Function(_equals);

  static $Value? _equals(Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0];
    return $bool(target!.$value == other!.$value);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    throw UnimplementedError();
  }

  @override
  int get $runtimeType => RuntimeTypes.objectType;
}

class $bool implements $Instance {
  $bool(this.$value);

  final $Instance $super = $Object();

  @override
  bool $value;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
    }
    return $super.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {}

  @override
  bool get $reified => $value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is $bool &&
          runtimeType == other.runtimeType &&
          $value == other.$value;

  @override
  int get hashCode => $value.hashCode;

  @override
  String toString() {
    return 'EvalBool{${$value}}';
  }

  @override
  int get $runtimeType => RuntimeTypes.boolType;
}

/*class EvalInvocation implements EvalInstance {
  EvalInvocation.getter(this.positionalArguments);

  final EvalInstance $super = EvalObject();

  final $List? positionalArguments;

  @override
  EvalValue? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'positionalArguments':
        return positionalArguments;
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, EvalValue value) {}

  @override
  dynamic get $value => throw UnimplementedError();

  @override
  dynamic get $reified => throw UnimplementedError();
}*/

class $String implements $Instance {
  const $String(this.$value);

  @override
  final String $value;

  final $Instance $super = const $Object();

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'length':
        return $int($value.length);
      case 'isEmpty':
        return $bool($value.isEmpty);
      case 'isNotEmpty':
        return $bool($value.isNotEmpty);
      case '+':
        return __concat;
      case 'toLowerCase':
        return __toLowerCase;
      case 'toUpperCase':
        return __toUpperCase;
    }

    return $super.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    throw EvalUnknownPropertyException(identifier);
  }

  static const $Function __concat = $Function(_concat);

  static $Value? _concat(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    target as $String;
    final other = args[0] as $String;
    return $String(target.$value + other.$value);
  }

  static const $Function __toLowerCase = $Function(_toLowerCase);

  static $Value? _toLowerCase(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    return $String((target!.$value as String).toLowerCase());
  }

  static const $Function __toUpperCase = $Function(_toUpperCase);

  static $Value? _toUpperCase(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    return $String((target!.$value as String).toUpperCase());
  }

  @override
  String get $reified => $value;

  @override
  int get $runtimeType => RuntimeTypes.stringType;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is $String && runtimeType == other.runtimeType && $value == other.$value;

  @override
  int get hashCode => $value.hashCode;
}
