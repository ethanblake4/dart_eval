import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/functions.dart';
import 'package:dart_eval/src/eval/primitives.dart';

import 'object.dart';

/// A scope in which variables can be defined
class EvalScope {
  const EvalScope(this.parent, this.defines);

  static const EvalScope empty = EvalScope(null, {});

  final EvalScope? parent;
  final Map<String, EvalField> defines;

  EvalField define(String name, EvalField value) {
    return defines[name] = value;
  }

  ScopedReference? lookup(String name) {
    final d = defines.containsKey(name) ? ScopedReference(this, name) : null;
    return d ?? parent?.lookup(name);
  }

  EvalValue<T> me<T>() {
    return lookup('this')!.value! as EvalValue<T>;
  }

  @override
  String toString() {
    return 'EvalScope{defines: $defines}';
  }
}

class ScopeWrapper {
  const ScopeWrapper(this.scope);

  final EvalScope scope;

  EvalValue call(String name, List<Parameter> args) {
    return (scope.lookup(name)!.value! as EvalCallable).call(scope, scope, [], args);
  }
}

/// A proxied combination of two [EvalScope]s
class EvalSequentialScope implements EvalScope {
  EvalSequentialScope(this.scope1, this.scope2);
  EvalScope scope1;
  EvalScope scope2;

  @override
  EvalField define(String name, EvalField value) {
    throw UnimplementedError('Cannot define properties on a SequentialScope');
  }

  @override
  Map<String, EvalField> get defines => throw UnimplementedError('Cannot access defines of a SequentialScope');

  @override
  ScopedReference? lookup(String name) {
    return scope1.lookup(name) ?? scope2.lookup(name);
  }

  @override
  EvalScope? get parent => null;

  @override
  EvalValue<T> me<T>() => lookup('this')!.value! as EvalValue<T>;
}

class EvalObjectScope implements EvalScope {
  EvalObjectScope();

  late EvalObject object;

  @override
  EvalField define(String name, EvalField value) {
    throw UnimplementedError();
  }

  @override
  Map<String, EvalField> get defines => throw UnimplementedError();

  @override
  ScopedReference? lookup(String name) {
    return ObjectScopedReference(object, name);
  }

  @override
  EvalValue<T> me<T>() => lookup('this')!.value! as EvalValue<T>;

  @override
  // TODO: implement parent
  EvalScope? get parent => throw UnimplementedError();
}

class ScopedReference {
  ScopedReference(this._scope, this.name);

  final EvalScope _scope;
  final String name;

  EvalValue? get value {
    final d = _scope.defines[name]!;
    final getter = d.getter!;
    if (getter.get != null) {
      return getter.get?.call(EvalScope.empty, EvalScope.empty, const [], const []);
    } else {
      return d.value ?? EvalNull();
    }
  }

  set value(EvalValue? newValue) {
    final d = _scope.defines[name]!;
    final setter = d.setter!;
    if (setter.set != null) {
      setter.set?.call(EvalScope.empty, EvalScope.empty, const [], [Parameter(newValue ?? EvalNull())]) ?? EvalNull();
    } else {
      d.value = newValue;
    }
  }

  void seti(EvalValue newValue) {
    final d = _scope.defines[name]!;
    d.value = newValue;
  }
}

class ObjectScopedReference implements ScopedReference {
  ObjectScopedReference(this.object, this.name);

  final EvalObject object;
  final String name;

  EvalValue? get value {
    try {
      return object.getField(name);
    } catch (e) {
      return null;
    }
  }

  set value(EvalValue? newValue) => object.setField(name, newValue ?? EvalNull());

  @override
  EvalScope get _scope => throw UnimplementedError();

  @override
  void seti(EvalValue newValue) {
    throw UnimplementedError('seti on objectscopedref');
  }
}
