import 'helpers/global.dart';
import 'helpers/conversion.dart';
import 'member/call_signature.dart';
import 'member/member.dart';
import 'member/member_name.dart';
import 'backend/representation.dart' show MachineRepresentation;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'invocation/deferred.dart';
import 'invocation/targets.dart';
import 'package:dart_eval/src/eval/ir/primitives.dart';
import 'package:dart_eval/src/eval/ir/types.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:collection/collection.dart';
import 'package:dart_eval/src/eval/ir/collection.dart';
import 'package:dart_eval/src/eval/ir/globals.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:dart_eval/src/eval/compiler/helpers/extension.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'values/abi.dart';
import 'invocation/resolver.dart';
import 'variable/value_facts.dart';

import 'denotation.dart';
export 'denotation.dart';

/// A compile-time datum that can be - at the very least - converted to a [Variable] in the
/// future if needed. May also contain information about how to modify its value.
///
/// Using References can help prevent unnecessary bytecode generation, but be careful! Some Dart structures
/// may rely on side-effects from accessing a variable.
abstract class Reference {
  TypeRef resolveType(
    CompilerContext ctx, {
    bool forSet = false,
    AstNode? source,
  });

  Variable setValue(CompilerContext ctx, Variable value, [AstNode? source]);

  Variable getValue(CompilerContext ctx, [AstNode? source]);

  CallTarget? getDirectCall(CompilerContext ctx, [AstNode? source]);
}

/// A property whose getter and setter resolve from the lexical superclass.
class SuperPropertyReference extends IdentifierReference {
  SuperPropertyReference(Variable super.object, super.name);

  @override
  Denotation denotation(
    CompilerContext ctx, {
    bool forSet = false,
    AstNode? source,
  }) => InstanceMemberDenotation(SuperReceiver(object!), name);

  @override
  CallTarget? getDirectCall(CompilerContext ctx, [AstNode? source]) => null;
}

/// A local, instance, or top-level reference with an optional target object.
class IdentifierReference implements Reference {
  IdentifierReference(this.object, this.name, {this.pin});

  Variable? object;
  final String name;

  /// For member access on an `E(receiver)` value: the explicit-application
  /// pin restricting member resolution to the extension.
  final BoundExtension? pin;

  /// The denotation this reference resolves to — computed per call since
  /// resolution depends on the scope at the use site (the plan's
  /// `late final` is approximated: References are per-site and denotation
  /// resolution is cheap).
  Denotation denotation(
    CompilerContext ctx, {
    bool forSet = false,
    AstNode? source,
  }) {
    final object = this.object;
    if (object != null) {
      return resolveMemberAccess(
        ctx,
        receiverOf(ctx, object, pin: pin),
        name,
        forSet: forSet,
        source: source,
      );
    }
    return resolveIdentifier(ctx, name, forSet: forSet, source: source);
  }

  @override
  TypeRef resolveType(
    CompilerContext ctx, {
    bool forSet = false,
    AstNode? source,
  }) {
    final d = denotation(ctx, forSet: forSet, source: source);
    return forSet
        ? d.writeType(ctx, source: source)
        : d.readType(ctx, source: source);
  }

  @override
  Variable setValue(CompilerContext ctx, Variable value, [AstNode? source]) =>
      denotation(
        ctx,
        forSet: true,
        source: source,
      ).write(ctx, value, source: source);

  @override
  Variable getValue(CompilerContext ctx, [AstNode? source]) =>
      denotation(ctx, source: source).read(ctx, source: source);

  @override
  CallTarget? getDirectCall(CompilerContext ctx, [AstNode? source]) =>
      denotation(ctx, source: source).call(ctx, source: source);
}

/// A [Reference] with a prefixed String identifier, for accessing prefixed
/// imports.
class PrefixedIdentifierReference implements Reference {
  final String prefix;
  final String identifier;

  const PrefixedIdentifierReference(this.prefix, this.identifier);

  Denotation denotation(
    CompilerContext ctx, {
    bool forSet = false,
    AstNode? source,
  }) {
    final dec =
        ctx.visibleDeclarations[ctx.library]![prefix] ??
        (throw CompileError('Cannot find prefix $prefix', source));
    if (dec.declaration != null) {
      throw CompileError('Cannot use a declaration as a prefix', source);
    }
    return PrefixDenotation(
      prefix,
      dec.children!,
    ).memberAccess(ctx, identifier, forSet: forSet, source: source);
  }

  @override
  CallTarget? getDirectCall(CompilerContext ctx, [AstNode? source]) =>
      denotation(ctx, source: source).call(ctx, source: source);

  @override
  Variable getValue(CompilerContext ctx, [AstNode? source]) =>
      denotation(ctx, source: source).read(ctx, source: source);

  @override
  TypeRef resolveType(
    CompilerContext ctx, {
    bool forSet = false,
    AstNode? source,
  }) {
    final d = denotation(ctx, forSet: forSet, source: source);
    return forSet
        ? d.writeType(ctx, source: source)
        : d.readType(ctx, source: source);
  }

  @override
  Variable setValue(CompilerContext ctx, Variable value, [AstNode? source]) =>
      denotation(
        ctx,
        forSet: true,
        source: source,
      ).write(ctx, value, source: source);
}

/// A [Reference] with a variable that can be indexed into and a variable index. Accessing its value may use [IndexList]
/// [IndexMap] or [InvokeDynamic] depending on the state of the target variable.
class IndexedReference implements Reference {
  IndexedReference(this._variable, this._index);

  Variable _variable;
  Variable _index;

  @override
  TypeRef resolveType(
    CompilerContext ctx, {
    bool forSet = false,
    AstNode? source,
  }) {
    if (_variable.type.isAssignableTo(
      ctx,
      CoreTypes.list.ref(ctx),
      forceAllowDynamic: false,
    )) {
      return interfaceArgumentsOf(_variable.type).isNotEmpty
          ? interfaceArgumentsOf(_variable.type)[0]
          : CoreTypes.dynamic.ref(ctx);
    }
    if (_variable.type.isAssignableTo(
      ctx,
      CoreTypes.map.ref(ctx),
      forceAllowDynamic: false,
    )) {
      return interfaceArgumentsOf(_variable.type).length >= 2
          ? interfaceArgumentsOf(_variable.type)[1]
          : CoreTypes.dynamic.ref(ctx);
    }
    // A write's contextual type must not execute the indexed getter. For a
    // custom `[]=` the write type is the operator's value parameter —
    // callers use it as the RHS's context type (e.g. `a?[i] ??= e`).
    if (forSet) {
      return setterValueType(ctx, source) ?? CoreTypes.dynamic.ref(ctx);
    }
    return getValue(ctx).type;
  }

  /// The declared value-parameter type of the receiver's `[]=` operator, or
  /// null when it cannot be resolved (dynamic receivers, missing member).
  TypeRef? setterValueType(CompilerContext ctx, [AstNode? source]) {
    try {
      final resolved = ctx.memberLookup.interfaceMember(
        _variable.type,
        MemberName.method('[]='),
        source: source,
      );
      final member = resolved.member;
      final decl = member is SourceMember ? member.node : null;
      if (decl is MethodDeclaration) {
        final param = decl.parameters?.parameters.elementAtOrNull(1);
        if (param?.type == null) return null;
        // Bind the declaring class's type parameters through the receiver's
        // supertype chain so a `WriteType` annotation resolves concretely.
        return ctx.typeFactory.formalParameterAnnotationType(
          resolved.viewedAs.file,
          param!,
          typeParameters: resolved.ownerTypeArguments,
        );
      }
    } on CompileError {
      // An extension `[]=` may apply instead.
    }
    final found = resolveExtensionMember(ctx, _variable.type, '[]=');
    if (found == null) return null;
    final (ext, member, bindings) = found;
    final param = member.parameters?.parameters.elementAtOrNull(1);
    if (param?.type == null) return null;
    return ctx.typeFactory.formalParameterAnnotationType(
      ext.library,
      param!,
      typeParameters: extBindingsMap(ext, bindings),
    );
  }

  @override
  Variable getValue(CompilerContext ctx, [AstNode? source]) {
    _variable = _variable.updated(ctx);
    _index = _index.updated(ctx);

    if (_variable.type.isAssignableTo(
      ctx,
      CoreTypes.list.ref(ctx),
      forceAllowDynamic: false,
    )) {
      if (!_index.type.isAssignableTo(ctx, CoreTypes.int.ref(ctx))) {
        throw CompileError(
          'TypeError: Cannot use variable of type ${_index.type} as list index',
        );
      }

      final list = _variable.unboxIfNeeded(ctx);
      _index = _index.unboxIfNeeded(ctx);
      final listElementType = interfaceArgumentsOf(_variable.type).isNotEmpty
          ? interfaceArgumentsOf(_variable.type)[0]
          : CoreTypes.dynamic.ref(ctx);
      return Variable.ssa(
        ctx,
        IndexList(ctx.svar('list'), list.ssa, _index.ssa),
        listElementType,
        rep: ValueRep.boxed,
      );
    }

    if (_variable.type.isAssignableTo(
      ctx,
      CoreTypes.map.ref(ctx),
      forceAllowDynamic: false,
    )) {
      // `Map.[]` takes `Object?` — any index type is allowed at compile
      // time; a miss returns null rather than throwing.
      final map = _variable.unboxIfNeeded(ctx);
      // Collection elements are always boxed (Abi.collectionElement), so the
      // key travels boxed and a miss must produce a boxed null.
      _index = _index.boxIfNeeded(ctx, source);

      final mapType = interfaceArgumentsOf(_variable.type).length < 2
          ? CoreTypes.dynamic.ref(ctx)
          : interfaceArgumentsOf(_variable.type)[1];

      final mapResult = Variable.ssa(
        ctx,
        IndexMap(ctx.svar('map'), map.ssa, _index.ssa),
        mapType,
        rep: ValueRep.boxed,
      );

      return Variable.ssa(
        ctx,
        MaybeBoxNull(ctx.svar('map'), mapResult.ssa),
        mapType,
        rep: ValueRep.boxed,
      );
    }

    final result = CallResolver(ctx).invokeOperator(_variable, '[]', [_index]);
    _variable = result.target!;
    _index = result.args[0];

    return result.result;
  }

  @override
  Variable setValue(CompilerContext ctx, Variable value, [AstNode? source]) {
    _variable = _variable.updated(ctx);
    _index = _index.updated(ctx);

    if (_variable.type.isAssignableTo(
      ctx,
      CoreTypes.list.ref(ctx),
      forceAllowDynamic: false,
    )) {
      if (!_index.type.isAssignableTo(ctx, CoreTypes.int.ref(ctx))) {
        throw CompileError(
          'TypeError: Cannot use variable of type ${_index.type} as list index',
          source,
        );
      }

      final elementType = interfaceArgumentsOf(_variable.type).isEmpty
          ? CoreTypes.dynamic.ref(ctx)
          : interfaceArgumentsOf(_variable.type)[0];
      final formattedValue = convertForAssignment(
        ctx,
        value,
        elementType,
        representation: MachineRepresentation.object,
        source: source,
      );
      // Keep the reified wrapper for writes. A List<num> reference can point
      // at a List<int>; writing directly to its raw backing list would bypass
      // the actual instance's checked element type.
      final result = CallResolver(
        ctx,
      ).invokeOperator(_variable, '[]=', [_index, formattedValue]);
      _variable = result.target!;
      _index = result.args[0];
      return result.args[1];
    }

    // Coerce the value against the `[]=` signature — the implicit `.call`
    // tear-off applies when the parameter is a function type. A missing
    // instance member means an extension `[]=` may apply (handled inside
    // [Variable.invoke]).
    final valueType = setterValueType(ctx, source);
    final converted = valueType == null
        ? value
        : convertForAssignment(
            ctx,
            value,
            valueType,
            representation: MachineRepresentation.object,
            source: source,
          );

    final result = CallResolver(
      ctx,
    ).invokeOperator(_variable, '[]=', [_index, converted]);
    _variable = result.target!;
    _index = result.args[0];
    return result.args[1];
  }

  @override
  CallTarget? getDirectCall(CompilerContext ctx, [AstNode? source]) {
    return null;
  }
}

/// Loads a top-level (or static field) global by its qualified [globalName],
/// using [valueName] (defaults to the unqualified name) for the SSA variable.
Variable loadGlobalVariable(
  CompilerContext ctx,
  int sourceLib,
  String globalName, [
  String? valueName,
]) {
  ensureGlobalRegistered(ctx, sourceLib, globalName);
  final type = resolveGlobalType(ctx, sourceLib, globalName);
  final gIndex = ctx.topLevelGlobalIndices[sourceLib]![globalName]!;
  return Variable.ssa(
    ctx,
    LoadGlobal(ctx.svar(valueName ?? globalName), gIndex),
    type,
    rep: Abi.storageSlot(type),
  );
}

/// A `Type` literal variable for [type]. [constructorKey] is the name used in
/// [DeferredOrOffset] to resolve the constructor (e.g. `ClassName.` or, for
/// bridged enums, `EnumName#wrap`).
Variable typeLiteral(
  CompilerContext ctx,
  TypeRef type,
  String constructorKey,
) {
  final typeId = ctx.runtimeTypes.idOf(type);
  final operation = type.requiresTypeEnvironment
      ? LoadTypeParameter(ctx.svar('type'), typeId)
      : LoadConstantType(ctx.svar('type'), typeId);
  return Variable.ssa(
    ctx,
    operation,
    CoreTypes.type.ref(ctx),
    facts: ValueFacts(denotedType: type, possibleClasses: [type]),
    callable: CallableValue(
      offset: DeferredOrOffset(file: type.file, name: constructorKey),
      signature: CallSignature.returnOnly(type),
    ),
  );
}

/// The declared type of a setter's `value` parameter, or null when the
/// parameter list is empty or untyped.
TypeRef? setterValueType(
  CompilerContext ctx,
  int file,
  FormalParameterList? parameters,
) {
  final param = parameters?.parameters.firstOrNull;
  if (param == null || param.type == null) return null;
  return ctx.typeFactory.formalParameterAnnotationType(file, param);
}

/// Whether [name] resolves to a field, method, or extension member of
/// [receiver]'s static type. Anonymous-method bodies use this to scope
/// unqualified names to the receiver without emitting a speculative
/// dispatch — a dynamic receiver always counts as having the member.
/// Whether [type] or one of its supertypes declares a member named [name].
/// Setters and getters register under `name*s`/`name*g` keys, so each kind is
/// probed separately when [forSet] selects one.
bool hasInstanceMember(
  CompilerContext ctx,
  TypeRef type,
  String name, {
  bool forSet = false,
}) {
  final member = forSet
      ? ctx.memberLookup.tryInterfaceMember(
              type,
              MemberName(name, MemberKind.setter),
            ) ??
            ctx.memberLookup.tryInterfaceMember(
              type,
              MemberName(name, MemberKind.getter),
            )
      : ctx.memberLookup.tryInterfaceMember(
          type,
          MemberName(name, MemberKind.getter),
        );
  return member != null;
}

/// Re-derives the [BoundExtension] pin an `E(x)` target expression would
/// carry — explicit extension application is syntactic, so the pin lives at
/// the member-access site rather than on the compiled value. [receiverType]
/// is the compiled `E(x)` value's type, used to resolve the `on` bindings.
BoundExtension? extensionPinOf(
  CompilerContext ctx,
  Expression? target,
  TypeRef receiverType,
) {
  if (target is! MethodInvocation) return null;
  // `E(x)` always names the extension as a bare identifier; a member-call
  // target like `recv.m(...)` fails the lexical lookup and is not a pin.
  final Denotation d;
  try {
    d = IdentifierReference(
      null,
      target.methodName.name,
    ).denotation(ctx, source: target);
  } on CompileError {
    return null;
  }
  if (d is! ExtensionNamespaceDenotation) return null;
  return boundExtensionFor(ctx, target, d.ext, receiverType);
}
