import 'package:dart_eval/src/eval/runtime/exception.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_closure.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_instance.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/base.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/num.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/object.dart';

import '../../../dart_eval_bridge.dart';

/// Typedef of a function that can be called by dart_eval.
///
/// Arguments travel in the canonical register-call ABI: R and S hold the
/// first two arguments. C encodes the remainder: an `int` argument count
/// (0, 1, or 2) when fewer than three arguments are supplied, otherwise a
/// `List<Object?>` holding arguments 2..n-1. Callees decode the supplied
/// count as `c is int ? c : 2 + (c as List).length`; implementations with
/// a fixed signature may read the tail list positionally without decoding.
typedef EvalCallableFunc =
    $Value? Function(
      Runtime runtime,
      $Value? target,
      Object? r,
      Object? s,
      Object? c,
    );

/// Generated static bridge entry. Arguments are canonical language values.
/// Up to three arguments occupy R/S/C. Beyond three, R/S hold the first two
/// and C holds a borrowed `List<Object?>` with the remaining arguments.
/// Read overflow arguments before calling host code; never retain that list.
typedef EvalRegisterFunc =
    $Value? Function(Runtime runtime, Object? r, Object? s, Object? c);

/// Abstract supertype for values representing a callable in dart_eval.
///
/// Arguments travel in the [EvalCallableFunc] register-call ABI: R/S hold
/// arguments 0 and 1, and C is an `int` argument count below three arguments
/// or a `List<Object?>` of arguments 2..n-1 otherwise.
abstract class EvalCallable {
  $Value? call(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  );
}

/// Abstract supertype for values representing a [Function] in dart_eval.
///
/// See [$Function] or [$Closure] to wrap an existing Dart function as a
/// [EvalFunction].
abstract class EvalFunction implements $Instance, EvalCallable {
  const EvalFunction();

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'call':
        return this;
      case '==':
        return $Function((runtime, target, r, s, c) => $bool(this == r));
      case 'hashCode':
        return $int(hashCode);
      case 'toString':
        return $Function(
          (runtime, target, r, s, c) => $String(toString()),
        );
      default:
        throw EvalUnknownPropertyException(identifier);
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    throw EvalUnknownPropertyException(identifier);
  }

  @override
  dynamic get $value => throw UnimplementedError();

  @override
  dynamic get $reified => throw UnimplementedError();
}

/// An implementation of [EvalFunction] that wraps an existing Dart function for
/// use in dart_eval.
///
/// The wrapped function should be of the type [EvalCallableFunc].
///
/// The target is the object that the function is being called on, or null if
/// the function is being called statically.
///
/// The args are the arguments passed to the function.
///
/// In dynamic invocation / closure contexts such as when passing a function
/// as an argument, use [$Closure] instead.
class $Function extends EvalFunction {
  const $Function(this.func);

  static const $declaration = BridgeClassDef(
    BridgeClassType(BridgeTypeRef(CoreTypes.function)),
    constructors: {},
    methods: {
      'apply': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
          params: [
            BridgeParameter(
              'function',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              false,
            ),
            BridgeParameter(
              'positionalArguments',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
                ]),
              ),
              false,
            ),
            BridgeParameter(
              'namedArguments',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.map, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.symbol)),
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
                ]),
              ),
              true,
            ),
          ],
        ),
        isStatic: true,
      ),
    },
    wrap: true,
  );

  final EvalCallableFunc func;

  /// `Function.apply(function, positionalArguments, [namedArguments])`.
  static $Value? $apply(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final positional = switch (s) {
      $Value v => (v.$value as List).cast<Object?>(),
      _ => (s as List).cast<Object?>(),
    };
    // `c` is the argument-count integer when fewer than three arguments were
    // supplied (the namedArguments parameter omitted).
    final namedArg = switch (c) {
      $Value v => v.$value as Map?,
      Map m => m,
      _ => null,
    };
    final namedMap = <String, Object?>{};
    if (namedArg != null) {
      for (final entry in namedArg.entries) {
        final key = entry.key;
        namedMap[_symbolName(key is $Value ? key.$value : key)] =
            entry.value;
      }
    }
    return _apply(runtime, r, positional, namedMap);
  }

  /// Symbol's only string view is `Symbol("name")`; the SDK's Symbol has no
  /// public name getter.
  static String _symbolName(Object? symbol) {
    if (symbol is Symbol) {
      final str = symbol.toString();
      const prefix = 'Symbol("';
      if (str.startsWith(prefix) && str.endsWith('")')) {
        return str.substring(prefix.length, str.length - 2);
      }
      return str;
    }
    return symbol.toString();
  }

  static $Value? _apply(
    Runtime runtime,
    Object? fn,
    List<Object?> positional,
    Map<String, Object?> named,
  ) {
    final namedNames = named.keys.toList();
    final args = [...positional, ...named.values];
    final first = args.isEmpty ? null : args[0];
    final rest = args.length <= 1
        ? null
        : args.length == 2
        ? args[1]
        : args.sublist(1);
    if (fn is TypedClosure) {
      return fn.invoke(
        positional.length,
        first,
        rest,
        namedNames: namedNames,
        runtime: runtime,
      );
    }
    if (fn is TypedInstance) {
      return fn.invoke(
        'call',
        positional.length,
        first,
        rest,
        namedNames: namedNames,
        runtime: runtime,
      );
    }
    if (fn is EvalCallable) {
      return fn.call(
        runtime,
        null,
        first,
        args.length > 1 ? args[1] : null,
        args.length < 3 ? args.length : args.sublist(2),
      );
    }
    if (fn is Function) {
      return TypedInterop.boxExternal(
        Function.apply(
          fn,
          positional.map((e) => e is $Value ? e.$value : e).toList(),
          named.isEmpty
              ? null
              : {
                  for (final e in named.entries)
                    Symbol(e.key): e.value is $Value
                        ? (e.value as $Value).$value
                        : e.value,
                },
        ),
        runtime: runtime,
      );
    }
    throw NoSuchMethodError.withInvocation(
      fn,
      Invocation.method(const Symbol('call'), positional),
    );
  }

  @override
  get $value => func;

  @override
  get $reified => func;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    try {
      return super.$getProperty(runtime, identifier);
    } on UnimplementedError {
      return $Object(this).$getProperty(runtime, identifier);
    } on EvalUnknownPropertyException {
      return $Object(this).$getProperty(runtime, identifier);
    }
  }

  @override
  $Value? call(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return func(runtime, target, r, s, c);
  }

  @override
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(CoreTypes.function);

  @override
  String toString() {
    return 'Function{func: $func}';
  }
}

/// Variant of [$Function] for use in a dynamic invocation / closure context,
/// such as when passing a function as an argument.
class $Closure extends EvalFunction {
  const $Closure(this.func, [this.$this]);

  final EvalCallableFunc func;
  final $Instance? $this;

  @override
  get $value => func;

  @override
  get $reified => func;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    try {
      return super.$getProperty(runtime, identifier);
    } on UnimplementedError {
      return $Object(this).$getProperty(runtime, identifier);
    } on EvalUnknownPropertyException {
      return $Object(this).$getProperty(runtime, identifier);
    }
  }

  @override
  $Value? call(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return func(runtime, $this ?? target, r, s, c);
  }

  @override
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(CoreTypes.function);
}
