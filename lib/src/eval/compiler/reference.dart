import 'helpers/global.dart';
import 'package:dart_eval/src/eval/compiler/variable/binding.dart';
import 'helpers/conversion.dart';
import 'helpers/tearoff.dart';
import 'model/function_type.dart';
import '../ir/closures.dart';
import '../ir/exception.dart';
import 'backend/representation.dart' show MachineRepresentation;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/bridge/declaration.dart';
import 'package:dart_eval/src/eval/compiler/dispatch.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/expression/function.dart';
import 'package:dart_eval/src/eval/compiler/expression/method_invocation.dart';
import 'package:dart_eval/src/eval/ir/primitives.dart';
import 'package:dart_eval/src/eval/ir/types.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/ir/bridge.dart';
import 'package:collection/collection.dart';
import 'package:dart_eval/src/eval/ir/collection.dart';
import 'package:dart_eval/src/eval/ir/globals.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/compiler/expression/identifier.dart';
import 'package:dart_eval/src/eval/compiler/helpers/extension.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'values/abi.dart';
import 'member/member_name.dart';
import 'invocation/accessors.dart';
import 'invocation/resolver.dart';

part 'denotation.dart';

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

  DirectCall? getDirectCall(CompilerContext ctx, [AstNode? source]);
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
  DirectCall? getDirectCall(CompilerContext ctx, [AstNode? source]) =>
      null;
}

/// A local, instance, or top-level reference with an optional target object.
class IdentifierReference implements Reference {
  IdentifierReference(this.object, this.name);

  Variable? object;
  final String name;

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
        receiverOf(ctx, object),
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
      denotation(ctx, forSet: true, source: source)
          .write(ctx, value, source: source);

  @override
  Variable getValue(CompilerContext ctx, [AstNode? source]) =>
      denotation(ctx, source: source).read(ctx, source: source);

  @override
  DirectCall? getDirectCall(CompilerContext ctx, [AstNode? source]) =>
      denotation(ctx, source: source).call(ctx, source: source);
}

/// A deferred import prefix exposes an implicit `loadLibrary` member. Since
/// all libraries are compiled eagerly, it resolves to a stub closure
/// returning an already-completed `Future<Null>` — and it shadows any
/// `loadLibrary` declared by the imported library itself.
Variable? _deferredLoadLibrary(CompilerContext ctx, String prefix) {
  if (!(ctx.deferredPrefixes[ctx.library]?.contains(prefix) ?? false)) {
    return null;
  }
  final idx =
      ctx.bridgeStaticFunctionIndices[ctx
          .libraryMap['dart:core']]?['deferred_loadLibrary'];
  if (idx == null) return null;
  return Variable.ssa(
    ctx,
    InvokeExternal(ctx.svar('loadLibrary'), idx, []),
    CoreTypes.function.ref(ctx),
    methodReturnType: AlwaysReturnType(
      CoreTypes.future
          .ref(ctx)
          .copyWith(typeArguments: [CoreTypes.nullType.ref(ctx)]),
      false,
    ),
  );
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
    return PrefixDenotation(prefix, dec.children!).memberAccess(
      ctx,
      identifier,
      forSet: forSet,
      source: source,
    );
  }

  @override
  DirectCall? getDirectCall(CompilerContext ctx, [AstNode? source]) =>
      denotation(ctx, source: source).call(ctx, source: source);

  @override
  Variable getValue(CompilerContext ctx, [AstNode? source]) =>
      denotation(ctx, source: source).read(ctx, source: source);

  @override
  TypeRef resolveType(
    CompilerContext ctx, {
    bool forSet = false,
    AstNode? source,
  }) => denotation(ctx, forSet: forSet, source: source).readType(
    ctx,
    source: source,
  );

  @override
  Variable setValue(CompilerContext ctx, Variable value, [AstNode? source]) =>
      denotation(ctx, forSet: true, source: source)
          .write(ctx, value, source: source);
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
      return _variable.type.typeArguments.isNotEmpty
          ? _variable.type.typeArguments[0]
          : CoreTypes.dynamic.ref(ctx);
    }
    if (_variable.type.isAssignableTo(
      ctx,
      CoreTypes.map.ref(ctx),
      forceAllowDynamic: false,
    )) {
      return _variable.type.typeArguments.length >= 2
          ? _variable.type.typeArguments[1]
          : CoreTypes.dynamic.ref(ctx);
    }
    // A write's contextual type must not execute the indexed getter. For a
    // custom `[]=` the write type is the operator's value parameter —
    // callers use it as the RHS's context type (e.g. `a?[i] ??= e`).
    if (forSet) {
      return _setterValueType(ctx, source) ?? CoreTypes.dynamic.ref(ctx);
    }
    return getValue(ctx).type;
  }

  /// The declared value-parameter type of the receiver's `[]=` operator, or
  /// null when it cannot be resolved (dynamic receivers, missing member).
  TypeRef? _setterValueType(CompilerContext ctx, [AstNode? source]) {
    try {
      final decl0 = resolveInstanceMethod(ctx, _variable.type, '[]=', source);
      final decl = decl0.declaration;
      if (decl is MethodDeclaration) {
        final param = decl.parameters?.parameters.elementAtOrNull(1);
        if (param?.type == null) return null;
        // Bind the declaring class's type parameters through the receiver's
        // supertype chain so a `WriteType` annotation resolves concretely.
        return formalParameterAnnotationType(
          ctx,
          decl0.sourceLib,
          param!,
          typeParameters: classTypeArguments(
            ctx,
            _variable.type,
            decl0.sourceLib,
            decl,
          ),
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
    return formalParameterAnnotationType(
      ctx,
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
      final listElementType = _variable.type.typeArguments.isNotEmpty
          ? _variable.type.typeArguments[0]
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

      final mapType = _variable.type.typeArguments.length < 2
          ? CoreTypes.dynamic.ref(ctx)
          : _variable.type.typeArguments[1];

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

      final elementType = _variable.type.typeArguments.isEmpty
          ? CoreTypes.dynamic.ref(ctx)
          : _variable.type.typeArguments[0];
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
      final result = CallResolver(ctx).invokeOperator(_variable, '[]=', [_index, formattedValue]);
      _variable = result.target!;
      _index = result.args[0];
      return result.args[1];
    }

    // Coerce the value against the `[]=` signature — the implicit `.call`
    // tear-off applies when the parameter is a function type. A missing
    // instance member means an extension `[]=` may apply (handled inside
    // [Variable.invoke]).
    final valueType = _setterValueType(ctx, source);
    final converted = valueType == null
        ? value
        : convertForAssignment(
            ctx,
            value,
            valueType,
            representation: MachineRepresentation.object,
            source: source,
          );

    final result = CallResolver(ctx).invokeOperator(_variable, '[]=', [_index, converted]);
    _variable = result.target!;
    _index = result.args[0];
    return result.args[1];
  }

  @override
  DirectCall? getDirectCall(CompilerContext ctx, [AstNode? source]) {
    return null;
  }
}

Variable _declarationToVariable(
  DeclarationOrBridge decOrBridge,
  String name,
  CompilerContext ctx, [
  AstNode? source,
]) {
  if (decOrBridge.isBridge) {
    final bridge = decOrBridge.bridge!;

    if (bridge is BridgeClassDef) {
      final type = TypeRef.fromBridgeTypeRef(ctx, bridge.type.type);
      return _typeLiteral(ctx, type, '${type.name}.');
    }

    if (bridge is BridgeEnumDef) {
      final type = TypeRef.fromBridgeTypeRef(ctx, bridge.type);
      return _typeLiteral(ctx, type, '${type.name}#wrap');
    }

    if (bridge is BridgeFunctionDeclaration) {
      final returnType = TypeRef.fromBridgeAnnotation(
        ctx,
        bridge.function.returns,
      );
      return Variable(
        CoreTypes.function.ref(ctx),
        methodReturnType: AlwaysReturnType(returnType, false),
        methodOffset: DeferredOrOffset(file: decOrBridge.sourceLib, name: name),
      );
    }

    throw CompileError(
      'Cannot resolve bridged ${bridge.runtimeType} in reference',
      source,
    );
  }

  final decl = decOrBridge.declaration!;

  if (decl is VariableDeclaration) {
    return _loadGlobalVariable(ctx, decOrBridge.sourceLib, decl.name.lexeme);
  }

  if (decl is ExtensionDeclaration) {
    // `E` as an expression is the extension's namespace: `E.m(recv, ...)`
    // (explicit application) and `E.staticM(...)` resolve through it. The
    // pseudo-type `E` exists only in the declarations map, never as a class.
    final extType = TypeRef.unresolved(decOrBridge.sourceLib, declarationName(decl));
    return Variable(
      CoreTypes.type.ref(ctx),
      concreteTypes: [extType],
      methodOffset: DeferredOrOffset(
        file: decOrBridge.sourceLib,
        name: '${declarationName(decl)}.',
      ),
      callingConvention: CallingConvention.static,
    );
  }

  if (decl is! FunctionDeclaration && decl is! ConstructorDeclaration) {
    final type = decl is TypeAlias && decl is! ClassTypeAlias
        ? resolveTypeAlias(ctx, decOrBridge.sourceLib, decl)
        : TypeRef.lookupDeclaration(ctx, decOrBridge.sourceLib, decl);
    return _typeLiteral(ctx, type, '${declarationName(decl)}.');
  }

  TypeRef? returnType;
  var nullable = true;
  if (decl is FunctionDeclaration && decl.returnType != null) {
    returnType = ctx.withTypeParameters<TypeRef>(
      decOrBridge.sourceLib,
      null,
      decl.functionExpression.typeParameters?.typeParameters,
      () =>
          TypeRef.fromAnnotation(ctx, decOrBridge.sourceLib, decl.returnType!),
    );
    nullable = decl.returnType!.question != null;
  } else if (decl is ConstructorDeclaration) {
    returnType = TypeRef.lookupDeclaration(
      ctx,
      decOrBridge.sourceLib,
      decl.parent!.parent as ClassDeclaration,
    );
  } else {
    // A function without a return type annotation returns dynamic.
    returnType = CoreTypes.dynamic.ref(ctx);
  }

  // Accessors compile under `*g`/`*s` keys — use the accessor's own key so
  // deferred resolution finds the right function entry.
  final offset = DeferredOrOffset(
    file: decOrBridge.sourceLib,
    name: decl is FunctionDeclaration
        ? (decl.isGetter
              ? MemberName.getter(decl.name.lexeme).key
              : decl.isSetter
              ? MemberName.setter(decl.name.lexeme).key
              : name)
        : name,
  );

  final fn = Variable(
    decl is FunctionDeclaration
        ? CoreTypes.function.ref(ctx)
        : CoreTypes.type.ref(ctx),
    concreteTypes: [returnType],
    methodOffset: offset,
    methodReturnType: AlwaysReturnType(returnType, nullable),
  );

  if (decl is FunctionDeclaration && decl.isGetter) {
    return CallResolver(ctx).invokeOperator(fn, null, []).result;
  }
  return fn;
}

DirectCall? _declarationToDirectCall(
  DeclarationOrBridge decOrBridge,
  String name,
  CompilerContext ctx, [
  AstNode? source,
]) {
  if (decOrBridge.isBridge) {
    // No static dispatch for bridge
    return null;
  }

  final decl = decOrBridge.declaration!;

  if (decl is! FunctionDeclaration && decl is! ConstructorDeclaration) {
    if (decl is! ClassDeclaration) {
      // Variables, enums and other non-function decls have no static
      // dispatch target.
      return null;
    }

    final offset = DeferredOrOffset(
      file: decOrBridge.sourceLib,
      name: '$name.',
    );

    final rt = AlwaysReturnType(
      TypeRef.lookupDeclaration(ctx, decOrBridge.sourceLib, decl),
      false,
    );

    return DirectCall(offset, rt);
  }

  TypeRef? returnType;
  var nullable = true;
  if (decl is FunctionDeclaration && decl.returnType != null) {
    returnType = TypeRef.fromAnnotation(
      ctx,
      decOrBridge.sourceLib,
      decl.returnType!,
    );
    nullable = decl.returnType!.question != null;
  } else if (decl is ConstructorDeclaration) {
    returnType = TypeRef.lookupDeclaration(
      ctx,
      decOrBridge.sourceLib,
      decl.parent!.parent as ClassDeclaration,
    );
  } else {
    // A function without a return type annotation returns dynamic.
    returnType = CoreTypes.dynamic.ref(ctx);
  }

  // Accessors compile under `*g`/`*s` keys — use the accessor's own key so
  // deferred resolution finds the right function entry.
  final offset = DeferredOrOffset(
    file: decOrBridge.sourceLib,
    name: decl is FunctionDeclaration
        ? (decl.isGetter
              ? MemberName.getter(decl.name.lexeme).key
              : decl.isSetter
              ? MemberName.setter(decl.name.lexeme).key
              : name)
        : name,
  );

  return DirectCall(offset, AlwaysReturnType(returnType, nullable));
}

/// Loads a top-level (or static field) global by its qualified [globalName],
/// using [valueName] (defaults to the unqualified name) for the SSA variable.
Variable _loadGlobalVariable(
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
    rep: Abi.unboxedAcrossCalls(type),
  );
}

/// A `Type` literal variable for [type]. [constructorKey] is the name used in
/// [DeferredOrOffset] to resolve the constructor (e.g. `ClassName.` or, for
/// bridged enums, `EnumName#wrap`).
Variable _typeLiteral(
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
    concreteTypes: [type],
    methodOffset: DeferredOrOffset(file: type.file, name: constructorKey),
    methodReturnType: AlwaysReturnType(type, false),
  );
}

/// The declared type of instance member [name] on the enclosing class, or null
/// when the current class has no such member.
TypeRef? _resolveInstanceFieldType(
  CompilerContext ctx,
  String name, {
  bool forSet = false,
  AstNode? source,
}) {
  final instanceDeclaration = resolveInstanceDeclaration(
    ctx,
    ctx.library,
    ctx.currentClassName!,
    name,
  );
  if (instanceDeclaration == null) return null;
  return TypeRef.lookupFieldType(
        ctx,
        instanceDeclaration.$1,
        name,
        forSet: forSet,
        source: source,
      ) ??
      CoreTypes.dynamic.ref(ctx);
}

/// Resolves [name] to a top-level declaration visible in the current library.
/// Throws [PrefixError] when the name resolves to an import prefix rather than
/// a concrete declaration.
DeclarationOrBridge _lookupVisibleValue(
  CompilerContext ctx,
  String name,
  AstNode? source, {
  bool forSet = false,
}) {
  final visible = ctx.visibleDeclarations[ctx.library]!;
  Map<String, DeclarationOrBridge>? children;
  var key = name;
  // `prefix.member` — descend into the prefix's children.
  if (name.contains('.')) {
    final split = name.split('.');
    final prefixEntry = visible[split[0]];
    if (prefixEntry != null &&
        prefixEntry.declaration == null &&
        prefixEntry.children != null) {
      children = prefixEntry.children;
      key = split.sublist(1).join('.');
    }
  }
  // Top-level accessors register under `*g`/`*s` — reads prefer the getter
  // key, writes the setter key, falling back to the plain name (variables,
  // functions, classes).
  DeclarationOrBridge? found;
  if (children != null) {
    found = forSet
        ? children[MemberName.setter(key).key] ?? children[key]
        : children[MemberName.getter(key).key] ?? children[key];
  } else {
    found = forSet
        ? visible[MemberName.setter(key).key]?.declaration ?? visible[key]?.declaration
        : visible[MemberName.getter(key).key]?.declaration ?? visible[key]?.declaration;
  }
  if (found == null) {
    if (children == null && visible[key] != null) {
      throw PrefixError();
    }
    throw CompileError('Could not find declaration "$name"', source);
  }
  return found;
}

/// The declared type of a setter's `value` parameter, or null when the
/// parameter list is empty or untyped.
TypeRef? _setterValueType(
  CompilerContext ctx,
  int file,
  FormalParameterList? parameters,
) {
  final param = parameters?.parameters.firstOrNull;
  if (param == null || param.type == null) return null;
  return formalParameterAnnotationType(ctx, file, param);
}

/// Emits a `Call` to a setter taking [value] as its argument. The value is
/// first converted to the setter's declared parameter type (which can apply
/// coercions like the implicit `.call` tear-off), then adapted to the
/// parameter's representation across the call boundary. Returns the converted
/// variable — the assignment expression's value.
Variable _invokeSetter(
  CompilerContext ctx,
  DeferredOrOffset offset,
  Variable value,
  int file,
  FormalParameterList? parameters, {
  required bool isMethod,
  AstNode? source,
}) {
  final paramType = _setterValueType(ctx, file, parameters);
  final converted = paramType == null
      ? value
      : convertForAssignment(
          ctx,
          value,
          paramType,
          representation: isMethod
              ? MachineRepresentation.object
              : Abi.unboxedAcrossCalls(paramType).bank,
          source: source,
        );
  ctx.pushOp(
    Call(offset, [
      _setterArgument(ctx, converted, file, parameters, isMethod: isMethod).ssa,
    ], result: ctx.svar('setter_result')),
  );
  return converted;
}

/// Adapts [value] to the physical representation a setter's `value` parameter
/// travels in across the call boundary. A direct `Call` constrains argument
/// representations to the callee signature, so the caller must emit the
/// conversion itself. Method parameters are always boxed (bridge interop);
/// top-level function parameters travel in their boundary representation
/// (unboxed `int`/`double`/`bool`, boxed otherwise).
Variable _setterArgument(
  CompilerContext ctx,
  Variable value,
  int file,
  FormalParameterList? parameters, {
  required bool isMethod,
}) {
  if (isMethod) {
    return value.boxIntoFreshSlot(ctx);
  }
  final paramType = _setterValueType(ctx, file, parameters);
  final rep = Abi.unboxedAcrossCalls(
    paramType ?? CoreTypes.dynamic.ref(ctx),
  ).bank;
  return rep == MachineRepresentation.object
      ? value.boxIntoFreshSlot(ctx)
      : value.unboxIfNeeded(ctx, false);
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
  final keys = forSet ? [name, MemberName.setter(name).key] : [name, MemberName.getter(name).key];
  for (final key in keys) {
    if (resolveInstanceDeclaration(
          ctx,
          type.file,
          type.name,
          key,
          instantiated: type,
        ) !=
        null) {
      return true;
    }
  }
  return false;
}

bool _hasReceiverMember(
  CompilerContext ctx,
  Variable receiver,
  String name, {
  bool forSet = false,
  AstNode? source,
}) {
  final resolvedReceiver = ctx.typeSystem.throughTypeParameters(receiver.type);
  if (resolvedReceiver.isSpec(CoreTypes.dynamic)) return true;
  if (TypeRef.lookupFieldType(
        ctx,
        resolvedReceiver,
        name,
        forSet: forSet,
        source: source,
      ) !=
      null) {
    return true;
  }
  if (hasInstanceMember(ctx, resolvedReceiver, name, forSet: forSet)) {
    return true;
  }
  return resolveExtensionMember(
            ctx,
            resolvedReceiver,
            name,
            getter: !forSet,
            setter: forSet,
          ) !=
          null ||
      resolveExtensionMember(ctx, resolvedReceiver, name) != null;
}
