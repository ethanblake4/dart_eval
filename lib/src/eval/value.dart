import 'package:dart_eval/src/eval/expressions.dart';
import 'package:dart_eval/src/eval/functions.dart';
import 'package:dart_eval/src/eval/scope.dart';
import 'package:dart_eval/src/eval/type.dart';

abstract class EvalValue<R> {
  EvalValue(this.evalType, {this.sourceFile, this.realValue});

  final EvalType evalType;
  final String? sourceFile;
  final R? realValue;

  EvalValue getField(String name);

  void setField(String name, EvalValue value);

  @override
  String toString() {
    return 'EvalValue{type: $evalType}';
  }
}

class EvalReturn implements EvalValue {
  EvalReturn(this.returnValue);

  EvalValue returnValue;

  @override
  EvalType get evalType => throw UnimplementedError();

  @override
  String get sourceFile => throw UnimplementedError();

  @override
  dynamic? get realValue => throw UnimplementedError();

  @override
  EvalValue getField(String name) {
    throw UnimplementedError();
  }

  @override
  void setField(String name, EvalValue value) {
    throw UnimplementedError();
  }
}

mixin ValueInterop<T> {
  @override
  T? get realValue;
}

class EvalValueImpl<R> extends EvalValue<R> {
  EvalValueImpl.withIndividual(EvalType type,
      {String? sourceFile,
      Map<String, EvalValue>? fields,
      Map<String, Setter>? setters,
      Map<String, Getter>? getters,
      R? realValue})
      : super(type, sourceFile: sourceFile, realValue: realValue) {
    _fields = fields ?? {};
    _getters = getters ?? {};
    _setters = setters ?? {};
  }

  EvalValueImpl(EvalType type,
      {String? sourceFile, required EvalFieldListBreakout fieldListBreakout, dynamic? realValue})
      : super(type, sourceFile: sourceFile, realValue: realValue) {
    _fields = fieldListBreakout.values;
    _getters = fieldListBreakout.getters;
    _setters = fieldListBreakout.setters;
  }

  late Map<String, EvalValue> _fields;
  late Map<String, Setter> _setters;
  late Map<String, Getter> _getters;

  @override
  EvalValue getField(String name) {
    final getter = _getters[name];
    if (getter == null) {
      throw ArgumentError("Unknown field '$name'");
    }
    if (getter.get == null) {
      return _fields[name]!;
    } else {
      final thisScope = EvalScope(null, {'this': EvalField('this', this, null, Getter(null))});
      return getter.get!.call(thisScope, EvalScope.empty, [], []);
    }
  }

  @override
  EvalValue setField(String name, EvalValue value) {
    final setter = _setters[name];
    if (setter == null) {
      throw Error();
    }
    if (setter.set == null) {
      return _fields[name] = value;
    } else {
      final thisScope = EvalScope(null, {'this': EvalField('this', this, null, Getter(null))});
      return setter.set!.call(thisScope, EvalScope.empty, [], [Parameter(value)]);
    }
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
      final ref = lexicalScope.lookup(name);
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
