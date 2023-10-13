import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/exception.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/collection.dart';
import 'num.dart';

/// dart_eval [$Value] representation of [null]
class $null implements $Value {
  const $null();

  @override
  Null get $value => null;

  @override
  Null get $reified => null;

  @override
  int $getRuntimeType(Runtime runtime) => RuntimeTypes.nullType;

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
      case '!=':
        return __not_equals;
      case 'toString':
        return __toString;
      case 'hashCode':
        return __hashCode;
    }

    throw UnimplementedError();
  }

  static const $Function __equals = $Function(_equals);

  static $Value? _equals(Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0];
    return $bool(target!.$value == other!.$value);
  }

  static const $Function __not_equals = $Function(_not_equals);

  static $Value? _not_equals(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0];
    return $bool(target!.$value != other!.$value);
  }

  static const $Function __toString = $Function(_toString);

  static $Value? _toString(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $String(target!.$value.toString());
  }

  static const $Function __hashCode = $Function(_hashCode);

  static $Value? _hashCode(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $int(target!.$value.hashCode);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    throw UnimplementedError();
  }

  @override
  int $getRuntimeType(Runtime runtime) => RuntimeTypes.objectType;
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
      case '!':
        return __not;
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

  static const $Function __not = $Function(_not);

  static $Value? _not(Runtime runtime, $Value? target, List<$Value?> args) {
    return $bool(!target!.$value);
  }

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
  int $getRuntimeType(Runtime runtime) => RuntimeTypes.boolType;
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
      case 'contains':
        return __contains;
      case 'endsWith':
        return __endsWith;
      case 'indexOf':
        return __indexOf;
      case 'lastIndexOf':
        return __lastIndexOf;
      case 'padLeft':
        return __padLeft;
      case 'padRight':
        return __padRight;
      case 'replaceAll':
        return __replaceAll;
      case 'replaceFirst':
        return __replaceFirst;
      case 'replaceRange':
        return __replaceRange;
      case 'startsWith':
        return __startsWith;
      case 'split':
        return __split;
      case 'substring':
        return __substring;
      case 'toLowerCase':
        return __toLowerCase;
      case 'toUpperCase':
        return __toUpperCase;
      case 'trimLeft':
        return __trimLeft;
      case 'trimRight':
        return __trimRight;
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

  static $Value? _concat(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    target as $String;
    final other = args[0] as $String;
    return $String(target.$value + other.$value);
  }

  static const $Function __codeUnitAt = $Function(_codeUnitAt);

  static $Value? _codeUnitAt(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    target as $String;
    final index = args[0] as $int;
    return $int(target.$value.codeUnitAt(index.$value));
  }

  static const $Function __compareTo = $Function(_compareTo);

  static $Value? _compareTo(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    target as $String;
    final other = args[0] as $String;
    return $int(target.$value.compareTo(other.$value));
  }

  static const $Function __contains = $Function(_contains);

  static $Value? _contains(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    target as $String;
    final other = args[0] as $String;
    return $bool(target.$value.contains(other.$value));
  }

  static const $Function __endsWith = $Function(_endsWith);

  static $Value? _endsWith(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    target as $String;
    final other = args[0] as $String;
    return $bool(target.$value.endsWith(other.$value));
  }

  static const $Function __indexOf = $Function(_indexOf);

  static $Value? _indexOf(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    target as $String;
    final other = args[0] as $String;
    final start = args.length > 1 ? args[1] as $int : null;
    if (start != null) {
      return $int(target.$value.indexOf(other.$value, start.$value));
    } else {
      return $int(target.$value.indexOf(other.$value));
    }
  }

  static const $Function __lastIndexOf = $Function(_lastIndexOf);

  static $Value? _lastIndexOf(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    target as $String;
    final other = args[0] as $String;
    final start = args.length > 1 ? args[1] as $int : null;
    if (start != null) {
      return $int(target.$value.lastIndexOf(other.$value, start.$value));
    } else {
      return $int(target.$value.lastIndexOf(other.$value));
    }
  }

  static const $Function __padLeft = $Function(_padLeft);

  static $Value? _padLeft(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    target as $String;
    final width = args[0] as $int;
    final padding = args.length > 1 ? args[1] as $String : null;
    if (padding != null) {
      return $String(target.$value.padLeft(width.$value, padding.$value));
    } else {
      return $String(target.$value.padLeft(width.$value));
    }
  }

  static const $Function __padRight = $Function(_padRight);

  static $Value? _padRight(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    target as $String;
    final width = args[0] as $int;
    final padding = args.length > 1 ? args[1] as $String : null;
    if (padding != null) {
      return $String(target.$value.padRight(width.$value, padding.$value));
    } else {
      return $String(target.$value.padRight(width.$value));
    }
  }

  static const $Function __replaceAll = $Function(_replaceAll);

  static $Value? _replaceAll(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    target as $String;
    final from = args[0] as $String;
    final replace = args[1] as $String;
    return $String(target.$value.replaceAll(from.$value, replace.$value));
  }

  static const $Function __replaceFirst = $Function(_replaceFirst);

  static $Value? _replaceFirst(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    target as $String;
    final from = args[0] as $String;
    final to = args[1] as $String;
    final startIndex = args.length > 2 ? args[2] as $int : null;
    if (startIndex != null) {
      return $String(target.$value
          .replaceFirst(from.$value, to.$value, startIndex.$value));
    } else {
      return $String(target.$value.replaceFirst(from.$value, to.$value));
    }
  }

  static const $Function __replaceRange = $Function(_replaceRange);

  static $Value? _replaceRange(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    target as $String;
    final start = args[0] as $int;
    final end = args[1] is $int ? args[1] as $int : $null();
    final replacement = args[2] as $String;
    return $String(target.$value
        .replaceRange(start.$value, end.$value, replacement.$value));
  }

  static const $Function __startsWith = $Function(_startsWith);

  static $Value? _startsWith(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    target as $String;
    final pattern = args[0] as $String;
    final index = args.length > 1 ? args[1] as $int : null;
    if (index != null) {
      return $bool(target.$value.startsWith(pattern.$value, index.$value));
    } else {
      return $bool(target.$value.startsWith(pattern.$value));
    }
  }

  static const $Function __split = $Function(_split);

  static $Value? _split(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    target as $String;
    final pattern = args[0] as $String;
    return $List.wrap(target.$value.split(pattern.$value));
  }

  static const $Function __substring = $Function(_substring);

  static $Value? _substring(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    target as $String;
    final start = args[0] as $int;
    final end = args.length > 1 ? args[1] as $int : null;
    return $String(target.$value.substring(start.$value, end?.$value));
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

  static const $Function __trimLeft = $Function(_trimLeft);

  static $Value? _trimLeft(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    return $String((target!.$value as String).trimLeft());
  }

  static const $Function __trimRight = $Function(_trimRight);

  static $Value? _trimRight(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    return $String((target!.$value as String).trimRight());
  }

  @override
  String get $reified => $value;

  @override
  int $getRuntimeType(Runtime runtime) => RuntimeTypes.stringType;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is $String &&
          runtimeType == other.runtimeType &&
          $value == other.$value;

  @override
  int get hashCode => $value.hashCode;
}
