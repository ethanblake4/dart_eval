import 'package:dart_eval/src/eval/expressions.dart';
import 'package:dart_eval/src/eval/functions.dart';
import 'package:dart_eval/src/eval/primitives.dart';
import 'package:dart_eval/src/eval/reference.dart';
import 'package:dart_eval/src/eval/scope.dart';
import 'package:dart_eval/src/eval/type.dart';

abstract class EvalValue<R> {
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
  bool operator ==(Object other) =>
      identical(this, other) || other is EvalValue && runtimeType == other.runtimeType && realValue == other.realValue;

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
  set value(EvalValue? newValue) => v.evalSetField(name, newValue ?? EvalNull());
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
      {String? sourceFile,
      Map<String, EvalValue>? fields,
      Map<String, Setter>? setters,
      Map<String, Getter>? getters,
      R? realValue})
      : super(type, evalSourceFile: sourceFile, realValue: realValue) {
    _fields = fields ?? {};
    _getters = getters ?? {};
    _setters = setters ?? {};
  }

  EvalValueImpl(EvalType type,
      {String? sourceFile, required EvalFieldListBreakout fieldListBreakout, dynamic? realValue})
      : super(type, evalSourceFile: sourceFile, realValue: realValue) {
    _fields = fieldListBreakout.values;
    _getters = fieldListBreakout.getters;
    _setters = fieldListBreakout.setters;
  }

  late Map<String, EvalValue> _fields;
  late Map<String, Setter> _setters;
  late Map<String, Getter> _getters;

  void addFields(EvalFieldListBreakout breakout) {
    _fields.addAll(breakout.values);
    _getters.addAll(breakout.getters);
    _setters.addAll(breakout.setters);
  }

  @override
  EvalValue evalGetField(String name, {bool internalGet = false}) {
    if(internalGet) {
      return _fields[name] ?? (throw ArgumentError(_fields.containsKey(name)
          ? ' Non-nullable field $name was not initialized'
          : 'Field $name does not exist'));
    }
    final getter = _getters[name];
    if (getter == null) {
      throw ArgumentError("Unknown field '$name'");
    }
    if (getter.get == null) {
      return _fields[name] ??
          (throw ArgumentError(_fields.containsKey(name)
              ? ' Non-nullable field $name was not initialized'
              : 'Field $name does not exist'));
    } else {
      try {
        final thisScope = EvalScope(null, {'this': EvalField('this', this, null, Getter(null))});
        final r = getter.get!.call(thisScope, EvalScope.empty, [], []);
        return r;
      } catch (e) {
        print('getField exception $e');
        if(e is Error) {
          print(e.stackTrace);
        }
        rethrow;
      }

    }
  }

  @override
  EvalValue evalSetField(String name, EvalValue value, {bool internalSet = false}) {
    if (internalSet) {
      return _fields[name] = value;
    }
    final setter = _setters[name];
    if (setter == null) {
      throw ArgumentError('No setter for field $name');
    }
    if (setter.set == null) {
      return _fields[name] = value;
    } else {
      final thisScope = EvalScope(null, {'this': EvalField('this', this, null, Getter(null))});
      return setter.set!.call(thisScope, EvalScope.empty, [], [Parameter(value)]);
    }
  }

  @override
  EvalField evalGetFieldRaw(String name) {
    return EvalField(name, _fields[name], _setters[name], _getters[name]);
  }

  @override
  void evalSetGetter(String name, Getter getter) {
    _getters[name] = getter;
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

  factory Getter.deferred(String name, EvalType type, EvalScope lexicalScope, EvalScope inheritedScope,
      EvalExpression deferredInitializer) {
    return Getter(EvalCallableImpl((_lexicalScope, _inheritedScope, generics, params, {EvalValue? target}) {
      final ref = lexicalScope.getFieldRaw(name);
      if (ref?.value != null) {
        return ref!.value!;
      } else {
        return lexicalScope
            .define(name,
                EvalField(name, deferredInitializer.eval(lexicalScope, inheritedScope), Setter(null), Getter(null)))
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
    return "EvalField{$name, (${getter != null ? 'get' : ''}${setter != null ? 'set': ''}): $value}";
  }
}

class EvalValueFieldRef implements EvalField {
  EvalValueFieldRef(this._value, this.name);

  @override
  String name;
  EvalValue _value;

  @override
  Getter? get getter => _value.evalGetFieldRaw(name).getter;

  @override
  set getter(Getter? newGetter) => _value.evalSetGetter(name, newGetter!);

  @override
  Setter? setter;

  @override
  EvalValue? get value => _value.evalGetFieldRaw(name).value;

  set value(EvalValue? newValue) => _value.evalSetField(name, newValue!, internalSet: true);
}

class EvalFieldListBreakout {
  EvalFieldListBreakout(this.values, this.getters, this.setters);

  factory EvalFieldListBreakout.withFields(Map<String, EvalField> fields) {
    final getters = <String, Getter>{};
    final setters = <String, Setter>{};
    final values = <String, EvalValue>{};
    fields.forEach((key, value) {
      if (value.getter != null) getters[key] = value.getter!;
      if (value.setter != null) setters[key] = value.setter!;
      if (value.value != null) values[key] = value.value!;
    });
    return EvalFieldListBreakout(values, getters, setters);
  }

  Map<String, EvalValue> values;
  Map<String, Getter> getters;
  Map<String, Setter> setters;
}
