import 'package:dart_eval/src/eval/generics.dart';
import 'package:dart_eval/src/eval/object.dart';
import 'package:dart_eval/src/eval/primitives.dart';
import 'package:dart_eval/src/eval/scope.dart';
import 'package:dart_eval/src/eval/statements.dart';
import 'package:dart_eval/src/eval/type.dart';
import 'package:dart_eval/src/eval/value.dart';

import '../../dart_eval.dart';
import 'expressions.dart';

typedef CallableFunc = EvalValue Function(
    EvalScope lexicalScope, EvalScope inheritedScope, List<EvalType> generics, List<Parameter> args,
    {EvalValue? target});

typedef BridgeMapper<T> = EvalValue Function(T? realValue);

class Parameter {
  Parameter(this.value);

  final EvalValue value;

  static SeparatedParameterList coalesceNamed(List<Parameter> args) {
    final m = <String, EvalValue>{};
    final p = <Parameter>[];
    for (final a in args) {
      if (a is NamedParameter) {
        m[a.name] = a.value;
      } else
        p.add(a);
    }
    return SeparatedParameterList(p, m);
  }
}

class SeparatedParameterList {
  SeparatedParameterList(this.positional, this.named);

  final List<Parameter> positional;
  final Map<String, EvalValue> named;
}

class NamedParameter extends Parameter {
  NamedParameter(this.name, EvalValue value) : super(value);
  final String name;
}

class ParameterDefinition {
  ParameterDefinition(this.name, this.type, this.nullable, this.optional, this.named, this.required, this.dfValue,
      {this.isField = false});

  final String name;
  EvalType? type;
  final bool isField;
  final bool optional;
  final bool named;
  final bool nullable;
  final bool required;
  final EvalExpression? dfValue;

  EvalValue? extractFrom(List<Parameter> args, int i, [Map<String, EvalValue>? argMap]) {
    final _argMap = argMap ?? Parameter.coalesceNamed(args).named;
    if (named) {
      return _argMap[name];
    } else {
      return args.length > i ? args[i].value : (required ? throw ArgumentError('Parameter $name required') : null);
    }
  }
}

abstract class EvalCallable {
  const EvalCallable();

  EvalValue call(EvalScope lexicalScope, EvalScope inheritedScope, List<EvalType> generics, List<Parameter> args,
      {EvalValue? target});
}

class EvalCallableImpl extends EvalCallable {
  const EvalCallableImpl(this.function) : super();

  final CallableFunc function;

  @override
  EvalValue call(EvalScope lexicalScope, EvalScope inheritedScope, List<EvalType> generics, List<Parameter> args,
      {EvalValue? target}) {
    return function(lexicalScope, inheritedScope, generics, args, target: target);
  }
}

abstract class EvalFunction<T> extends EvalObject<T> {
  EvalFunction(EvalAbstractClass prototype) : super(prototype, fields: {});
}

class EvalFunctionImpl<T> extends EvalObject<T> implements EvalFunction<T> {
  static EvalAbstractClass functionClass = EvalAbstractClass([
    //DartFunctionDeclaration('apply', functionBody, isStatic: true, visibility: visibility)
  ], EvalGenericsList([]), EvalType.functionType, EvalScope.empty);

  EvalFunctionImpl(this._function, this.params, {this.inheritedScope, this.lexicalScope})
      : super(functionClass, fields: {});

  final DartMethodBody _function;
  final EvalScope? inheritedScope;
  final EvalScope? lexicalScope;
  final List<ParameterDefinition> params;

  @override
  EvalValue getField(String name) {
    throw Error();
  }

  @override
  EvalValue call(EvalScope lexicalScope, EvalScope inheritedScope, List<EvalType> generics, List<Parameter> args,
      {EvalValue? target}) {
    if (_function.block != null) {
      final functionScope = EvalScope(this.lexicalScope ?? lexicalScope, {});
      var lastPositional = false;
      var lastNonOptional = false;
      final namedParams = <String, ParameterDefinition>{};
      final namedArgs = <NamedParameter>[];
      for (var i = 0; i < params.length; i++) {
        final param = params[i];
        final ai = args[i];
        if (ai is NamedParameter) {
          namedArgs.add(ai);
        }
        if (param.named) {
          lastPositional = true;
          namedParams[param.name] = param;
        } else if (param.optional) {
          lastNonOptional = true;
          functionScope.define(
              param.name,
              EvalField(
                  param.name,
                  (args.length - 1 < i || args[i] is NamedParameter)
                      ? (param.dfValue?.eval(EvalScope.empty, this.inheritedScope ?? EvalScope.empty) ?? EvalNull())
                      : args[i].value,
                  Setter(null),
                  Getter(null)));
        } else {
          if (lastPositional || lastNonOptional) {
            throw ArgumentError('Cannot have positional arguments after named/optional arguments');
          }
          if (args.length - 1 < i) {
            throw ArgumentError('Not enough arguments');
          }
          functionScope.define(params[i].name, EvalField(params[i].name, args[i].value, Setter(null), Getter(null)));
        }
      }

      for (final na in namedArgs) {
        if (!namedParams.containsKey(na.name)) {
          throw ArgumentError('Named parameter ${na.name} doesn\'t exist on function');
        }
        functionScope.define(na.name, EvalField(na.name, na.value, Setter(null), Getter(null)));
      }
      return _function.block!.eval(functionScope, this.inheritedScope ?? EvalScope.empty).value ?? EvalNull();
    } else if (_function.callable != null) {
      return _function.callable!(lexicalScope, inheritedScope, generics, args, target: target);
    }
    throw ArgumentError('No function block or callable');
  }
}

class EvalBridgeFunction<T> extends EvalObject<Function> implements EvalFunctionImpl<Function>, ValueInterop<Function> {
  EvalBridgeFunction(Function function, this.mapper)
      : super(EvalFunctionImpl.functionClass, fields: {}, realValue: function);

  BridgeMapper<T> mapper;

  @override
  EvalValue call(EvalScope lexicalScope, EvalScope inheritedScope, List<EvalType> generics, List<Parameter> args,
      {EvalValue? target}) {
    final named = <Symbol, dynamic>{};
    final pos = <dynamic>[];

    for (final ar in args) {
      if (ar is NamedParameter) {
        named[Symbol(ar.name)] = ar.value.realValue;
      } else {
        pos.add(ar.value.realValue);
      }
    }
    return mapper(Function.apply(realValue!, pos, named));
  }

  @override
  DartMethodBody get _function => throw UnimplementedError();

  @override
  EvalScope? get inheritedScope => throw UnimplementedError();

  @override
  EvalScope? get lexicalScope => throw UnimplementedError();

  @override
  List<ParameterDefinition> get params => throw UnimplementedError();
}

class DartMethodBody {
  DartMethodBody({this.block, this.callable});

  //List<ParameterDefinition> params;
  DartBlockStatement? block;
  CallableFunc? callable;

  @override
  String toString() {
    return 'DartMethodBody{block: $block, callable: $callable}';
  }
}
