import 'package:dart_eval/src/eval/runtime/class.dart';
import 'package:dart_eval/src/eval/bridge/runtime_bridge.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

import 'typed_call_site.dart';
import 'typed_closure.dart';
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
    Object? argumentsFirst,
    Object? argumentsRest,
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
    final member = receiver.resolve(
      site.kind,
      site.name,
      callerLibrary: site.callerLibrary,
    );
    if (member == null || !identical(member.receiver.program, program)) {
      return null;
    }
    final function = member.function;
    if (site.typeArguments.isNotEmpty ||
        site.namedNames.isNotEmpty ||
        site.positionalCount != site.argumentCount ||
        function.argumentKinds.length != site.argumentCount + 1) {
      return null;
    }
    member.checkExactArguments(
      site.argumentCount,
      argumentsFirst,
      argumentsRest,
      runtime,
    );
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
    int siteIndex, [
    List<int>? resolvedTypeArguments,
  ]) {
    final site = program.callSites[siteIndex];
    final typeArguments = resolvedTypeArguments ?? site.typeArguments;
    switch (site.kind) {
      case TypedMemberKind.getter:
        if (receiver is TypedInstance) {
          return receiver.getProperty(
            site.name,
            callerLibrary: site.callerLibrary,
            runtime: runtime,
          );
        }
        return TypedInterop.getProperty(runtime, receiver, site.name);
      case TypedMemberKind.setter:
        if (receiver is TypedInstance) {
          receiver.setProperty(
            site.name,
            first as $Value?,
            callerLibrary: site.callerLibrary,
            runtime: runtime,
          );
          return null;
        }
        TypedInterop.setProperty(
          runtime,
          receiver,
          site.name,
          first as $Value?,
        );
        return null;
      case TypedMemberKind.method:
        final count = site.argumentCount;
        if (receiver is TypedInstance) {
          return receiver.invoke(
            site.name,
            site.positionalCount,
            first,
            rest,
            namedNames: site.namedNames,
            callerLibrary: site.callerLibrary,
            typeArguments: typeArguments,
            runtime: runtime,
          );
        }
        if (site.name == 'call' && receiver is TypedClosure) {
          if (!receiver.descriptor.accepts(
                site.positionalCount,
                site.namedNames,
              ) ||
              !receiver.acceptsTypeArguments(typeArguments)) {
            throw NoSuchMethodError.withInvocation(
              receiver,
              _callMethodInvocation(count, first, rest, site),
            );
          }
          return receiver.invoke(
            site.positionalCount,
            first,
            rest,
            namedNames: site.namedNames,
            typeArguments: typeArguments,
            runtime: runtime,
          );
        }
        if (site.name == 'call' && receiver is TypedMember) {
          if (!receiver.accepts(site.positionalCount, site.namedNames) ||
              !receiver.acceptsTypeArguments(typeArguments)) {
            throw NoSuchMethodError.withInvocation(
              receiver,
              _callMethodInvocation(count, first, rest, site),
            );
          }
          return receiver.invokeClosure(
            site.positionalCount,
            first,
            rest,
            namedNames: site.namedNames,
            typeArguments: typeArguments,
            runtime: runtime,
          );
        }
        final bridgeSubclass = receiver is $Bridge
            ? Runtime.bridgeData[receiver]?.subclass
            : null;
        if (bridgeSubclass is TypedInstance) {
          return site.namedNames.isEmpty && typeArguments.isEmpty
              ? bridgeSubclass.invokeBridge(
                  site.name,
                  TypedInterop.argList(count, first, rest),
                  runtime: runtime,
                )
              : bridgeSubclass.invoke(
                  site.name,
                  site.positionalCount,
                  first,
                  rest,
                  namedNames: site.namedNames,
                  callerLibrary: site.callerLibrary,
                  typeArguments: typeArguments,
                  runtime: runtime,
                );
        }
        if (site.name == 'call' &&
            site.namedNames.isEmpty &&
            typeArguments.isEmpty) {
          return TypedInterop.call(runtime, receiver, count, first, rest);
        }
        if (site.namedNames.isNotEmpty) {
          // Bridge definitions lower named parameters into their fixed host
          // ABI order. A super shim must therefore receive the full flattened
          // vector, not the source-level positional prefix.
          if (receiver is BridgeSuperShim && typeArguments.isEmpty) {
            return TypedInterop.invoke(
              runtime,
              receiver,
              site.name,
              count,
              first,
              rest,
            );
          }
          throw UnsupportedError(
            'Named arguments require an evaluated method or closure',
          );
        }
        return TypedInterop.invoke(
          runtime,
          receiver,
          site.name,
          site.positionalCount,
          first,
          rest,
        );
    }
  }

  static Invocation _callMethodInvocation(
    int count,
    Object? first,
    Object? rest,
    TypedCallSite site,
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
}
