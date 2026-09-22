import 'package:dart_eval/src/eval/runtime/class.dart';
import 'package:dart_eval/src/eval/runtime/exception.dart';
import 'package:dart_eval/src/eval/runtime/function.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/base.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/num.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/type.dart';

class $Record implements $Instance {
  final List<Object?> fields;
  final Map<String, int> mapping;
  final int typeId;
  final Runtime runtime;

  const $Record(this.fields, this.mapping, this.typeId, this.runtime);

  @override
  int $getRuntimeType(Runtime runtime) =>
      runtime.importRuntimeType(this.runtime, typeId);

  /// Whether [value] is a $Record of the same shape whose fields are
  /// pairwise equal under each field's own `==`.
  bool $structurallyEquals(Object? other) {
    if (identical(this, other)) return true;
    if (other is! $Record) return false;
    if (fields.length != other.fields.length) return false;
    if (mapping.length != other.mapping.length) return false;
    for (final entry in mapping.entries) {
      final otherIndex = other.mapping[entry.key];
      if (otherIndex == null) return false;
      if (!_fieldsEqual(fields[entry.value], other.fields[otherIndex])) {
        return false;
      }
    }
    return true;
  }

  bool _fieldsEqual(Object? a, Object? b) {
    // Fields compare by their own `==` — an `identical` shortcut would be
    // wrong here since a user `==` may return false for identical values.
    if (a == null || b == null) return a == b;
    if (a is! $Instance || b is! $Instance) return a == b;
    if (a.$getProperty(runtime, '==') case final EvalCallable callable) {
      return (callable.call(runtime, a, b, null, 1) as $bool?)!.$value;
    }
    return a == b;
  }

  /// Field hashCode in canonical order: positionals first ($1, $2, ...),
  /// then named fields sorted by name.
  int get $hashCode {
    final keys = mapping.keys.toList()..sort(_compareKeys);
    return Object.hashAll([
      for (final key in keys) _fieldHash(fields[mapping[key]!]),
    ]);
  }

  Object? _fieldHash(Object? field) =>
      field is $Instance ? field.$getProperty(runtime, 'hashCode')?.$value : null;

  static int _compareKeys(String a, String b) {
    final aPos = a.startsWith('\$');
    final bPos = b.startsWith('\$');
    if (aPos != bPos) return aPos ? -1 : 1;
    if (aPos) {
      return int.parse(a.substring(1)).compareTo(int.parse(b.substring(1)));
    }
    return a.compareTo(b);
  }

  // Host-side identity for collections: Dart Map/Set and `identical`-keyed
  // lookups use `==`/`hashCode` directly, bypassing `$getProperty`.
  @override
  bool operator ==(Object other) => $structurallyEquals(other);

  @override
  int get hashCode => $hashCode;

  String $stringify() {
    final keys = mapping.keys.toList()..sort(_compareKeys);
    return '(${[
      for (final key in keys)
        key.startsWith('\$')
            ? runtime.valueToString(fields[mapping[key]!] as $Value?)
            : '$key: ${runtime.valueToString(fields[mapping[key]!] as $Value?)}',
    ].join(', ')})';
  }

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
    switch (identifier) {
      case '==':
        return $Function(
          (runtime, target, r, s, c) => $bool($structurallyEquals(r)),
        );
      case '!=':
        return $Function(
          (runtime, target, r, s, c) => $bool(!$structurallyEquals(r)),
        );
      case 'hashCode':
        return $int($hashCode);
      case 'toString':
        return $Function(
          (runtime, target, r, s, c) => $String($stringify()),
        );
      case 'runtimeType':
        return $TypeImpl(typeId, runtime);
    }
    throw NoSuchMethodError.withInvocation(
      this,
      Invocation.getter(Symbol(identifier)),
    );
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    throw NoSuchMethodError.withInvocation(
      this,
      Invocation.setter(Symbol(identifier), value),
    );
  }

  @override
  $Record get $value => this;

  @override
  $Record get $reified => this;
}
