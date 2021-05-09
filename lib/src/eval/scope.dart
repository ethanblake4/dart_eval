import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/functions.dart';
import 'package:dart_eval/src/eval/primitives.dart';
import 'package:dart_eval/src/eval/reference.dart';

import 'object.dart';

/// A scope in which variables can be defined
class EvalScope {
  const EvalScope(this.parent, this.defines);

  static final EvalScope empty = EvalScope(null, {});

  final EvalScope? parent;
  final Map<String, EvalField> defines;

  EvalField? getFieldRaw(String name) => defines[name];

  EvalField define(String name, EvalField value) {
    final v = value.value;
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
    return 'EvalScope{defines: $defines, parent: $parent}';
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

  @override
  String toString() {
    return 'EvalSequentialScope{scope1: $scope1, scope2: $scope2}';
  }

  @override
  EvalField? getFieldRaw(String name) => scope1.getFieldRaw(name) ?? scope2.getFieldRaw(name);
}

// An object scope, prefixed by a lexical scope
class EvalObjectLexicalScope implements EvalScope {
  EvalObjectLexicalScope(this.parent);

  @override
  EvalScope? parent;

  EvalValue? object;

  @override
  ScopedReference? lookup(String name) {
    if (parent == null && object == null) {
      return null;
    } else if (parent == null) {
      return ObjectScopedReference(object!, name);
    } else if (object == null) {
      return parent!.lookup(name);
    }
    return StaticLexicalObjectScopedReference(object!, parent!.lookup(name), name);
  }

  @override
  EvalValue<T> me<T>() => lookup('this')!.value! as EvalValue<T>;

  @override
  EvalField define(String name, EvalField value) {
    // TODO setSetter
    object!.evalSetField(name, value.value!);
    object!.evalSetGetter(name, value.getter!);
    return value;
  }

  @override
  Map<String, EvalField> get defines => throw UnimplementedError();

  @override
  String toString() {
    return 'EvalObjectLexicalScope{object: $object, parent: $parent}';
  }

  @override
  EvalField? getFieldRaw(String name) {
    return object?.evalGetFieldRaw(name);
  }
}

class EvalObjectScope implements EvalScope {
  EvalObjectScope();

  late EvalValue object;

  @override
  EvalField define(String name, EvalField value) {
    // TODO setSetter
    object.evalSetField(name, value.value!);
    object.evalSetGetter(name, value.getter!);
    return value;
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
  EvalScope? get parent => throw UnimplementedError();

  @override
  EvalField? getFieldRaw(String name) {
    return object.evalGetFieldRaw(name);
  }

  @override
  String toString() {
    return 'EvalObjectScope{object: $object, parent: $parent}';
  }
}

class ScopedReference implements Reference {
  ScopedReference(this._scope, this.name);

  final EvalScope _scope;
  final String name;

  @override
  EvalValue? get value {
    final d = _scope.defines[name]!;
    final getter = d.getter!;
    if (getter.get != null) {
      return getter.get?.call(EvalScope.empty, EvalScope.empty, const [], const []);
    } else {
      return d.value ?? EvalNull();
    }
  }

  @override
  set value(EvalValue? newValue) {
    final d = _scope.defines[name]!;
    final setter = d.setter!;
    if (setter.set != null) {
      setter.set!.call(EvalScope.empty, EvalScope.empty, const [], [Parameter(newValue ?? EvalNull())]);
    } else {
      d.value = newValue ?? EvalNull();
    }
  }

  void seti(EvalValue newValue) {
    final d = _scope.defines[name]!;
    d.value = newValue;
  }
}

class ObjectScopedReference implements ScopedReference {
  ObjectScopedReference(this.object, this.name);

  final EvalValue object;
  final String name;

  EvalValue? get value {
    try {
      return object.evalGetField(name);
    } catch (e) {
      return null;
    }
  }

  set value(EvalValue? newValue) => object.evalSetField(name, newValue ?? EvalNull());

  @override
  EvalScope get _scope => throw UnimplementedError();

  @override
  void seti(EvalValue newValue) {
    throw UnimplementedError('seti on objectscopedref');
  }
}

class StaticLexicalObjectScopedReference extends ObjectScopedReference {
  StaticLexicalObjectScopedReference(EvalValue object, this.scopeRef, String name) : super(object, name);

  final ScopedReference? scopeRef;

  @override
  EvalValue? get value {
    final osr = super.value;
    if(osr != null) return osr;

    return scopeRef?.value;
  }

  @override
  set value(EvalValue? newValue) {
    try {
      super.value = newValue;
    } catch (e) {
      print(e);
      print(object);
      scopeRef!.value = newValue;
    }
  }
}