import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
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
  TypedClosure._(this.program, this.descriptor, this.captures, this.runtime)
    : function = program.functions[descriptor.functionId];

  final TypedProgram program;
  final TypedClosureDescriptor descriptor;
  final TypedFunction function;
  final List<Object?> captures;
  final Runtime? runtime;

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
  }) => TypedClosure._(program, descriptor, [receiver], runtime);
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
    return TypedClosure._(program, descriptor, captures, runtime);
  }

  /// Exact calls need no argument vector, signature adapter or recursive Dart
  /// invocation. The hidden closure receiver already occupies R.
  @pragma('vm:never-inline')
  static TypedClosure? resolve(
    TypedProgram program,
    Object? receiver,
    int index,
    Runtime? runtime,
  ) {
    if (receiver is! TypedClosure ||
        !identical(receiver.program, program) ||
        (receiver.runtime != null && !identical(receiver.runtime, runtime))) {
      return null;
    }
    final descriptor = receiver.descriptor;
    if (!descriptor.hasEnvironment) return null;
    final site = program.closureCalls[index];
    if (site.positionalCount != descriptor.positionalCount ||
        site.namedNames.length != descriptor.namedNames.length) {
      return null;
    }
    for (var i = 0; i < site.namedNames.length; i++) {
      if (site.namedNames[i] != descriptor.namedNames[i]) return null;
    }
    return receiver;
  }

  @pragma('vm:never-inline')
  static $Value? invokeAt(
    TypedProgram program,
    Runtime? runtime,
    Object? receiver,
    Object? first,
    Object? rest,
    int index,
  ) {
    final site = program.closureCalls[index];
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
    final named = <String, $Value?>{
      for (var i = 0; i < site.namedNames.length; i++)
        site.namedNames[i]: values[site.positionalCount + i],
    };
    if (receiver is TypedClosure) {
      return receiver.invoke(
        values.sublist(0, site.positionalCount),
        named: named,
        runtime: runtime,
      );
    }
    if (receiver is TypedMember) {
      return receiver.invokeClosure(
        values.sublist(0, site.positionalCount),
        named: named,
        runtime: runtime,
      );
    }
    if (named.isNotEmpty) {
      if (receiver is TypedHostFunction) {
        return receiver.invokeHost(
          runtime,
          values.sublist(0, site.positionalCount),
          named: named,
        );
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
    Runtime? runtime,
  }) {
    final descriptor = this.descriptor;
    if (arguments.length < descriptor.requiredPositional ||
        arguments.length > descriptor.positionalCount) {
      throw ArgumentError('Invalid closure positional argument count');
    }
    for (final name in named.keys) {
      if (!descriptor.namedNames.contains(name)) {
        throw ArgumentError('Unknown closure argument $name');
      }
    }
    for (final name in descriptor.requiredNamed) {
      if (!named.containsKey(name)) {
        throw ArgumentError('Missing closure argument $name');
      }
    }
    final context = this.runtime ?? runtime;
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
        TypedEntry.direct(r: first, s: second, environment: captures),
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
      TypedEntry.fromValues(function, values, environment: captures),
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
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(CoreTypes.function);
}
