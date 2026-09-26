import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'typed_closure_descriptor.dart';
import 'typed_frame.dart';
import 'typed_function.dart';
import 'typed_interop.dart';
import 'typed_instance.dart';
import 'typed_machine.g.dart';
import 'typed_program.dart';

/// A captured binding stores its compiler-selected native representation.
final class TypedCaptureCell {
  TypedCaptureCell(this.value);
  Object? value;
}

/// An escaping closure owns its environment, independently of cached VM frames.
final class TypedClosure extends EvalFunction {
  TypedClosure._(
    this.program,
    this.descriptor,
    this.captures,
    this.runtime,
    this.definingTypeEnvironmentReceiver,
    List<int> definingTypeArguments,
  ) : definingTypeArguments = List.unmodifiable(definingTypeArguments),
      function = program.functions[descriptor.functionId];

  final TypedProgram program;
  final TypedClosureDescriptor descriptor;
  final TypedFunction function;
  final List<Object?> captures;
  final Runtime? runtime;
  final Object? definingTypeEnvironmentReceiver;
  final List<int> definingTypeArguments;
  int? _resolvedRuntimeTypeId;

  // Bound methods with a boxed ABI can use the closure entry path by supplying
  // their receiver in place of its hidden environment argument.
  late final bool _canEnterBound =
      !descriptor.hasEnvironment &&
      descriptor.boundReceiver &&
      function.argumentKinds.length == descriptor.argumentCount + 1 &&
      function.argumentKinds.every((kind) => kind == TypedArgumentKind.object) &&
      (function.resultKind == null ||
          function.resultKind == TypedArgumentKind.object);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypedClosure &&
          identical(program, other.program) &&
          identical(runtime, other.runtime) &&
          descriptor.functionId == other.descriptor.functionId &&
          !descriptor.hasEnvironment &&
          !other.descriptor.hasEnvironment &&
          descriptor.boundReceiver == other.descriptor.boundReceiver &&
          (!descriptor.boundReceiver ||
              identical(captures.single, other.captures.single)) ||
      other is TypedClosure &&
          _adapterEquals(other) ||
      other is TypedMember &&
          descriptor.boundReceiver &&
          descriptor.functionId == other.functionId &&
          identical(captures.single, other.receiver);

  /// Instantiation adapters (`f<X>` torn off under an enclosing generic and
  /// `f<int>` torn off directly) get distinct function ids but are the same
  /// value when they forward the same callable at the same signature.
  bool _adapterEquals(TypedClosure other) =>
      descriptor.isInstantiationAdapter &&
      other.descriptor.isInstantiationAdapter &&
      captures.single == other.captures.single &&
      _equalityTypeId == other._equalityTypeId;

  int get _equalityTypeId {
    final runtime = this.runtime;
    if (runtime == null) return descriptor.runtimeTypeId;
    return _resolvedRuntimeTypeId ??= _resolveRuntimeType(runtime);
  }

  @override
  int get hashCode {
    if (descriptor.hasEnvironment && !descriptor.isInstantiationAdapter) {
      return identityHashCode(this);
    }
    if (descriptor.isInstantiationAdapter) {
      return Object.hash(captures.single, _equalityTypeId);
    }
    // Match [TypedMember]: a bound tear-off produced by `x.m` and a bound
    // closure created directly must hash alike for canonicalization.
    if (descriptor.boundReceiver) {
      return Object.hash(identityHashCode(captures.single), descriptor.functionId);
    }
    return Object.hash(
      identityHashCode(program),
      identityHashCode(runtime),
      descriptor.functionId,
      null,
    );
  }
  static TypedClosure bind(
    TypedProgram program,
    TypedClosureDescriptor descriptor,
    Object receiver, {
    Runtime? runtime,
  }) => TypedClosure._(
    program,
    descriptor,
    [receiver],
    runtime,
    receiver,
    const [],
  );
  static final _defaultArguments = Expando<List<$Value?>>();

  // Scalar constant conversion happens once per compiler descriptor, never on
  // the exact-call path or repeatedly for each omitted-argument invocation.
  // Thunk-produced defaults (closures, const objects) belong to a runtime, so
  // they're memoized per closure instance instead of per shared descriptor.
  List<$Value?>? _resolvedDefaults;

  List<$Value?> get defaults {
    final thunks = descriptor.defaultThunks;
    if (thunks.isEmpty) {
      return _defaultArguments[descriptor] ??= List<$Value?>.unmodifiable([
        for (final value in [
          ...descriptor.positionalDefaults,
          ...descriptor.namedDefaults,
        ])
          TypedInterop.boxExternal(value),
      ]);
    }
    return _resolvedDefaults ??= List<$Value?>.unmodifiable([
      for (final (index, value) in [
        ...descriptor.positionalDefaults,
        ...descriptor.namedDefaults,
      ].indexed)
        index < thunks.length && thunks[index] >= 0
            ? TypedInterop.boxExternal(
                TypedMachine.runRaw(
                  program,
                  entryFunction: thunks[index],
                  runtime: runtime,
                ),
              )
            : TypedInterop.boxExternal(value),
    ]);
  }

  @pragma('vm:never-inline')
  static TypedClosure create(
    TypedProgram program,
    int index,
    List<Object?> outgoing,
    Runtime? runtime,
    Object? definingTypeEnvironmentReceiver,
    List<int> definingTypeArguments,
  ) {
    final descriptor = program.closures[index];
    final captures = descriptor.captureCount == 0
        ? const <Object?>[]
        : List<Object?>.generate(
            descriptor.captureCount,
            (i) => outgoing[i],
            growable: false,
          );
    if (descriptor.captureCount > 0) {
      outgoing.fillRange(0, descriptor.captureCount, null);
    }
    return TypedClosure._(
      program,
      descriptor,
      captures,
      runtime,
      definingTypeEnvironmentReceiver,
      definingTypeArguments,
    );
  }

  /// Exact calls need no argument vector, signature adapter or recursive Dart
  /// invocation. The hidden closure receiver already occupies R.
  @pragma('vm:never-inline')
  static TypedClosure? resolve(
    TypedProgram program,
    Object? receiver,
    int index,
    Runtime? runtime,
    Object? first,
    Object? rest, [
    List<int>? resolvedTypeArguments,
  ]) {
    if (receiver is TypedMember) receiver = receiver.boundClosure;
    if (receiver is! TypedClosure ||
        !identical(receiver.program, program) ||
        (receiver.runtime != null && !identical(receiver.runtime, runtime))) {
      return null;
    }
    final descriptor = receiver.descriptor;
    if (!descriptor.hasEnvironment && !receiver._canEnterBound) return null;
    final site = program.closureCalls[index];
    final typeArguments = resolvedTypeArguments ?? site.typeArguments;
    if (site.positionalCount != descriptor.positionalCount ||
        site.namedNames.length != descriptor.namedNames.length ||
        !receiver.acceptsTypeArguments(typeArguments)) {
      return null;
    }
    for (var i = 0; i < site.namedNames.length; i++) {
      if (site.namedNames[i] != descriptor.namedNames[i]) return null;
    }
    if (site.trusted &&
        (runtime == null || !descriptor.needsCovariantParameterChecks)) {
      receiver._checkTypeArguments(typeArguments, runtime);
    } else {
      receiver.checkExactArguments(
        descriptor.argumentCount,
        first,
        rest,
        runtime,
        typeArguments,
      );
    }
    return receiver;
  }

  void checkExactArguments(
    int count,
    Object? first,
    Object? rest,
    Runtime? runtime, [
    List<int> typeArguments = const [],
  ]) {
    _checkTypeArguments(typeArguments, runtime);
    final ownerType = _checkedOwnerType(runtime);
    for (var i = 0; i < descriptor.parameterTypeIds.length; i++) {
      final value = i == 0
          ? first
          : count == 2
          ? rest
          : (rest as List<Object?>)[i - 1];
      _checkArgument(value, i, runtime, typeArguments, ownerType);
    }
  }

  /// The checked-argument owner resolves once per call rather than per
  /// parameter; its runtime type is stable for the receiver's lifetime.
  /// Returns null when no parameter actually requires a runtime type check.
  int? _checkedOwnerType(Runtime? runtime) {
    if (runtime == null) return null;
    for (var i = 0; i < descriptor.parameterTypeIds.length; i++) {
      if (descriptor.parameterTypeIds[i] >= 0) {
        final typeReceiver = descriptor.boundReceiver
            ? captures.single
            : definingTypeEnvironmentReceiver;
        return typeReceiver is TypedInstance
            ? typeReceiver.dispatchRoot.$getRuntimeType(runtime)
            : null;
      }
    }
    return null;
  }

  bool acceptsTypeArguments(List<int> typeArguments) =>
      typeArguments.isEmpty ||
      typeArguments.length == descriptor.typeParameterBounds.length;

  void _checkTypeArguments(List<int> typeArguments, Runtime? runtime) {
    if (typeArguments.isEmpty || runtime == null) return;
    final typeReceiver = descriptor.boundReceiver
        ? captures.single
        : definingTypeEnvironmentReceiver;
    final ownerType = typeReceiver is TypedInstance
        ? typeReceiver.dispatchRoot.$getRuntimeType(runtime)
        : null;
    runtime.assertTypedTypeArguments(
      typeArguments,
      descriptor.typeParameterBounds,
      actualOwnerType: ownerType,
    );
  }

  void _checkArgument(
    Object? value,
    int index,
    Runtime? runtime,
    List<int> typeArguments,
    int? ownerType,
  ) {
    final typeId = descriptor.parameterTypeIds[index];
    if (typeId < 0) return;
    if (runtime != null) {
      if (!runtime.isTypedValueTypeInCallableEnvironment(
        value,
        typeId,
        typeArguments.isEmpty ? definingTypeArguments : typeArguments,
        actualOwnerType: ownerType,
      )) {
        throw TypeError();
      }
      return;
    }
    if (value == null) {
      if (!descriptor.parameterNullable[index]) {
        throw TypeError();
      }
      return;
    }
    // Direct TypedProgram execution has no Runtime metadata. Preserve that
    // low-level API's existing behavior; Runtime entrypoints always provide
    // the descriptor service used for language-level checked invocation.
  }

  @pragma('vm:never-inline')
  static $Value? invokeAt(
    TypedProgram program,
    Runtime? runtime,
    Object? receiver,
    Object? first,
    Object? rest,
    int index, [
    List<int>? resolvedTypeArguments,
  ]) {
    final site = program.closureCalls[index];
    final typeArguments = resolvedTypeArguments ?? site.typeArguments;
    final count = site.positionalCount + site.namedNames.length;
    if (receiver is TypedClosure) {
      if (!receiver.descriptor.accepts(site.positionalCount, site.namedNames) ||
          !receiver.acceptsTypeArguments(typeArguments)) {
        throw NoSuchMethodError.withInvocation(
          receiver,
          _callInvocation(count, first, rest, site),
        );
      }
      return receiver.invoke(
        site.positionalCount,
        first,
        rest,
        namedNames: site.namedNames,
        typeArguments: typeArguments,
        runtime: runtime,
        trusted: site.trusted,
      );
    }
    if (receiver is TypedInstance) {
      return receiver.invoke(
        'call',
        site.positionalCount,
        first,
        rest,
        namedNames: site.namedNames,
        typeArguments: typeArguments,
        runtime: runtime,
      );
    }
    if (receiver is TypedMember) {
      if (!receiver.accepts(site.positionalCount, site.namedNames) ||
          !receiver.acceptsTypeArguments(typeArguments)) {
        throw NoSuchMethodError.withInvocation(
          receiver,
          _callInvocation(count, first, rest, site),
        );
      }
      return receiver.invokeClosure(
        site.positionalCount,
        first,
        rest,
        namedNames: site.namedNames,
        typeArguments: typeArguments,
        runtime: runtime,
        trusted: site.trusted,
      );
    }
    if (site.namedNames.isNotEmpty) {
      if (receiver is TypedHostFunction) {
        final values = TypedInterop.argList(count, first, rest);
        return receiver.invokeHost(
          runtime,
          values.sublist(0, site.positionalCount),
          named: {
            for (var i = 0; i < site.namedNames.length; i++)
              site.namedNames[i]: values[site.positionalCount + i],
          },
        );
      }
      throw UnsupportedError(
        'Named arguments require a typed closure or host function',
      );
    }
    return TypedInterop.call(runtime, receiver, count, first, rest);
  }

  static Invocation _callInvocation(
    int count,
    Object? first,
    Object? rest,
    TypedClosureCall site,
  ) {
    final values = TypedInterop.argList(count, first, rest);
    return Invocation.method(
      Symbol('call'),
      values.sublist(0, site.positionalCount),
      {
        for (var i = 0; i < site.namedNames.length; i++)
          Symbol(site.namedNames[i]): values[site.positionalCount + i],
      },
    );
  }

  /// Invoke with a register call vector: [first] is argument 0 and [rest] is
  /// argument 1 when `positionalCount + namedNames.length` is 2, or a
  /// borrowed `List<Object?>` of arguments 1..count-1 for more. Named values
  /// sit after positionals in the order of [namedNames]; when the call site
  /// names match the declaration order no map is materialized.
  $Value? invoke(
    int positionalCount,
    Object? first,
    Object? rest, {
    List<String> namedNames = const [],
    List<int> typeArguments = const [],
    Runtime? runtime,
    bool trusted = false,
  }) {
    final descriptor = this.descriptor;
    final count = positionalCount + namedNames.length;
    if (!descriptor.accepts(positionalCount, namedNames) ||
        !acceptsTypeArguments(typeArguments)) {
      // Calling a closure with an unsatisfiable signature is a
      // noSuchMethod on its `call` member.
      final values = TypedInterop.argList(count, first, rest);
      throw NoSuchMethodError.withInvocation(
        this,
        Invocation.method(
          Symbol('call'),
          values.sublist(0, positionalCount),
          {
            for (var i = 0; i < namedNames.length; i++)
              Symbol(namedNames[i]): values[positionalCount + i],
          },
        ),
      );
    }
    final context = this.runtime ?? runtime;
    final effectiveTypeArguments =
        this.runtime != null &&
            runtime != null &&
            !identical(this.runtime, runtime)
        ? [
            for (final type in typeArguments)
              this.runtime!.importRuntimeType(runtime, type),
          ]
        : typeArguments;
    _checkTypeArguments(effectiveTypeArguments, context);
    final hiddenCount =
        (descriptor.hasEnvironment ? 1 : 0) +
        (descriptor.boundReceiver ? 1 : 0);
    assert(
      function.argumentKinds
          .take(hiddenCount)
          .every((kind) => kind == TypedArgumentKind.object),
    );
    if (count == 0 &&
        descriptor.positionalCount == 0 &&
        descriptor.namedNames.isEmpty &&
        function.argumentKinds.length == hiddenCount) {
      final Object? first = descriptor.hasEnvironment
          ? this
          : descriptor.boundReceiver
          ? captures.single
          : null;
      final Object? second =
          descriptor.hasEnvironment && descriptor.boundReceiver
          ? captures.single
          : null;
      return _run(
        TypedEntry.direct(
          r: first,
          s: second,
          environment: captures,
          typeEnvironmentReceiver: descriptor.boundReceiver
              ? captures.single
              : null,
          typeArguments: effectiveTypeArguments,
          lexicalTypeEnvironmentReceiver: definingTypeEnvironmentReceiver,
          lexicalTypeArguments: definingTypeArguments,
        ),
        context,
      );
    }
    Object? slot(int i) => i == 0
        ? first
        : count == 2
        ? rest
        : (rest as List<Object?>)[i - 1];
    final declNames = descriptor.namedNames;
    var namesInOrder = namedNames.length == declNames.length;
    if (namesInOrder) {
      for (var i = 0; i < namedNames.length; i++) {
        if (namedNames[i] != declNames[i]) {
          namesInOrder = false;
          break;
        }
      }
    }
    Object? namedValue(int i) {
      var supplied = namesInOrder ? i : -1;
      if (!namesInOrder) {
        for (var j = 0; j < namedNames.length; j++) {
          if (namedNames[j] == declNames[i]) {
            supplied = j;
            break;
          }
        }
      }
      return supplied < 0
          ? defaults[descriptor.positionalCount + i]
          : slot(positionalCount + supplied);
    }

    final values = <Object?>[
      if (descriptor.hasEnvironment) this,
      if (descriptor.boundReceiver) captures.single,
      for (var i = 0; i < positionalCount; i++) slot(i),
      for (var i = positionalCount; i < descriptor.positionalCount; i++)
        defaults[i],
      for (var i = 0; i < declNames.length; i++) namedValue(i),
    ];
    // Trusted sites skip the argument check — except bound method tear-offs
    // whose erased (covariant) parameters hide the callee's real contract.
    if (!trusted ||
        (context != null && descriptor.needsCovariantParameterChecks)) {
      final ownerType = _checkedOwnerType(context);
      for (var i = 0; i < descriptor.parameterTypeIds.length; i++) {
        _checkArgument(
          values[hiddenCount + i],
          i,
          context,
          effectiveTypeArguments,
          ownerType,
        );
      }
    }
    for (var i = 0; i < values.length; i++) {
      values[i] = switch (function.argumentKinds[i]) {
        TypedArgumentKind.integer => (values[i] as $int).$value,
        TypedArgumentKind.doublePrecision => (values[i] as $double).$value,
        TypedArgumentKind.boolean => (values[i] as $bool).$value,
        TypedArgumentKind.string => (values[i] as $String).$value,
        TypedArgumentKind.object => values[i],
      };
    }
    return _run(
      TypedEntry.fromValues(
        function,
        values,
        environment: captures,
        typeEnvironmentReceiver: descriptor.boundReceiver
            ? captures.single
            : null,
        typeArguments: effectiveTypeArguments,
        lexicalTypeEnvironmentReceiver: definingTypeEnvironmentReceiver,
        lexicalTypeArguments: definingTypeArguments,
      ),
      context,
    );
  }

  $Value? _run(TypedEntry entry, Runtime? context) {
    final result = TypedMachine.runEntry(
      program,
      entry,
      descriptor.functionId,
      runtime: context,
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
  ) => invoke(
    TypedInterop.callableCount(c),
    r,
    TypedInterop.callableRest(s, c),
    runtime: runtime,
  );
  @override
  int $getRuntimeType(Runtime runtime) {
    if (descriptor.runtimeTypeId < 0) {
      return runtime.lookupType(CoreTypes.function);
    }
    final definingRuntime = this.runtime ?? runtime;
    final resolved = this.runtime == null
        ? _resolveRuntimeType(definingRuntime)
        : _resolvedRuntimeTypeId ??= _resolveRuntimeType(definingRuntime);
    return runtime.importRuntimeType(definingRuntime, resolved);
  }

  int _resolveRuntimeType(Runtime runtime) {
    final typeReceiver = descriptor.boundReceiver
        ? captures.single
        : definingTypeEnvironmentReceiver;
    final ownerType = typeReceiver is TypedInstance
        ? typeReceiver.dispatchRoot.$getRuntimeType(runtime)
        : null;
    return runtime.resolveTypedEnvironmentType(
      descriptor.runtimeTypeId,
      actualOwnerType: ownerType,
      // A generic callable owns its callable parameter slots. Resolving them
      // with an enclosing callable's arguments would conflate two owners.
      callableTypeArguments: descriptor.typeParameterBounds.isEmpty
          ? definingTypeArguments
          : const [],
    );
  }

  /// Materialize this closure as a host Dart [Function] so bridge signatures
  /// like `void Function()` can consume it. Only positional-argument shapes
  /// up to five parameters are representable: a Dart closure with named
  /// parameters cannot be synthesized dynamically.
  @override
  Object get $reified {
    if (descriptor.namedNames.isNotEmpty) {
      throw UnimplementedError(
        'dart_eval cannot reify a closure with named parameters',
      );
    }
    Object? run(List<Object?> args) => TypedInterop.exportExternal(
      invoke(
        args.length,
        args.isEmpty ? null : args[0],
        switch (args.length) {
          0 || 1 => null,
          2 => args[1],
          _ => args.sublist(1),
        },
        runtime: runtime,
      ),
      runtime: runtime,
    );
    return switch (descriptor.positionalCount) {
      0 => () => run(const []),
      1 => (Object? a) => run([a]),
      2 => (Object? a, Object? b) => run([a, b]),
      3 => (Object? a, Object? b, Object? c) => run([a, b, c]),
      4 => (Object? a, Object? b, Object? c, Object? d) => run([a, b, c, d]),
      5 => (Object? a, Object? b, Object? c, Object? d, Object? e) =>
        run([a, b, c, d, e]),
      _ => throw UnimplementedError(
          'dart_eval cannot reify a closure with '
          '${descriptor.positionalCount} positional parameters',
        ),
    };
  }
}
