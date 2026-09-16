import 'package:dart_eval/src/eval/runtime/class.dart';
import 'package:dart_eval/src/eval/bridge/runtime_bridge.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

import 'typed_call_site.dart';
import 'typed_function.dart';
import 'typed_instance.dart';
import 'typed_interop.dart';
import 'typed_program.dart';

/// Resolve members outside the arithmetic loop without moving their arguments.
abstract final class TypedDispatch {
  @pragma('vm:never-inline')
  static TypedMember? resolve(
    TypedProgram program,
    Object? receiver,
    int siteIndex, [
    Runtime? runtime,
  ]) {
    if (receiver is! TypedInstance) {
      if (receiver is! $Bridge) return null;
      receiver = Runtime.bridgeData[receiver]?.subclass;
    }
    if (receiver is! TypedInstance ||
        !identical(receiver.program, program) ||
        (receiver.runtime != null && !identical(receiver.runtime, runtime))) {
      return null;
    }
    final site = program.callSites[siteIndex];
    final member = receiver.resolve(site.kind, site.name);
    if (member == null || !identical(member.receiver.program, program)) {
      return null;
    }
    final function = member.function;
    if (function.argumentKinds.length != site.argumentCount + 1) {
      throw ArgumentError('Invalid argument count for ${site.name}');
    }
    // Ordinary methods share the boxed result ABI. Native scalar operators
    // use the explicit signature adapter until their return adapters are linked.
    if (function.resultKind != TypedArgumentKind.object &&
        function.resultKind != null) {
      return null;
    }
    return member;
  }

  /// A bridge or a different typed program is an actual invocation boundary.
  /// Only this path materializes the positional vector required by bridge APIs.
  @pragma('vm:never-inline')
  static Object? invoke(
    TypedProgram program,
    Runtime? runtime,
    Object? receiver,
    Object? first,
    Object? rest,
    int siteIndex,
  ) {
    final site = program.callSites[siteIndex];
    switch (site.kind) {
      case TypedMemberKind.getter:
        return TypedInterop.getProperty(runtime, receiver, site.name);
      case TypedMemberKind.setter:
        TypedInterop.setProperty(
          runtime,
          receiver,
          site.name,
          first as $Value?,
        );
        return null;
      case TypedMemberKind.method:
        final arguments = switch (site.argumentCount) {
          0 => <$Value?>[],
          1 => <$Value?>[first as $Value?],
          2 => <$Value?>[first as $Value?, rest as $Value?],
          _ => <$Value?>[
            first as $Value?,
            for (var i = 0; i < site.argumentCount - 1; i++)
              (rest as List<Object?>)[i] as $Value?,
          ],
        };
        return site.name == 'call'
            ? TypedInterop.call(runtime, receiver, arguments)
            : TypedInterop.invoke(runtime, receiver, site.name, arguments);
    }
  }
}
