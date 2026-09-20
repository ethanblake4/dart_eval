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
              identical(captures.single, other.captures.single));

  @override
  int get hashCode => descriptor.hasEnvironment
      ? identityHashCode(this)
      : Object.hash(
          identityHashCode(program),
          identityHashCode(runtime),
          descriptor.functionId,
          descriptor.boundReceiver ? identityHashCode(captures.single) : null,
        );
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
  List<$Value?> get defaults =>
      _defaultArguments[descriptor] ??= List<$Value?>.unmodifiable([
        for (final value in [
          ...descriptor.positionalDefaults,
          ...descriptor.namedDefaults,
        ])
          TypedInterop.boxExternal(value),
      ]);

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
    if (receiver is! TypedClosure ||
        !identical(receiver.program, program) ||
        (receiver.runtime != null && !identical(receiver.runtime, runtime))) {
      return null;
    }
    final descriptor = receiver.descriptor;
    if (!descriptor.hasEnvironment) return null;
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
    if (site.trusted) {
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
    final values = switch (count) {
      0 => <$Value?>[],
      1 => <$Value?>[first as $Value?],
      2 => <$Value?>[first as $Value?, rest as $Value?],
      _ => <$Value?>[
        first as $Value?,
        for (var i = 0; i < count - 1; i++)
          (rest as List<Object?>)[i] as $Value?,
      ],
    };
    // The no-named-argument path is the hot one: `values` is already exactly
    // the positional vector and no named map needs to be materialized.
    final List<$Value?> positional;
    final Map<String, $Value?> named;
    if (site.namedNames.isEmpty) {
      positional = values;
      named = const <String, $Value?>{};
    } else {
      positional = values.sublist(0, site.positionalCount);
      named = <String, $Value?>{
        for (var i = 0; i < site.namedNames.length; i++)
          site.namedNames[i]: values[site.positionalCount + i],
      };
    }
    if (receiver is TypedClosure) {
      if (!receiver.descriptor.accepts(site.positionalCount, named.keys) ||
          !receiver.acceptsTypeArguments(typeArguments)) {
        throw NoSuchMethodError.withInvocation(
          receiver,
          Invocation.method(
            Symbol('call'),
            positional,
            {for (final entry in named.entries) Symbol(entry.key): entry.value},
          ),
        );
      }
      return receiver.invoke(
        positional,
        named: named,
        typeArguments: typeArguments,
        runtime: runtime,
        trusted: site.trusted,
      );
    }
    if (receiver is TypedMember) {
      if (!receiver.accepts(site.positionalCount, named.keys) ||
          !receiver.acceptsTypeArguments(typeArguments)) {
        throw NoSuchMethodError.withInvocation(
          receiver,
          Invocation.method(
            Symbol('call'),
            positional,
            {for (final entry in named.entries) Symbol(entry.key): entry.value},
          ),
        );
      }
      return receiver.invokeClosure(
        positional,
        named: named,
        typeArguments: typeArguments,
        runtime: runtime,
        trusted: site.trusted,
      );
    }
    if (named.isNotEmpty) {
      if (receiver is TypedHostFunction) {
        return receiver.invokeHost(runtime, positional, named: named);
      }
      throw UnsupportedError(
        'Named arguments require a typed closure or host function',
      );
    }
    return TypedInterop.call(runtime, receiver, values);
  }

  $Value? invoke(
    List<$Value?> arguments, {
    Map<String, $Value?> named = const {},
    List<int> typeArguments = const [],
    Runtime? runtime,
    bool trusted = false,
  }) {
    final descriptor = this.descriptor;
    if (!descriptor.accepts(arguments.length, named.keys) ||
        !acceptsTypeArguments(typeArguments)) {
      throw ArgumentError('Invalid closure positional argument count');
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
    if (arguments.isEmpty &&
        named.isEmpty &&
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
    final values = <Object?>[
      if (descriptor.hasEnvironment) this,
      if (descriptor.boundReceiver) captures.single,
      ...arguments,
      for (var i = arguments.length; i < descriptor.positionalCount; i++)
        defaults[i],
      for (var i = 0; i < descriptor.namedNames.length; i++)
        named.containsKey(descriptor.namedNames[i])
            ? named[descriptor.namedNames[i]]
            : defaults[descriptor.positionalCount + i],
    ];
    if (!trusted) {
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
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) =>
      invoke(args, runtime: runtime);
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
}
