import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/exception.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'num.dart';

/// dart_eval [$Value] representation of [null]
class $null implements $Value {
  const $null();

  @override
  Null get $value => null;

  @override
  Null get $reified => null;

  @override
  int get $runtimeType => RuntimeTypes.nullType;

  @override
  bool operator ==(Object other) => other is $null;

  @override
  int get hashCode => -12121212;
}

/// dart_eval [$Instance] representation of an [Object]
class $Object implements $Instance {
  $Object(this.$value);

  @override
  final Object $value;

  @override
  dynamic get $reified => $value;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case '==':
        return __equals;
      case 'toString':
        return __toString;
    }

    throw UnimplementedError();
  }

  static const $Function __equals = $Function(_equals);

  static $Value? _equals(Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0];
    return $bool(target!.$value == other!.$value);
  }

  static const $Function __toString = $Function(_toString);

  static $Value? _toString(Runtime runtime, $Value? target, List<$Value?> args) {
    return $String(target!.$value.toString());
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    throw UnimplementedError();
  }

  @override
  int get $runtimeType => RuntimeTypes.objectType;
}

/// dart_eval [$Instance] representation of a [bool]
class $bool implements $Instance {
  $bool(this.$value) : _superclass = $Object($value);

  final $Instance _superclass;

  @override
  bool $value;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case '&&':
        return __and;
      case '||':
        return __or;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {}

  static const $Function __and = $Function(_and);

  static $Value? _and(Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0];
    return $bool(target!.$value && other!.$value);
  }

  static const $Function __or = $Function(_or);

  static $Value? _or(Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0];
    return $bool(target!.$value || other!.$value);
  }

  @override
  bool get $reified => $value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is $bool && runtimeType == other.runtimeType && $value == other.$value;

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

/// dart_eval [$Instance] representation of a [String]
class $String implements $Instance {
  $String(this.$value) : _superclass = $Object($value);

  @override
  final String $value;

  final $Instance _superclass;

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
      case 'codeUnitAt':
        return __codeUnitAt;
      case 'compareTo':
        return __compareTo;
      case 'endsWith':
        return __endsWith;
      case 'substring':
        return __substring;
      case 'toLowerCase':
        return __toLowerCase;
      case 'toUpperCase':
        return __toUpperCase;
    }

    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  String toString() {
    return '\$"${$value}"';
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    throw EvalUnknownPropertyException(identifier);
  }

  static const $Function __concat = $Function(_concat);

  static $Value? _concat(final Runtime runtime, final $Value? target, final List<$Value?> args) {
    target as $String;
    final other = args[0] as $String;
    return $String(target.$value + other.$value);
  }

  static const $Function __codeUnitAt = $Function(_codeUnitAt);

  static $Value? _codeUnitAt(final Runtime runtime, final $Value? target, final List<$Value?> args) {
    target as $String;
    final index = args[0] as $int;
    return $int(target.$value.codeUnitAt(index.$value));
  }

  static const $Function __compareTo = $Function(_compareTo);

  static $Value? _compareTo(final Runtime runtime, final $Value? target, final List<$Value?> args) {
    target as $String;
    final other = args[0] as $String;
    return $int(target.$value.compareTo(other.$value));
  }

  static const $Function __endsWith = $Function(_endsWith);

  static $Value? _endsWith(final Runtime runtime, final $Value? target, final List<$Value?> args) {
    target as $String;
    final other = args[0] as $String;
    return $bool(target.$value.endsWith(other.$value));
  }

  static const $Function __substring = $Function(_substring);

  static $Value? _substring(final Runtime runtime, final $Value? target, final List<$Value?> args) {
    target as $String;
    final start = args[0] as $int;
    final end = args.length > 1 ? args[1] as $int : null;
    return $String(target.$value.substring(start.$value, end?.$value));
  }

  static const $Function __toLowerCase = $Function(_toLowerCase);

  static $Value? _toLowerCase(final Runtime runtime, final $Value? target, final List<$Value?> args) {
    return $String((target!.$value as String).toLowerCase());
  }

  static const $Function __toUpperCase = $Function(_toUpperCase);

  static $Value? _toUpperCase(final Runtime runtime, final $Value? target, final List<$Value?> args) {
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
