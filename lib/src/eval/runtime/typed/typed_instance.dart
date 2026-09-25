import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/bridge/runtime_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

import 'typed_call_site.dart';
import 'typed_closure.dart';
import 'typed_class.dart';
import 'typed_function.dart';
import 'typed_interop.dart';
import 'typed_machine.g.dart';
import 'typed_program.dart';

Invocation _typedMethodInvocation(
  String name,
  int positionalCount,
  Object? first,
  Object? rest,
  List<String> namedNames,
  List<int> typeArguments,
  Runtime? runtime,
) {
  final count = positionalCount + namedNames.length;
  final values = TypedInterop.argList(count, first, rest);
  final namedArguments = {
    for (var i = 0; i < namedNames.length; i++)
      Symbol(namedNames[i]): values[positionalCount + i],
  };
  final arguments = values.sublist(0, positionalCount);
  return typeArguments.isEmpty
      ? Invocation.method(Symbol(name), arguments, namedArguments)
      : Invocation.genericMethod(
          Symbol(name),
          [for (final type in typeArguments) $TypeImpl(type, runtime)],
          arguments,
          namedArguments,
        );
}

/// An evaluated object whose members belong to a typed program.
final class TypedInstance implements $Instance {
  @pragma('vm:never-inline')
  TypedInstance(
    this.program,
    this.classId, [
    $Instance? superclass,
    this.runtime,
    this.runtimeTypeId,
  ]) : superclass = superclass is $Bridge
           ? Runtime.bridgeData[superclass]!.subclass
           : superclass,
       values = List<Object?>.filled(
         program.classes[classId].valueCount,
         null,
       ) {
    if (superclass is $Bridge) {
      final data = Runtime.bridgeData[superclass]!;
      Runtime.bridgeData[superclass] = BridgeData(
        data.runtime,
        data.$runtimeType,
        this,
      );
    }
    var parent = this.superclass;
    while (parent is TypedInstance) {
      parent._dispatchRoot = this;
      parent = parent.superclass;
    }
  }

  final TypedProgram program;
  final Runtime? runtime;
  final int classId;
  final $Instance? superclass;
  final List<Object?> values;
  TypedInstance? _dispatchRoot;
  final int? runtimeTypeId;
  final _members = <TypedMemberKind, Map<String, TypedMember?>>{};

  // Single-entry memo for $getRuntimeType, keyed on the runtime and the
  // dispatch root identity (the root can change when a subclass instance
  // links this object into its superclass chain).
  Runtime? _cachedTypeRuntime;
  TypedInstance? _cachedTypeRoot;
  int _cachedTypeId = -1;

  TypedClass get descriptor => program.classes[classId];
  TypedInstance get dispatchRoot => _dispatchRoot ?? this;

  $Value? _noSuchMethod(Invocation invocation, Runtime? runtime) {
    final handler = resolve(TypedMemberKind.method, 'noSuchMethod');
    if (handler != null) {
      return handler.invokeClosure(
        1,
        $Invocation.wrap(invocation),
        null,
        runtime: runtime,
      );
    }
    throw NoSuchMethodError.withInvocation(dispatchRoot, invocation);
  }

  /// Cache resolution separately from register argument transfer and frame entry.
  TypedMember? resolve(
    TypedMemberKind kind,
    String name, {
    String callerLibrary = '',
  }) {
    final root = dispatchRoot;
    final cache = root._members[kind] ??= {};
    final cacheKey = name.startsWith('_') ? '$callerLibrary::$name' : name;
    final cached = cache[cacheKey];
    if (cached != null || cache.containsKey(cacheKey)) return cached;
    var owner = root;
    while (true) {
      final members = switch (kind) {
        TypedMemberKind.method => owner.descriptor.methods,
        TypedMemberKind.getter => owner.descriptor.getters,
        TypedMemberKind.setter => owner.descriptor.setters,
      };
      final function = name.startsWith('_')
          ? members['$callerLibrary::$name'] ??
                (owner.descriptor.library == callerLibrary
                    ? members[name]
                    : null)
          : members[name];
      if (function != null) {
        return cache[cacheKey] = TypedMember(owner, function);
      }
      final parent = owner.superclass;
      if (parent is! TypedInstance) return cache[cacheKey] = null;
      owner = parent;
    }
  }

  /// Explicit host entry. Arguments travel in the register-call layout:
  /// [first] is argument 0 and [rest] is argument 1 when two arguments are
  /// supplied or a (borrowed) `List<Object?>` of arguments 1..count-1 for
  /// more. Typed bytecode calls enter their callee in the dispatch loop.
  $Value? invoke(
    String name,
    int positionalCount,
    Object? first,
    Object? rest, {
    List<String> namedNames = const [],
    String callerLibrary = '',
    List<int> typeArguments = const [],
    Runtime? runtime,
  }) {
    final member = resolve(
      TypedMemberKind.method,
      name,
      callerLibrary: callerLibrary,
    );
    if (member != null) {
      if (!member.accepts(positionalCount, namedNames) ||
          !member.acceptsTypeArguments(typeArguments)) {
        return _noSuchMethod(
          _typedMethodInvocation(
            name,
            positionalCount,
            first,
            rest,
            namedNames,
            typeArguments,
            runtime,
          ),
          runtime,
        );
      }
      return member.invokeClosure(
        positionalCount,
        first,
        rest,
        namedNames: namedNames,
        typeArguments: typeArguments,
        runtime: runtime,
      );
    }
    final getter = resolve(
      TypedMemberKind.getter,
      name,
      callerLibrary: callerLibrary,
    );
    if (getter != null) {
      final callable = getter.invoke(0, null, null, runtime: runtime);
      if (callable is TypedClosure) {
        if (!callable.acceptsTypeArguments(typeArguments)) {
          return _noSuchMethod(
            _typedMethodInvocation(
              name,
              positionalCount,
              first,
              rest,
              namedNames,
              typeArguments,
              runtime,
            ),
            runtime,
          );
        }
        return callable.invoke(
          positionalCount,
          first,
          rest,
          namedNames: namedNames,
          typeArguments: typeArguments,
          runtime: runtime,
        );
      }
      if (callable is TypedMember) {
        if (!callable.acceptsTypeArguments(typeArguments)) {
          return _noSuchMethod(
            _typedMethodInvocation(
              name,
              positionalCount,
              first,
              rest,
              namedNames,
              typeArguments,
              runtime,
            ),
            runtime,
          );
        }
        return callable.invokeClosure(
          positionalCount,
          first,
          rest,
          namedNames: namedNames,
          typeArguments: typeArguments,
          runtime: runtime,
        );
      }
      if (namedNames.isEmpty && typeArguments.isEmpty) {
        return TypedInterop.call(
          runtime,
          callable,
          positionalCount,
          first,
          rest,
        );
      }
      return _noSuchMethod(
        _typedMethodInvocation(
          name,
          positionalCount,
          first,
          rest,
          namedNames,
          typeArguments,
          runtime,
        ),
        runtime,
      );
    }
    var parent = superclass;
    while (parent is TypedInstance) {
      parent = parent.superclass;
    }
    if (parent != null) {
      if (namedNames.isNotEmpty) {
        throw UnsupportedError('Named bridge method arguments');
      }
      return TypedInterop.invoke(
        runtime,
        parent,
        name,
        positionalCount,
        first,
        rest,
      );
    }
    if (name == '==' || name == '!=') {
      if (namedNames.isNotEmpty) {
        throw ArgumentError('Unexpected named arguments');
      }
      if (positionalCount != 1) {
        throw ArgumentError('Expected one argument');
      }
      final other = first;
      final equal = identical(
        dispatchRoot,
        other is TypedInstance ? other.dispatchRoot : other,
      );
      return $bool(name == '==' ? equal : !equal);
    }
    if (name == 'toString' && positionalCount == 0 && namedNames.isEmpty) {
      return $String("Instance of '${dispatchRoot.descriptor.name}'");
    }
    return _noSuchMethod(
      _typedMethodInvocation(
        name,
        positionalCount,
        first,
        rest,
        namedNames,
        typeArguments,
        runtime,
      ),
      runtime,
    );
  }

  /// Bridge wrappers pass their declared ABI as one ordered argument vector,
  /// including values for named parameters. Reconstruct the guest call shape
  /// when a native method dispatches back into an evaluated override.
  $Value? invokeBridge(
    String name,
    List<$Value?> arguments, {
    Runtime? runtime,
  }) {
    final member = resolve(TypedMemberKind.method, name);
    if (member != null) {
      return member.invokeBridgeArguments(arguments, runtime: runtime);
    }
    final (first, rest) = TypedInterop.splitVector(arguments);
    return invoke(name, arguments.length, first, rest, runtime: runtime);
  }

  @override
  $Value? $getProperty(Runtime runtime, String identifier) =>
      getProperty(identifier, runtime: runtime);

  $Value? getProperty(
    String identifier, {
    String callerLibrary = '',
    Runtime? runtime,
  }) {
    final getter = resolve(
      TypedMemberKind.getter,
      identifier,
      callerLibrary: callerLibrary,
    );
    if (getter != null) {
      return getter.invoke(0, null, null, runtime: runtime);
    }
    final method = resolve(
      TypedMemberKind.method,
      identifier,
      callerLibrary: callerLibrary,
    );
    if (method != null) return method;
    var parent = superclass;
    while (parent is TypedInstance) {
      parent = parent.superclass;
    }
    if (parent != null && runtime != null) {
      return parent.$getProperty(runtime, identifier);
    }
    return switch (identifier) {
      'hashCode' => $int(identityHashCode(dispatchRoot)),
      '==' || '!=' || 'toString' => $Function(
        (runtime, target, r, s, c) => invoke(
          identifier,
          TypedInterop.callableCount(c),
          r,
          TypedInterop.callableRest(s, c),
          runtime: runtime,
        ),
      ),
      _ => _noSuchMethod(Invocation.getter(Symbol(identifier)), runtime),
    };
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) =>
      setProperty(identifier, value, runtime: runtime);

  void setProperty(
    String identifier,
    $Value? value, {
    String callerLibrary = '',
    Runtime? runtime,
  }) {
    final setter = resolve(
      TypedMemberKind.setter,
      identifier,
      callerLibrary: callerLibrary,
    );
    if (setter != null) {
      setter.invokeClosure(1, value, null, runtime: runtime);
      return;
    }
    var parent = superclass;
    while (parent is TypedInstance) {
      parent = parent.superclass;
    }
    if (parent != null && runtime != null) {
      parent.$setProperty(runtime, identifier, value ?? const $null());
      return;
    }
    _noSuchMethod(Invocation.setter(Symbol('$identifier='), value), runtime);
  }

  @override
  int $getRuntimeType(Runtime runtime) {
    final root = dispatchRoot;
    if (identical(_cachedTypeRuntime, runtime) &&
        identical(_cachedTypeRoot, root)) {
      return _cachedTypeId;
    }
    final origin = root.runtime;
    final typeId =
        root.runtimeTypeId ??
        (origin ?? runtime).lookupType(
          BridgeTypeSpec(root.descriptor.library, root.descriptor.name),
        );
    final resolved = origin == null
        ? typeId
        : runtime.importRuntimeType(origin, typeId);
    _cachedTypeRuntime = runtime;
    _cachedTypeRoot = root;
    _cachedTypeId = resolved;
    return resolved;
  }

  $Bridge? get bridge {
    var parent = superclass;
    while (parent is TypedInstance) {
      parent = parent.superclass;
    }
    return parent is BridgeSuperShim ? parent.bridge : null;
  }

  @override
  Object get $value =>
      bridge ?? (throw UnsupportedError('Typed instances have no host value'));

  @override
  Object get $reified => $value;
}

/// A resolved member also serves as an explicit bound method bridge adapter.
final class TypedMember extends EvalFunction {
  @override
  bool operator ==(Object other) =>
      other is TypedMember &&
      identical(receiver, other.receiver) &&
      functionId == other.functionId;

  @override
  int get hashCode => Object.hash(identityHashCode(receiver), functionId);

  TypedMember(this.receiver, this.functionId)
    : function = receiver.program.functions[functionId];

  final TypedInstance receiver;
  final int functionId;
  final TypedFunction function;
  late final TypedClosure? _closure = _bindClosure();

  bool accepts(int positionalCount, Iterable<String> namedNames) =>
      _closure?.descriptor.accepts(positionalCount, namedNames) ??
      namedNames.isEmpty;

  bool acceptsTypeArguments(List<int> typeArguments) =>
      _closure?.acceptsTypeArguments(typeArguments) ?? typeArguments.isEmpty;

  void checkExactArguments(
    int count,
    Object? first,
    Object? rest,
    Runtime? runtime, [
    List<int> typeArguments = const [],
  ]) =>
      _closure?.checkExactArguments(count, first, rest, runtime, typeArguments);

  TypedClosure? _bindClosure() {
    for (final descriptor in receiver.program.closures) {
      if (descriptor.functionId == functionId && descriptor.boundReceiver) {
        return TypedClosure.bind(
          receiver.program,
          descriptor,
          receiver,
          runtime: receiver.runtime,
        );
      }
    }
    return null;
  }

  $Value? invokeClosure(
    int positionalCount,
    Object? first,
    Object? rest, {
    List<String> namedNames = const [],
    List<int> typeArguments = const [],
    Runtime? runtime,
    bool trusted = false,
  }) {
    final closure = _closure;
    if (closure != null) {
      return closure.invoke(
        positionalCount,
        first,
        rest,
        namedNames: namedNames,
        typeArguments: typeArguments,
        runtime: runtime,
        trusted: trusted,
      );
    }
    if (namedNames.isNotEmpty) {
      throw UnsupportedError('Method has no named argument metadata');
    }
    return invoke(positionalCount, first, rest, runtime: runtime);
  }

  $Value? invokeBridgeArguments(List<$Value?> arguments, {Runtime? runtime}) {
    final closure = _closure;
    final (first, rest) = TypedInterop.splitVector(arguments);
    if (closure == null ||
        arguments.length != closure.descriptor.argumentCount) {
      return invokeClosure(arguments.length, first, rest, runtime: runtime);
    }
    // The vector is in declaration order, so its named tail already matches
    // the descriptor's names.
    return closure.invoke(
      closure.descriptor.positionalCount,
      first,
      rest,
      namedNames: closure.descriptor.namedNames,
      runtime: runtime,
    );
  }

  $Value? invoke(int count, Object? first, Object? rest, {Runtime? runtime}) {
    final result = TypedMachine.runRaw(
      receiver.program,
      entryFunction: functionId,
      objectArguments: [receiver, ...TypedInterop.argList(count, first, rest)],
      runtime: receiver.runtime ?? runtime,
    );
    return switch (function.resultKind) {
      null => null,
      TypedArgumentKind.integer => $int(result as int),
      TypedArgumentKind.doublePrecision => $double(result as double),
      TypedArgumentKind.boolean => $bool(result as bool),
      TypedArgumentKind.string => $String(result as String),
      TypedArgumentKind.object => result as $Value?,
    };
  }

  @override
  $Value? call(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) => invokeClosure(
    TypedInterop.callableCount(c),
    r,
    TypedInterop.callableRest(s, c),
    runtime: runtime,
  );

  @override
  int $getRuntimeType(Runtime runtime) {
    return _closure?.$getRuntimeType(runtime) ??
        runtime.lookupType(CoreTypes.function);
  }
}
