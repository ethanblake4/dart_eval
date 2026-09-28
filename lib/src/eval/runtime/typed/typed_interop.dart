import 'dart:async';

import 'package:dart_eval/src/eval/runtime/class.dart';
import 'package:dart_eval/src/eval/bridge/runtime_bridge.dart';
import 'package:dart_eval/src/eval/runtime/function.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:dart_eval/src/eval/shared/types.dart';
import 'typed_instance.dart';
import 'typed_host_collections.dart';
import 'typed_program.dart';
import 'typed_closure.dart';
import 'typed_call_site.dart';
import 'typed_async.dart';

/// The dynamic-call boundary uses boxed language values exclusively.
///
/// The compiler emits every scalar box and unbox operation. Host functions must
/// use an explicit bridge wrapper, such as $Function or $Closure.
abstract final class TypedInterop {
  /// Guest Stream implementations keep their own listen dispatch.
  static Stream<Object?> stream(Object? value, Runtime runtime) =>
      value is TypedInstance
      ? _GuestHostStream(value, runtime)
      : (value as $Value).$value as Stream<Object?>;

  /// Adapts guest iterators returned to an SDK superclass implementation.
  static Iterator<T> exportIterator<T>(Object? value, Runtime runtime) {
    if (value is $Iterator) {
      return _ExportedIterator<T>(value.$value, runtime);
    }
    if (value is Iterator<T>) return value;
    return _GuestHostIterator<T>(value, runtime);
  }

  /// Export iterable elements lazily at a native SDK boundary.
  static Iterable<T> exportIterable<T>(Object? value, Runtime runtime) {
    if (value is TypedInstance) {
      final Object? bridge = value.bridge;
      if (bridge is Iterable<T>) return bridge;
      return _GuestHostIterable<T>(value, runtime);
    }
    final iterable = exportExternal(value, runtime: runtime) as Iterable;
    return iterable.map(
      (element) => exportExternal(element, runtime: runtime) as T,
    );
  }

  /// The host-side value of an object-bank slot: `$Value`s unwrap to their
  /// reified form, raw host objects pass through.
  static Object? reify(Object? value) =>
      value is $Value ? value.$reified : value;

  static $Value runtimeTypeOf(Runtime? runtime, Object? value) {
    final target = _runtime(runtime);
    return $TypeImpl(
      value == null
          ? target.lookupType(CoreTypes.nullType)
          : (value as $Value).$getRuntimeType(target),
      target,
    );
  }

  static BridgeSuperShim newBridgeSuperShim() => BridgeSuperShim();

  static void parentBridgeSuperShim(Object? shim, Object? parent) {
    (shim as BridgeSuperShim).bridge = parent as $Bridge;
  }

  static $Instance attachBridge(
    Runtime? runtime,
    Object? host,
    Object? subclass,
    int typeId,
  ) {
    final target = _runtime(runtime);
    final instance = host as $Instance;
    Runtime.bridgeData[instance] = BridgeData(
      target,
      typeId,
      subclass as $Instance?,
    );
    return instance;
  }

  /// Resolve metadata outside the switch so its table does not stay live in
  /// the arithmetic loop. Generated bridges consume canonical R/S/C directly.
  @pragma('vm:never-inline')
  static $Value? invokeExternal(
    TypedProgram program,
    Runtime? runtime,
    Object? first,
    Object? second,
    Object? rest,
    int siteIndex,
  ) {
    final target = _runtime(runtime);
    final site = program.externalCalls[siteIndex];
    return target.invokeTypedExternal(
      site.externalFunctionId,
      site.argumentCount,
      first,
      second,
      rest,
    );
  }

  /// Materialize a `first`/`rest` register pair as a positional vector.
  ///
  /// [first] is argument 0. [rest] is argument 1 when [count] is 2, a
  /// (possibly borrowed) `List<Object?>` of arguments 1..count-1 when
  /// [count] exceeds 2, and ignored otherwise. Cold host-facing paths only.
  static List<$Value?> argList(int count, Object? first, Object? rest) {
    if (count == 0) return const [];
    if (count == 1) return [first as $Value?];
    if (count == 2) return [first as $Value?, rest as $Value?];
    final tail = rest as List<Object?>;
    return [
      first as $Value?,
      for (var i = 0; i < count - 1; i++) tail[i] as $Value?,
    ];
  }

  /// Materialize [EvalCallable.call] R/S/C arguments as a list. Cold paths
  /// only: `Function.apply`, argument checking, and error construction.
  static List<$Value?> callableArgs(Object? r, Object? s, Object? c) {
    if (c is int) {
      return switch (c) {
        0 => const [],
        1 => [r as $Value?],
        _ => [r as $Value?, s as $Value?],
      };
    }
    final tail = c as List<Object?>;
    return [
      r as $Value?,
      s as $Value?,
      for (var i = 0; i < tail.length; i++) tail[i] as $Value?,
    ];
  }

  /// Supplied argument count encoded in [EvalCallable.call]'s C slot.
  static int callableCount(Object? c) => c is int ? c : 2 + (c as List).length;

  /// Convert an [EvalCallable.call] S/C pair into the `rest` register form:
  /// S itself for two arguments, a `List<Object?>` of arguments 1..n-1 for
  /// more, or null below two.
  static Object? callableRest(Object? s, Object? c) {
    if (c is int) return c == 2 ? s : null;
    return [s, ...c as List<Object?>];
  }

  /// Split a positional vector into the `first`/`rest` register pair.
  static (Object?, Object?) splitVector(List<Object?> args) =>
      switch (args.length) {
        0 => (null, null),
        1 => (args[0], null),
        2 => (args[0], args[1]),
        _ => (args[0], args.sublist(1)),
      };

  /// Convert a `first`/`rest`/`count` register call into the
  /// [EvalCallable.call] ABI (arguments 0/1 in R/S; C is the `int` argument
  /// count below three arguments, else a `List<Object?>` of arguments 2..n-1).
  ///
  /// The tail list is a snapshot: [EvalCallable] implementations may retain
  /// or reenter past their arguments.
  static $Value? callCallable(
    Runtime? runtime,
    Object? receiver,
    int count,
    Object? first,
    Object? rest, {
    EvalCallable? callable,
  }) {
    final r = count > 0 ? first : null;
    final s = switch (count) {
      2 => rest,
      > 2 => (rest as List<Object?>)[0],
      _ => null,
    };
    final c = count < 3
        ? count
        : List<Object?>.generate(
            count - 2,
            (i) => (rest as List<Object?>)[i + 1],
            growable: false,
          );
    return (callable ?? receiver as EvalCallable).call(
      _runtime(runtime),
      receiver as $Value?,
      r,
      s,
      c,
    );
  }

  @pragma('vm:never-inline')
  static $Value? call(
    Runtime? runtime,
    Object? receiver,
    int count,
    Object? first,
    Object? rest,
  ) => switch (receiver) {
    TypedClosure() => receiver.invoke(count, first, rest, runtime: runtime),
    TypedHostFunction() => receiver.invokeHost(
      runtime,
      argList(count, first, rest),
    ),
    TypedMember() => receiver.invokeClosure(
      count,
      first,
      rest,
      runtime: runtime,
    ),
    TypedInstance() => receiver.invoke(
      'call',
      count,
      first,
      rest,
      runtime: runtime,
    ),
    _ => _runtime(
      runtime,
    ).invokeTypedObject(receiver, 'call', count, first, rest),
  };

  @pragma('vm:never-inline')
  static $Value? invoke(
    Runtime? runtime,
    Object? receiver,
    String name,
    int positionalCount,
    Object? first,
    Object? rest, {
    List<String> namedNames = const [],
  }) {
    if (receiver == null) {
      final count = positionalCount + namedNames.length;
      if (name == 'toString' && count == 0) return $String('null');
      throw NoSuchMethodError.withInvocation(
        null,
        Invocation.method(Symbol(name), [
          for (final argument in argList(count, first, rest))
            argument?.$reified,
        ]),
      );
    }
    return receiver is TypedInstance
        ? receiver.invoke(
            name,
            positionalCount,
            first,
            rest,
            namedNames: namedNames,
            runtime: runtime,
          )
        : _runtime(runtime).invokeTypedObject(
            receiver,
            name,
            positionalCount + namedNames.length,
            first,
            rest,
          );
  }

  static $Value? getProperty(Runtime? runtime, Object? receiver, String name) {
    if (receiver == null) {
      return switch (name) {
        'hashCode' => $int(null.hashCode),
        'toString' => $Function(
          (runtime, target, r, s, c) => c == 0
              ? $String('null')
              : throw ArgumentError('Expected no arguments'),
        ),
        _ => throw NoSuchMethodError.withInvocation(
          null,
          Invocation.getter(Symbol(name)),
        ),
      };
    }
    final value = receiver is TypedInstance
        ? receiver.getProperty(name, runtime: runtime)
        : (receiver as $Instance).$getProperty(_runtime(runtime), name);
    return value is $null ? null : value;
  }

  static void setProperty(
    Runtime? runtime,
    Object? receiver,
    String name,
    $Value? value,
  ) {
    if (receiver == null) {
      throw NoSuchMethodError.withInvocation(
        null,
        Invocation.setter(Symbol('$name='), value?.$reified),
      );
    }
    if (receiver is TypedInstance) {
      receiver.setProperty(name, value, runtime: runtime);
    } else {
      (receiver as $Instance).$setProperty(
        _runtime(runtime),
        name,
        value ?? const $null(),
      );
    }
  }

  @pragma('vm:never-inline')
  static bool equals(Runtime? runtime, Object? left, Object? right) {
    final a = left as $Value?, b = right as $Value?;
    if (isNull(a) || isNull(b)) return isNull(a) && isNull(b);
    if (a is EvalFunction) return a == b;
    // $Object is the explicit adapter for a native host object's operators.
    // Subclasses may override bridge dispatch and must use their own methods.
    if (a.runtimeType == $Object) {
      return (a as $Object).$value == exportExternal(b, runtime: runtime);
    }
    return toBool(invoke(runtime, a, '==', 1, b, null));
  }

  static bool isNull(Object? value) => value == null;

  @pragma('vm:never-inline')
  static int toInt(Object? value) => (value as $int).$value;
  @pragma('vm:never-inline')
  static double toDouble(Object? value) => (value as $double).$value;
  @pragma('vm:never-inline')
  static bool toBool(Object? value) => (value as $bool).$value;
  @pragma('vm:never-inline')
  static String toStringValue(Object? value) => (value as $String).$value;

  /// Normalize once when a host enters the typed machine.
  static $Value? boxExternal(
    Object? value, {
    Runtime? runtime,
    int? runtimeTypeId,
  }) => switch (value) {
    null || $null() => null,
    $Value() => value,
    int() => $int(value),
    double() => $double(value),
    bool() => $bool(value),
    String() => $String(value),
    Function() => TypedHostFunction(value),
    List() || Map() || Set() => TypedHostCollections.box(
      value,
      runtime,
      runtimeTypeId: runtimeTypeId,
    ),
    _ => runtime == null ? $Object(value) : runtime.wrap(value),
  };

  /// Export scalar wrappers once when control returns to host Dart.
  /// Guest-only instances retain their identity; bridge subclasses expose their
  /// existing native bridge object.
  static Object? exportExternal(Object? value, {Runtime? runtime}) =>
      switch (value) {
        $null() => null,
        TypedHostFunction() => value.function,
        TypedInstance() => value.bridge ?? value,
        EvalFunction() => value,
        $List() => TypedHostCollections.export(value.$value, value, runtime),
        $Map() => TypedHostCollections.export(value.$value, value, runtime),
        $Set() => TypedHostCollections.export(value.$value, value, runtime),
        $Value() => value.$value,
        _ => value,
      };

  static Runtime _runtime(Runtime? runtime) =>
      runtime ??
      (throw StateError('A Runtime is required to invoke dart_eval objects'));
}

final class _GuestHostStream extends Stream<Object?> {
  _GuestHostStream(this.receiver, this.runtime);
  final TypedInstance receiver;
  final Runtime runtime;

  @override
  StreamSubscription<Object?> listen(
    void Function(Object?)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final member = receiver.resolve(TypedMemberKind.method, 'listen');
    final closure = member?.boundClosure;
    final descriptor = closure?.descriptor;
    EvalFunction callback(EvalCallableFunc function, int index, int arity) {
      final wrapped = $Closure.withNamed(
        function,
        null,
        positionalParameterCount: arity,
        namedParameters: const [],
      );
      if (descriptor == null ||
          index < 0 ||
          index >= descriptor.parameterTypeIds.length ||
          descriptor.parameterTypeIds[index] < 0) {
        return wrapped;
      }
      final type = runtime.resolveTypedEnvironmentType(
        descriptor.parameterTypeIds[index],
        actualOwnerType: member!.receiver.$getRuntimeType(runtime),
        callableTypeArguments: closure!.definingTypeArguments,
        typeEnvironment: closure.definingTypeEnvironment,
      );
      if (!runtime.isTypedFunctionTypeDescriptor(type)) return wrapped;
      return TypedCheckedFunction(runtime, type, wrapped);
    }

    int namedIndex(String name) => descriptor == null
        ? -1
        : descriptor.positionalCount + descriptor.namedNames.indexOf(name);
    final subscription = receiver.invoke(
      'listen',
      1,
      onData == null
          ? null
          : callback(
              (runtime, target, r, s, c) {
                onData(r);
                return null;
              },
              0,
              1,
            ),
      [
        onError == null
            ? null
            : callback(
                (runtime, target, r, s, c) {
                  final trace =
                      (s as $StackTrace?)?.$value ?? StackTrace.current;
                  if (onError is void Function(Object, StackTrace)) {
                    onError(r!, trace);
                  } else {
                    Function.apply(onError, [r]);
                  }
                  return null;
                },
                namedIndex('onError'),
                2,
              ),
        onDone == null
            ? null
            : callback(
                (runtime, target, r, s, c) {
                  onDone();
                  return null;
                },
                namedIndex('onDone'),
                0,
              ),
        cancelOnError == null ? null : $bool(cancelOnError),
      ],
      namedNames: const ['onError', 'onDone', 'cancelOnError'],
      runtime: runtime,
    );
    return subscription is TypedInstance
        ? _GuestHostSubscription(subscription, runtime)
        : subscription!.$value as StreamSubscription<Object?>;
  }
}

final class _GuestHostSubscription implements StreamSubscription<Object?> {
  _GuestHostSubscription(this.receiver, this.runtime);
  final TypedInstance receiver;
  final Runtime runtime;

  TypedMember? _member(String name) =>
      receiver.resolve(TypedMemberKind.method, name);

  int? _parameterType(TypedMember? member) {
    final closure = member?.boundClosure;
    if (closure == null || closure.descriptor.parameterTypeIds.isEmpty) {
      return null;
    }
    final type = closure.descriptor.parameterTypeIds.first;
    if (type < 0) return null;
    return runtime.resolveTypedEnvironmentType(
      type,
      actualOwnerType: member!.receiver.$getRuntimeType(runtime),
      callableTypeArguments: closure.definingTypeArguments,
      typeEnvironment: closure.definingTypeEnvironment,
    );
  }

  EvalFunction _callback(String name, int arity, EvalCallableFunc function) {
    final callback = $Closure.withNamed(
      function,
      null,
      positionalParameterCount: arity,
      namedParameters: const [],
    );
    final type = _parameterType(_member(name));
    return type != null && runtime.isTypedFunctionTypeDescriptor(type)
        ? TypedCheckedFunction(runtime, type, callback)
        : callback;
  }

  Future<Object?> _future(Object? value) =>
      TypedAsyncState(-1, runtime).complete(value);

  @override
  Future<void> cancel() => _future(
    receiver.invoke('cancel', 0, null, null, runtime: runtime),
  ).then<void>((_) {});

  @override
  void pause([Future<void>? resumeSignal]) {
    receiver.invoke(
      'pause',
      resumeSignal == null ? 0 : 1,
      resumeSignal == null
          ? null
          : $Future<void>.wrap(
              resumeSignal,
              runtimeTypeId: _parameterType(_member('pause')),
              runtime: runtime,
            ),
      null,
      runtime: runtime,
    );
  }

  @override
  void resume() => receiver.invoke('resume', 0, null, null, runtime: runtime);

  @override
  bool get isPaused =>
      TypedInterop.toBool(receiver.getProperty('isPaused', runtime: runtime));

  @override
  void onData(void Function(Object?)? handleData) => receiver.invoke(
    'onData',
    1,
    handleData == null
        ? null
        : _callback('onData', 1, (runtime, target, r, s, c) {
            handleData(r);
            return null;
          }),
    null,
    runtime: runtime,
  );

  @override
  void onError(Function? handleError) => receiver.invoke(
    'onError',
    1,
    handleError == null
        ? null
        : _callback('onError', 2, (runtime, target, r, s, c) {
            if (handleError is void Function(Object, StackTrace)) {
              handleError(
                r!,
                (s as $StackTrace?)?.$value ?? StackTrace.current,
              );
            } else {
              Function.apply(handleError, [r]);
            }
            return null;
          }),
    null,
    runtime: runtime,
  );

  @override
  void onDone(void Function()? handleDone) => receiver.invoke(
    'onDone',
    1,
    handleDone == null
        ? null
        : _callback('onDone', 0, (runtime, target, r, s, c) {
            handleDone();
            return null;
          }),
    null,
    runtime: runtime,
  );

  @override
  Future<E> asFuture<E>([E? futureValue]) =>
      _future(
        receiver.invoke(
          'asFuture',
          1,
          TypedInterop.boxExternal(futureValue, runtime: runtime),
          null,
          runtime: runtime,
        ),
      ).then<E>(
        (value) => TypedInterop.exportExternal(value, runtime: runtime) as E,
      );
}

final class _GuestHostIterable<T> extends Iterable<T> {
  _GuestHostIterable(this.receiver, this.runtime);
  final TypedInstance receiver;
  final Runtime runtime;

  @override
  Iterator<T> get iterator => TypedInterop.exportIterator<T>(
    TypedInterop.getProperty(runtime, receiver, 'iterator'),
    runtime,
  );
}

final class _ExportedIterator<T> implements Iterator<T> {
  _ExportedIterator(this.iterator, this.runtime);
  final Iterator<Object?> iterator;
  final Runtime runtime;

  @override
  bool moveNext() => iterator.moveNext();

  @override
  T get current =>
      TypedInterop.exportExternal(iterator.current, runtime: runtime) as T;
}

final class _GuestHostIterator<T> implements Iterator<T> {
  _GuestHostIterator(this.receiver, this.runtime);
  final Object? receiver;
  final Runtime runtime;

  @override
  bool moveNext() => TypedInterop.toBool(
    TypedInterop.invoke(runtime, receiver, 'moveNext', 0, null, null),
  );

  @override
  T get current =>
      TypedInterop.exportExternal(
            TypedInterop.getProperty(runtime, receiver, 'current'),
            runtime: runtime,
          )
          as T;
}

/// Explicit adapter for a native Dart function at the public host boundary.
final class TypedHostFunction extends EvalFunction {
  TypedHostFunction(this.function);
  final Function function;

  $Value? invokeHost(
    Runtime? runtime,
    List<$Value?> arguments, {
    Map<String, $Value?> named = const {},
  }) => TypedInterop.boxExternal(
    Function.apply(
      function,
      arguments
          .map((value) => TypedInterop.exportExternal(value, runtime: runtime))
          .toList(),
      named.isEmpty
          ? null
          : {
              for (final entry in named.entries)
                Symbol(entry.key): TypedInterop.exportExternal(
                  entry.value,
                  runtime: runtime,
                ),
            },
    ),
    runtime: runtime,
  );

  @override
  $Value? call(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) => invokeHost(runtime, TypedInterop.callableArgs(r, s, c));

  @override
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(CoreTypes.function);
}

/// Adds the structural checks missing from legacy [$Closure]/[$Function]
/// values when they enter through a typed export.
final class TypedCheckedFunction extends EvalFunction {
  TypedCheckedFunction(this.runtime, this.expectedType, this.function);

  final Runtime runtime;
  final int expectedType;
  final EvalFunction function;

  // Monomorphic cache: if every argument's runtime type matches the last
  // validated call, the structural argument check repeats a verdict that is
  // deterministic per (argument runtime type, expected descriptor) pair.
  List<int>? _lastArgTypeIds;

  @override
  $Value? call(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final args = TypedInterop.callableArgs(r, s, c);
    final last = _lastArgTypeIds;
    var hit = false;
    if (last != null && last.length == args.length) {
      hit = true;
      for (var i = 0; i < args.length; i++) {
        final arg = args[i];
        if ((arg == null ? -1 : arg.$getRuntimeType(this.runtime)) != last[i]) {
          hit = false;
          break;
        }
      }
    }
    if (!hit) {
      // Only a passing check seeds the cache; a throw stores nothing.
      this.runtime.assertTypedFunctionAdapterArguments(expectedType, args);
      _lastArgTypeIds = [
        for (final arg in args)
          arg == null ? -1 : arg.$getRuntimeType(this.runtime),
      ];
    }
    final result = function.call(this.runtime, target, r, s, c);
    return this.runtime.validateTypedFunctionAdapterResult(
      expectedType,
      result,
    );
  }

  @override
  int $getRuntimeType(Runtime runtime) => expectedType;
}
