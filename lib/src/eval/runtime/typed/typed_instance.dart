import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/bridge/runtime_bridge.dart';
import 'package:dart_eval/src/eval/runtime/exception.dart';
import 'package:dart_eval/stdlib/core.dart';

import 'typed_call_site.dart';
import 'typed_closure.dart';
import 'typed_class.dart';
import 'typed_function.dart';
import 'typed_interop.dart';
import 'typed_machine.g.dart';
import 'typed_program.dart';

/// An evaluated object whose members belong to a typed program.
final class TypedInstance implements $Instance {
  @pragma('vm:never-inline')
  TypedInstance(
    this.program,
    this.classId, [
    $Instance? superclass,
    this.runtime,
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
  final _members = <TypedMemberKind, Map<String, TypedMember?>>{};

  TypedClass get descriptor => program.classes[classId];
  TypedInstance get dispatchRoot => _dispatchRoot ?? this;

  /// Cache resolution separately from register argument transfer and frame entry.
  TypedMember? resolve(TypedMemberKind kind, String name) {
    final root = dispatchRoot;
    final cache = root._members[kind] ??= {};
    final cached = cache[name];
    if (cached != null || cache.containsKey(name)) return cached;
    var owner = root;
    while (true) {
      final members = switch (kind) {
        TypedMemberKind.method => owner.descriptor.methods,
        TypedMemberKind.getter => owner.descriptor.getters,
        TypedMemberKind.setter => owner.descriptor.setters,
      };
      final function = members[name];
      if (function != null) {
        return cache[name] = TypedMember(owner, function);
      }
      final parent = owner.superclass;
      if (parent is! TypedInstance) return cache[name] = null;
      owner = parent;
    }
  }

  /// Explicit host entry. Arguments and results are canonical language values.
  /// Typed bytecode calls enter their callee in the current dispatch loop.
  $Value? invoke(String name, List<$Value?> arguments, {Runtime? runtime}) {
    final member = resolve(TypedMemberKind.method, name);
    if (member != null) return member.invoke(arguments, runtime: runtime);
    final getter = resolve(TypedMemberKind.getter, name);
    if (getter != null) {
      return TypedInterop.call(
        runtime,
        getter.invoke(const [], runtime: runtime),
        arguments,
      );
    }
    var parent = superclass;
    while (parent is TypedInstance) {
      parent = parent.superclass;
    }
    if (parent != null) {
      return TypedInterop.invoke(runtime, parent, name, arguments);
    }
    if (name == '==' || name == '!=') {
      if (arguments.length != 1) throw ArgumentError('Expected one argument');
      final other = arguments.single;
      final equal = identical(
        dispatchRoot,
        other is TypedInstance ? other.dispatchRoot : other,
      );
      return $bool(name == '==' ? equal : !equal);
    }
    if (name == 'toString' && arguments.isEmpty) {
      return $String("Instance of '${dispatchRoot.descriptor.name}'");
    }
    throw EvalUnknownPropertyException(name);
  }

  @override
  $Value? $getProperty(Runtime runtime, String identifier) =>
      getProperty(identifier, runtime: runtime);

  $Value? getProperty(String identifier, {Runtime? runtime}) {
    final getter = resolve(TypedMemberKind.getter, identifier);
    if (getter != null) return getter.invoke(const [], runtime: runtime);
    final method = resolve(TypedMemberKind.method, identifier);
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
      _ => throw EvalUnknownPropertyException(identifier),
    };
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) =>
      setProperty(identifier, value, runtime: runtime);

  void setProperty(String identifier, $Value? value, {Runtime? runtime}) {
    final setter = resolve(TypedMemberKind.setter, identifier);
    if (setter != null) {
      setter.invoke([value], runtime: runtime);
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
    throw EvalUnknownPropertyException(identifier);
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType(
    BridgeTypeSpec(
      dispatchRoot.descriptor.library,
      dispatchRoot.descriptor.name,
    ),
  );

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
    Runtime? runtime,
  }) {
    final closure = _closure;
    if (closure != null)
      return closure.invoke(arguments, named: named, runtime: runtime);
    if (named.isNotEmpty)
      throw UnsupportedError('Method has no named argument metadata');
    return invoke(arguments, runtime: runtime);
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
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(CoreTypes.function);
}
