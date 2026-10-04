import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:dart_eval/stdlib/async.dart' show $TimeoutException;
import 'package:dart_eval/stdlib/typed_data.dart';
import 'package:dart_eval/src/eval/runtime/record.dart';
import 'package:dart_eval/src/eval/shared/stdlib/isolate/ports.dart';
import 'package:dart_eval/src/eval/shared/stdlib/isolate/isolate.dart';
import 'typed_closure.dart';
import 'typed_collections.dart';
import 'typed_instance.dart';
import 'typed_late_field.dart';
import 'typed_late_local.dart';
import 'typed_native_list.dart';
import 'typed_native_map.dart';
import 'typed_type_environment.dart';

/// A same-program heap snapshot. Only indexed nodes, integer type descriptors,
/// primitives and explicitly allowed VM resources cross the native boundary.
/// Constructors and global initializers are never replayed while hydrating.
final class TypedTransfer {
  static const marker = 'dart_eval.guest.graph.1';
  static final _identities = Expando<int>();
  static final Type _sendPortType = _nativeSendPortType();
  static final Type _capabilityType = Capability().runtimeType;

  static Type _nativeSendPortType() {
    final port = RawReceivePort();
    final type = port.sendPort.runtimeType;
    port.close();
    return type;
  }

  /// SDK SendPort is an interface; a custom implementation is not a VM handle.
  static SendPort? nativeSendPort(Object? value) {
    if (value == null) return null;
    if (value is SendPort && value.runtimeType == _sendPortType) return value;
    throw UnsupportedError('Guest isolates require a native VM SendPort');
  }

  static List<Object?> encode(Runtime runtime, Object? value) {
    final encoder = _Encoder(runtime);
    final root = encoder.ref(value);
    return [
      marker,
      _programIdentity(runtime),
      runtime.guestIsolateTypes(),
      root,
      encoder.nodes,
    ];
  }

  static Object? decode(Runtime runtime, Object? message) {
    if (message is! List || message.isEmpty || message.first != marker) {
      // VM control notifications are native null or [error, stack] messages.
      return runtime.wrapAlways(message, recursive: true);
    }
    if (message.length != 5 || message[1] != _programIdentity(runtime)) {
      throw UnsupportedError(
        'Guest messages require the same compiled program',
      );
    }
    final types = runtime.importGuestIsolateTypes(
      (message[2] as List).cast<Object?>(),
    );
    return _Decoder(
      runtime,
      types,
      (message[4] as List).cast<List>(),
    ).ref(message[3] as int);
  }

  static int _programIdentity(Runtime runtime) {
    final bytes = runtime.guestIsolateProgram();
    final cached = _identities[runtime];
    if (cached != null) return cached;
    var hash = 0x811c9dc5;
    for (final byte in bytes) {
      hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
    }
    return _identities[runtime] = hash;
  }
}

final class _Encoder {
  _Encoder(this.runtime);
  final Runtime runtime;
  final ids = HashMap<Object, int>.identity();
  final nodes = <List<Object?>>[];
  final activeNativeErrors = HashSet<List<Object?>>.identity();

  int ref(Object? value) {
    if (value != null && ids.containsKey(value)) {
      final id = ids[value]!;
      if (activeNativeErrors.contains(nodes[id])) {
        throw UnsupportedError(
          'Cyclic native error state cannot be transferred',
        );
      }
      return id;
    }
    final id = nodes.length;
    if (value != null) ids[value] = id;
    final node = <Object?>[];
    nodes.add(node);
    if (value == null || value is num || value is bool || value is String) {
      node.addAll(['scalar', value]);
    } else if (value is TypedCaptureCell) {
      node.addAll(['cell', ref(value.value)]);
    } else if (identical(value, TypedLateField.uninitialized)) {
      node.add('late-field-uninitialized');
    } else if (value is TypedLateLocal) {
      node.addAll([
        'late-local',
        value.name,
        value.isFinal,
        value.isInitialized,
        ref(value.snapshotValue),
        ref(value.initializer),
      ]);
    } else if (value is TypedMember) {
      node.addAll(['member', ref(value.receiver), value.functionId]);
    } else if (value is TypedClosure) {
      if (!identical(value.program, runtime.guestIsolateTypedProgram) ||
          value.runtime != null && !identical(value.runtime, runtime)) {
        throw UnsupportedError('Cannot transfer a foreign guest closure');
      }
      final index = value.program.closures.indexOf(value.descriptor);
      node.addAll([
        'closure',
        index,
        value.descriptor.functionId,
        value.captures.map(ref).toList(),
        ref(value.definingTypeEnvironmentReceiver),
        value.definingTypeArguments,
        environment(value.definingTypeEnvironment),
        value.$getRuntimeType(runtime),
        value.definingTypeEnvironmentReceiver is int,
      ]);
    } else if (value is TypedInstance) {
      if (!identical(value.program, runtime.guestIsolateTypedProgram) ||
          value.runtime != null && !identical(value.runtime, runtime)) {
        throw UnsupportedError('Cannot transfer a foreign guest instance');
      }
      if (value.superclass != null && value.superclass is! TypedInstance) {
        throw UnsupportedError('Cannot transfer native superclass state');
      }
      node.addAll([
        'instance',
        value.classId,
        value.runtimeTypeId,
        ref(value.superclass),
        value.values.map(ref).toList(),
        ref(value.dispatchRoot),
      ]);
    } else if (value is $Record) {
      node.addAll([
        'record',
        value.$getRuntimeType(runtime),
        value.mapping,
        value.fields.map(ref).toList(),
      ]);
    } else if (value is $List || value is $Map || value is $Set) {
      final wrapper = value as $Value;
      final raw = wrapper.$value;
      final type = wrapper.$getRuntimeType(runtime);
      final frozen = runtime.guestIsolateConstCollection(raw as Object);
      if (raw is List) {
        node.addAll([
          'list',
          type,
          raw.map(ref).toList(),
          (value as $List).isolateGrowable,
          frozen || value.isolateReadOnly || raw is UnmodifiableListView,
        ]);
      } else if (raw is Map) {
        node.addAll([
          'map',
          type,
          [
            for (final e in raw.entries) [ref(e.key), ref(e.value)],
          ],
          frozen || raw is UnmodifiableMapView,
          frozen,
        ]);
      } else {
        node.addAll([
          'set',
          type,
          (raw as Set).map(ref).toList(),
          frozen || raw is UnmodifiableSetView,
          frozen,
          (value as $Set).isolateIdentity,
        ]);
      }
    } else if (value is $TypeImpl) {
      node.addAll(['type', value.typeIdIn(runtime)]);
    } else if (value is $Value) {
      final raw = value.$value;
      if (raw == null || raw is num || raw is bool || raw is String) {
        node.addAll(['boxed', raw]);
      } else {
        native(node, raw, true);
      }
    } else {
      native(node, value, false);
    }
    return id;
  }

  Object? environment(TypedTypeEnvironment? value) => value == null
      ? null
      : [value.owners, value.arguments, environment(value.parent)];

  void native(List<Object?> node, Object? value, bool boxed) {
    if (value is TimeoutException) {
      node.addAll(['timeout', boxed, value.message, ref(value.duration)]);
      return;
    }
    if (value is DateTime) {
      node.addAll([
        'datetime',
        boxed,
        value.microsecondsSinceEpoch,
        value.isUtc,
      ]);
      return;
    }
    if (value is Duration) {
      node.addAll(['duration', boxed, value.inMicroseconds]);
      return;
    }
    if (value is StateError ||
        value is UnsupportedError ||
        value is UnimplementedError ||
        value is FormatException ||
        value is ArgumentError ||
        value is RemoteError ||
        value is TypeError ||
        value is AssertionError) {
      activeNativeErrors.add(node);
      final kind = switch (value) {
        StateError() => 'state',
        UnimplementedError() => 'unimplemented',
        UnsupportedError() => 'unsupported',
        FormatException() => 'format',
        RangeError() => 'range',
        ArgumentError() => 'argument',
        RemoteError() => 'remote',
        TypeError() => 'type',
        _ => 'assertion',
      };
      node.addAll([
        'error',
        boxed,
        kind,
        value.toString(),
        value is Error ? value.stackTrace?.toString() : null,
        value is StateError
            ? value.message
            : value is UnsupportedError
            ? value.message
            : value is UnimplementedError
            ? value.message
            : value is FormatException
            ? value.message
            : null,
        if (value is FormatException) [ref(value.source), value.offset],
        if (value is ArgumentError)
          [
            ref(value.invalidValue),
            ref(value.message),
            value.name,
            if (value is RangeError) value.start,
            if (value is RangeError) value.end,
          ],
        if (value is AssertionError) ref(value.message),
      ]);
      activeNativeErrors.remove(node);
      return;
    }
    if (value is SendPort) TypedTransfer.nativeSendPort(value);
    if (value is Capability &&
        value is! SendPort &&
        value.runtimeType != TypedTransfer._capabilityType) {
      throw UnsupportedError('Guest isolates require a native VM Capability');
    }
    if (value is SendPort ||
        value is Capability ||
        value is TransferableTypedData ||
        value is Uint8List ||
        value is Int8List ||
        value is Uint8ClampedList ||
        value is Int16List ||
        value is Uint16List ||
        value is Int32List ||
        value is Uint32List ||
        value is Uint64List ||
        value is Int64List ||
        value is Float32List ||
        value is Float64List ||
        value is ByteData ||
        value is ByteBuffer ||
        value is StackTrace) {
      node.addAll([
        'native',
        boxed,
        value is StackTrace ? value.toString() : value,
        value is StackTrace,
      ]);
      return;
    }
    throw UnsupportedError(
      'Unsupported guest isolate native resource: ${value.runtimeType}',
    );
  }
}

final class _Decoder {
  _Decoder(this.runtime, this.types, this.nodes)
    : values = List<Object?>.filled(nodes.length, null),
      allocated = List<bool>.filled(nodes.length, false);
  final Runtime runtime;
  final List<int> types;
  final List<List> nodes;
  final List<Object?> values;
  final List<bool> allocated;
  int type(int id) => id < 0 ? id : types[id];

  Object? ref(int id) {
    if (allocated[id]) return values[id];
    final node = nodes[id];
    Object? save(Object? value) {
      allocated[id] = true;
      return values[id] = value;
    }

    switch (node[0]) {
      case 'scalar':
        return save(node[1]);
      case 'boxed':
        return save(runtime.wrapAlways(node[1]));
      case 'type':
        return save($TypeImpl(type(node[1] as int), runtime));
      case 'cell':
        final cell = TypedCaptureCell(null);
        save(cell);
        cell.value = ref(node[1] as int);
        return cell;
      case 'late-field-uninitialized':
        return save(TypedLateField.uninitialized);
      case 'late-local':
        final cell = TypedLateLocal(node[1] as String, node[2] as bool);
        save(cell);
        cell.restoreSnapshot(
          initialized: node[3] as bool,
          value: ref(node[4] as int),
          initializer: ref(node[5] as int) as EvalCallable?,
        );
        return cell;
      case 'closure':
        final program = runtime.guestIsolateTypedProgram;
        final index = node[1] as int;
        final descriptor = index >= 0
            ? program.closures[index]
            : program.boundReceiverDescriptor(node[2] as int)!;
        final refs = (node[3] as List).cast<int>();
        final captures = List<Object?>.filled(refs.length, null);
        final closure = TypedClosure.restore(
          program,
          descriptor,
          captures,
          runtime,
          null,
          (node[5] as List).cast<int>().map(type).toList(),
          environment(node[6]),
          type(node[7] as int),
        );
        save(closure);
        final receiver = ref(node[4] as int);
        closure.definingTypeEnvironmentReceiver = node[8] == true
            ? type(receiver as int)
            : receiver;
        for (var i = 0; i < refs.length; i++) {
          captures[i] = ref(refs[i]);
        }
        return closure;
      case 'instance':
        final instance = TypedInstance(
          runtime.guestIsolateTypedProgram,
          node[1] as int,
          null,
          runtime,
          node[2] == null ? null : type(node[2] as int),
        );
        save(instance);
        final parent = ref(node[3] as int);
        if (parent != null) {
          TypedInstance.linkSuperclass(instance, parent as TypedInstance);
        }
        instance.restoreDispatchRoot(ref(node[5] as int) as TypedInstance);
        final refs = (node[4] as List).cast<int>();
        for (var i = 0; i < refs.length; i++) {
          instance.values[i] = ref(refs[i]);
        }
        return instance;
      case 'member':
        final receiverId = node[1] as int;
        final receiverNode = nodes[receiverId];
        final fresh = !allocated[receiverId];
        final receiver = fresh
            ? TypedInstance(
                runtime.guestIsolateTypedProgram,
                receiverNode[1] as int,
                null,
                runtime,
                receiverNode[2] == null ? null : type(receiverNode[2] as int),
              )
            : values[receiverId] as TypedInstance;
        if (fresh) {
          values[receiverId] = receiver;
          allocated[receiverId] = true;
        }
        final member = TypedMember(receiver, node[2] as int);
        save(member);
        if (fresh) {
          final parent = ref(receiverNode[3] as int);
          if (parent != null) {
            TypedInstance.linkSuperclass(receiver, parent as TypedInstance);
          }
          receiver.restoreDispatchRoot(
            ref(receiverNode[5] as int) as TypedInstance,
          );
          final refs = (receiverNode[4] as List).cast<int>();
          for (var i = 0; i < refs.length; i++) {
            receiver.values[i] = ref(refs[i]);
          }
        }
        return member;
      case 'record':
        final refs = (node[3] as List).cast<int>();
        final fields = List<Object?>.filled(refs.length, null);
        final record = $Record(
          fields,
          (node[2] as Map).cast<String, int>(),
          type(node[1] as int),
          runtime,
        );
        save(record);
        for (var i = 0; i < refs.length; i++) {
          fields[i] = ref(refs[i]);
        }
        return record;
      case 'list':
        final refs = (node[2] as List).cast<int>();
        final raw = List<Object?>.filled(
          refs.length,
          null,
          growable: node[3] as bool,
        );
        final readOnly = node[4] as bool;
        final wrapper = TypedNativeList.wrap(
          readOnly ? UnmodifiableListView(raw) : raw,
          isolateGrowable: node[3] as bool,
          isolateReadOnly: readOnly,
          runtime: runtime,
          runtimeTypeId: type(node[1] as int),
        );
        save(wrapper);
        for (var i = 0; i < refs.length; i++) {
          raw[i] = ref(refs[i]);
        }
        return wrapper;
      case 'map':
        final readOnly = node[3] as bool;
        final raw = node[4] == true
            ? TypedCollections.newConstMap(runtime)
            : TypedCollections.newMap(runtime);
        final wrapper = TypedNativeMap.wrap(
          readOnly ? UnmodifiableMapView(raw) : raw,
          runtime: runtime,
          runtimeTypeId: type(node[1] as int),
        );
        save(wrapper);
        for (final pair in node[2] as List) {
          raw[ref(pair[0] as int)] = ref(pair[1] as int);
        }
        return wrapper;
      case 'set':
        final readOnly = node[3] as bool;
        final identity = node[5] as bool;
        final raw = identity
            ? LinkedHashSet<Object?>.identity()
            : node[4] == true
            ? TypedCollections.newConstSet(runtime)
            : TypedCollections.newSet(runtime);
        final wrapper = $Set.wrap(
          readOnly ? UnmodifiableSetView(raw) : raw,
          isolateIdentity: identity,
          runtime: runtime,
          runtimeTypeId: type(node[1] as int),
        );
        save(wrapper);
        raw.addAll((node[2] as List).cast<int>().map(ref));
        return wrapper;
      case 'native':
        final raw = node[3] == true
            ? StackTrace.fromString(node[2] as String)
            : node[2];
        return save(node[1] == true ? wrapNative(raw) : raw);
      case 'datetime':
        final value = DateTime.fromMicrosecondsSinceEpoch(
          node[2] as int,
          isUtc: node[3] as bool,
        );
        return save(node[1] == true ? $DateTime.wrap(value) : value);
      case 'duration':
        final value = Duration(microseconds: node[2] as int);
        return save(node[1] == true ? $Duration.wrap(value) : value);
      case 'timeout':
        final value = TimeoutException(
          node[2] as String?,
          ref(node[3] as int) as Duration?,
        );
        return save(node[1] == true ? $TimeoutException.wrap(value) : value);
      case 'error':
        final text = node[3] as String;
        final stack = node[4] as String? ?? '';
        final Object error = switch (node[2]) {
          'state' => StateError(node[5] as String),
          'unsupported' => UnsupportedError(node[5] as String),
          'unimplemented' => UnimplementedError(node[5] as String?),
          'format' => FormatException(
            node[5] as String,
            ref(node[6][0] as int),
            node[6][1] as int?,
          ),
          'range' => rangeError(node[6] as List),
          'argument' => ArgumentError.value(
            ref(node[6][0] as int),
            node[6][2] as String?,
            ref(node[6][1] as int),
          ),
          'type' => _TransferredTypeError(text),
          'assertion' => AssertionError(ref(node[6] as int)),
          _ => RemoteError(text, stack),
        };
        if (error is Error && stack.isNotEmpty) {
          try {
            Error.throwWithStackTrace(error, StackTrace.fromString(stack));
          } catch (_) {
            /* Restore the stack without raising it in the receiver. */
          }
        }
        if (node[1] != true) return save(error);
        return save(switch (error) {
          StateError() => $StateError.wrap(error),
          UnimplementedError() => $UnimplementedError.wrap(error),
          UnsupportedError() => $UnsupportedError.wrap(error),
          FormatException() => $FormatException.wrap(error),
          RangeError() => $RangeError.wrap(error),
          ArgumentError() => $ArgumentError.wrap(error),
          TypeError() => $TypeError.wrap(error),
          AssertionError() => $AssertionError.wrap(error),
          RemoteError() => $RemoteError.wrap(error),
          _ => throw StateError('Unknown transferred error'),
        });
      default:
        throw FormatException('Unknown guest graph node ${node[0]}');
    }
  }

  RangeError rangeError(List fields) {
    final invalidValue = ref(fields[0] as int);
    final message = ref(fields[1] as int);
    if (invalidValue == null) return RangeError(message);
    return RangeError.range(
      invalidValue as num,
      fields[3] as int?,
      fields[4] as int?,
      fields[2] as String?,
      message as String?,
    );
  }

  TypedTypeEnvironment? environment(Object? value) {
    if (value == null) return null;
    final node = value as List;
    return TypedTypeEnvironment(
      (node[0] as List).cast<int>(),
      (node[1] as List).cast<int>().map(type).toList(),
      environment(node[2]),
    );
  }

  $Value wrapNative(Object? value) => switch (value) {
    SendPort() => $SendPort.wrap(value),
    Capability() => $Capability.wrap(value),
    TransferableTypedData() => $TransferableTypedData.wrap(value),
    Uint8List() => $Uint8List.wrap(value),
    Int8List() => $Int8List.wrap(value),
    Uint8ClampedList() => $Uint8ClampedList.wrap(value),
    Uint16List() => $Uint16List.wrap(value),
    Int16List() => $Int16List.wrap(value),
    Uint32List() => $Uint32List.wrap(value),
    Uint64List() => $Uint64List.wrap(value),
    Int32List() => $Int32List.wrap(value),
    Int64List() => $Int64List.wrap(value),
    Float32List() => $Float32List.wrap(value),
    Float64List() => $Float64List.wrap(value),
    ByteData() => $ByteData.wrap(value),
    ByteBuffer() => $ByteBuffer.wrap(value),
    Duration() => $Duration.wrap(value),
    DateTime() => $DateTime.wrap(value),
    StackTrace() => $StackTrace.wrap(value),
    _ => throw UnsupportedError(
      'Unsupported transferred native value: ${value.runtimeType}',
    ),
  };
}

final class _TransferredTypeError extends TypeError {
  _TransferredTypeError(this.message);
  final String message;
  @override
  String toString() => message;
}
