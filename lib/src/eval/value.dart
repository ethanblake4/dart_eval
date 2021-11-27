import 'package:dart_eval/src/eval/expressions.dart';
import 'package:dart_eval/src/eval/functions.dart';
import 'package:dart_eval/src/eval/primitives.dart';
import 'package:dart_eval/src/eval/reference.dart';
import 'package:dart_eval/src/eval/scope.dart';
import 'package:dart_eval/src/eval/type.dart';

abstract class EvalValue<R> implements EvalCallable {
  EvalValue(this.evalType, {this.evalSourceFile, this.realValue});

  final EvalType evalType;
  final String? evalSourceFile;
  final R? realValue;

  dynamic evalReifyFull() => realValue;

  EvalValue evalGetField(String name);

  EvalField evalGetFieldRaw(String name);

  void evalSetGetter(String name, Getter getter);

  void evalSetField(String name, EvalValue value, {bool internalSet = false});

  @override
  String toString() {
    return 'EvalValue{type: $evalType}';
  }

  @override
  EvalValue call(EvalScope lexicalScope, EvalScope inheritedScope,
      List<EvalType> generics, List<Parameter> args,
      {EvalValue? target}) {
    throw UnimplementedError();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvalValue &&
          runtimeType == other.runtimeType &&
          realValue == other.realValue;

  @override
  int get hashCode => realValue.hashCode;
}

class FieldReference extends Reference {
  FieldReference(this.v, this.name);

  final EvalValue v;
  final String name;

  @override
  EvalValue? get value => v.evalGetField(name);

  @override
  set value(EvalValue? newValue) =>
      v.evalSetField(name, newValue ?? EvalNull());
}

class EvalReturn implements EvalValue {
  EvalReturn(this.returnValue);

  EvalValue returnValue;

  @override
  EvalType get evalType => throw UnimplementedError();

  @override
  String get evalSourceFile => throw UnimplementedError();

  @override
  dynamic? get realValue => throw UnimplementedError();

  @override
  dynamic evalReifyFull() => realValue;

  @override
  EvalValue call(EvalScope lexicalScope, EvalScope inheritedScope,
      List<EvalType> generics, List<Parameter> args,
      {EvalValue? target}) {
    throw UnimplementedError();
  }

  @override
  EvalValue evalGetField(String name) {
    throw UnimplementedError();
  }

  @override
  EvalField evalGetFieldRaw(String name) {
    throw UnimplementedError();
  }

  @override
  void evalSetField(String name, EvalValue value, {bool internalSet = false}) {
    throw UnimplementedError();
  }

  @override
  void evalSetGetter(String name, Getter getter) {
    throw UnimplementedError();
  }
}

mixin ValueInterop<T> {
  T? get realValue;

  dynamic evalReifyFull() => realValue;
}

class EvalValueImpl<R> extends EvalValue<R> {
  EvalValueImpl.withIndividual(EvalType type,
      {String? sourceFile, Map<String, EvalField>? fields, R? realValue})
      : super(type, evalSourceFile: sourceFile, realValue: realValue) {
    _fields = {...fields ?? {}};
  }

  EvalValueImpl(EvalType type,
      {String? sourceFile,
      required Map<String, EvalField> fields,
      dynamic realValue})
      : super(type, evalSourceFile: sourceFile, realValue: realValue) {
    _fields = {...fields};
  }

  late Map<String, EvalField> _fields;

  void addFields(Map<String, EvalField> fields) {
    _fields.addAll(fields);
  }

  @override
  EvalValue evalGetField(String name, {bool internalGet = false}) {
    final field = _fields[name];

    if (internalGet) {
      return field?.value ??
          (throw ArgumentError(_fields.containsKey(name)
              ? ' Non-nullable field $name was not initialized'
              : 'Field $name does not exist'));
    }
    final getter = field?.getter;
    if (getter == null) {
      throw ArgumentError("Unknown field '$name'");
    }
    if (getter.get == null) {
      return field?.value ??
          (throw ArgumentError(_fields.containsKey(name)
              ? ' Non-nullable field $name was not initialized'
              : 'Field $name does not exist'));
    } else {
      try {
        final thisScope = EvalScope(
            null, {'this': EvalField('this', this, null, Getter(null))});
        final r = getter.get!.call(thisScope, EvalScope.empty, [], []);
        return r;
      } catch (e) {
        print('getField exception $e');
        if (e is Error) {
          print(e.stackTrace);
        }
        rethrow;
      }
    }
  }

  @override
  EvalValue evalSetField(String name, EvalValue value,
      {bool internalSet = false}) {
    if (internalSet) {
      return _fields[name]!.value = value;
    }
    final setter = _fields[name]?.setter;
    if (setter == null) {
      throw ArgumentError('No setter for field $name');
    }
    if (setter.set == null) {
      return _fields[name]!.value = value;
    } else {
      final thisScope = EvalScope(
          null, {'this': EvalField('this', this, null, Getter(null))});
      return setter.set!
          .call(thisScope, EvalScope.empty, [], [Parameter(value)]);
    }
  }

  @override
  EvalField evalGetFieldRaw(String name) {
    return _fields[name]!;
  }

  @override
  void evalSetGetter(String name, Getter getter) {
    _fields[name]!.getter = getter;
  }
}

class Setter {
  const Setter(this.set);

  /// If set to null, the default setter
  final EvalCallable? set;
}

class Getter {
  const Getter(this.get);

  /// If set to null, the default getter
  final EvalCallable? get;

  factory Getter.deferred(String name, EvalType type, EvalScope lexicalScope,
      EvalScope inheritedScope, EvalExpression deferredInitializer) {
    return Getter(EvalCallableImpl(
        (_lexicalScope, _inheritedScope, generics, params,
            {EvalValue? target}) {
      final ref = lexicalScope.getFieldRaw(name);
      if (ref?.value != null) {
        return ref!.value!;
      } else {
        return lexicalScope
            .define(
                name,
                EvalField(
                    name,
                    deferredInitializer.eval(lexicalScope, inheritedScope),
                    Setter(null),
                    Getter(null)))
            .value!;
      }
    }));
  }
}

final Setter defaultSetter = Setter(null);

class EvalField {
  EvalField(this.name, this.value, this.setter, this.getter);

  String name;
  EvalValue? value;
  Setter? setter;
  Getter? getter;

  @override
  String toString() {
    return "EvalField{$name, (${getter != null ? 'get' : ''}${setter != null ? 'set' : ''}): $value}";
  }
}

class EvalValueFieldRef implements EvalField {
  EvalValueFieldRef(this._value, this.name);

  @override
  String name;
  final EvalValue _value;

  @override
  Getter? get getter => _value.evalGetFieldRaw(name).getter;

  @override
  set getter(Getter? newGetter) => _value.evalSetGetter(name, newGetter!);

  @override
  Setter? setter;

  @override
  EvalValue? get value => _value.evalGetFieldRaw(name).value;

  @override
  set value(EvalValue? newValue) =>
      _value.evalSetField(name, newValue!, internalSet: true);
}
