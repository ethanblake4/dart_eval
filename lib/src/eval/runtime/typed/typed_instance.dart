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
  List<$Value?> arguments,
  Map<String, $Value?> named,
  List<int> typeArguments,
  Runtime? runtime,
) {
  final namedArguments = {
    for (final entry in named.entries) Symbol(entry.key): entry.value,
  };
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
      return handler.invokeClosure([
        $Invocation.wrap(invocation),
      ], runtime: runtime);
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
      final function = members[name];
      if (function != null &&
          (!name.startsWith('_') ||
              owner.descriptor.library == callerLibrary)) {
        return cache[cacheKey] = TypedMember(owner, function);
      }
      final parent = owner.superclass;
      if (parent is! TypedInstance) return cache[cacheKey] = null;
      owner = parent;
    }
  }

  /// Explicit host entry. Arguments and results are canonical language values.
  /// Typed bytecode calls enter their callee in the current dispatch loop.
  $Value? invoke(
    String name,
    List<$Value?> arguments, {
    Map<String, $Value?> named = const {},
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
      if (!member.accepts(arguments.length, named.keys) ||
          !member.acceptsTypeArguments(typeArguments)) {
        return _noSuchMethod(
          _typedMethodInvocation(
            name,
            arguments,
            named,
            typeArguments,
            runtime,
          ),
          runtime,
        );
      }
      return member.invokeClosure(
        arguments,
        named: named,
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
      final callable = getter.invoke(const [], runtime: runtime);
      if (callable is TypedClosure) {
        if (!callable.acceptsTypeArguments(typeArguments)) {
          return _noSuchMethod(
            _typedMethodInvocation(
              name,
              arguments,
              named,
              typeArguments,
              runtime,
            ),
            runtime,
          );
        }
        return callable.invoke(
          arguments,
          named: named,
          typeArguments: typeArguments,
          runtime: runtime,
        );
      }
      if (callable is TypedMember) {
        if (!callable.acceptsTypeArguments(typeArguments)) {
          return _noSuchMethod(
            _typedMethodInvocation(
              name,
              arguments,
              named,
              typeArguments,
              runtime,
            ),
            runtime,
          );
        }
        return callable.invokeClosure(
          arguments,
          named: named,
          typeArguments: typeArguments,
          runtime: runtime,
        );
      }
      if (named.isEmpty && typeArguments.isEmpty) {
        return TypedInterop.call(runtime, callable, arguments);
      }
      return _noSuchMethod(
        _typedMethodInvocation(name, arguments, named, typeArguments, runtime),
        runtime,
      );
    }
    var parent = superclass;
    while (parent is TypedInstance) {
      parent = parent.superclass;
    }
    if (parent != null) {
      if (named.isNotEmpty) {
        throw UnsupportedError('Named bridge method arguments');
      }
      return TypedInterop.invoke(runtime, parent, name, arguments);
    }
    if (name == '==' || name == '!=') {
      if (named.isNotEmpty) throw ArgumentError('Unexpected named arguments');
      if (arguments.length != 1) throw ArgumentError('Expected one argument');
      final other = arguments.single;
      final equal = identical(
        dispatchRoot,
        other is TypedInstance ? other.dispatchRoot : other,
      );
      return $bool(name == '==' ? equal : !equal);
    }
    if (name == 'toString' && arguments.isEmpty) {
      if (named.isNotEmpty) throw ArgumentError('Unexpected named arguments');
      return $String("Instance of '${dispatchRoot.descriptor.name}'");
    }
    return _noSuchMethod(
      _typedMethodInvocation(name, arguments, named, typeArguments, runtime),
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
    return member == null
        ? invoke(name, arguments, runtime: runtime)
        : member.invokeBridgeArguments(arguments, runtime: runtime);
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
    if (getter != null) return getter.invoke(const [], runtime: runtime);
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
        (runtime, target, arguments) =>
            invoke(identifier, arguments, runtime: runtime),
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
      setter.invokeClosure([value], runtime: runtime);
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
    List<$Value?> arguments, {
    Map<String, $Value?> named = const {},
    List<int> typeArguments = const [],
    Runtime? runtime,
    bool trusted = false,
  }) {
    final closure = _closure;
    if (closure != null) {
      return closure.invoke(
        arguments,
        named: named,
        typeArguments: typeArguments,
        runtime: runtime,
        trusted: trusted,
      );
    }
    if (named.isNotEmpty) {
      throw UnsupportedError('Method has no named argument metadata');
    }
    return invoke(arguments, runtime: runtime);
  }

  $Value? invokeBridgeArguments(List<$Value?> arguments, {Runtime? runtime}) {
    final closure = _closure;
    if (closure == null ||
        arguments.length != closure.descriptor.argumentCount) {
      return invokeClosure(arguments, runtime: runtime);
    }
    final positionalCount = closure.descriptor.positionalCount;
    return closure.invoke(
      arguments.sublist(0, positionalCount),
      named: {
        for (var i = 0; i < closure.descriptor.namedNames.length; i++)
          closure.descriptor.namedNames[i]: arguments[positionalCount + i],
      },
      runtime: runtime,
    );
  }

  $Value? invoke(List<$Value?> arguments, {Runtime? runtime}) {
    final result = TypedMachine.runRaw(
      receiver.program,
      entryFunction: functionId,
      objectArguments: [receiver, ...arguments],
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
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) =>
      invokeClosure(args, runtime: runtime);

  @override
  int $getRuntimeType(Runtime runtime) {
    return _closure?.$getRuntimeType(runtime) ??
        runtime.lookupType(CoreTypes.function);
  }
}
