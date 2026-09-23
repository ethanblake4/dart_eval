import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/member/member.dart';
import 'package:dart_eval/src/eval/compiler/member/member_name.dart';
import '../invocation/deferred.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/compiler/invocation/bound_call.dart';
import '../invocation/binder.dart';
import 'package:dart_eval/src/eval/compiler/invocation/targets.dart';

Variable compileInstanceCreation(
  CompilerContext ctx,
  InstanceCreationExpression e, [
  TypeRef? bound,
]) {
  final type = e.constructorName.type;
  final (typeName, name) = splitConstructorTypeName(
    ctx,
    ctx.library,
    type,
    e.constructorName.name?.name,
  );
  final $resolved = IdentifierReference(null, typeName).getValue(ctx);
  final receiver = receiverOf(ctx, $resolved);

  if (receiver is! TypeLiteralReceiver) {
    throw CompileError('Cannot create instance of a non-type $typeName');
  }

  var staticType = receiver.type;
  var instantiatedType = staticType.withNullable(type.question != null);
  // A typedef instantiation (`P1()` where `P1 = B2<int>`) constructs the
  // aliased type directly — typedefs register no constructors of their own.
  final aliasDecl = ctx
      .topLevelDeclarationsMap[staticType.file]![staticType.name]
      ?.declaration;
  if (aliasDecl is TypeAlias && aliasDecl is! ClassTypeAlias) {
    instantiatedType = staticType =
        (resolveTypeAlias(
              ctx,
              staticType.file,
              aliasDecl,
              nullable: type.question != null,
              typeArgs: type.typeArguments?.arguments,
            )
                as InterfaceTypeRef)
            .copyWith(
          arguments: [
            if (type.typeArguments == null) ...staticType.typeArguments,
          ],
        );
  }
  if (type.typeArguments != null) {
    instantiatedType = (instantiatedType as InterfaceTypeRef).copyWith(
      arguments: [
        for (final arg in type.typeArguments!.arguments)
          TypeRef.fromAnnotation(ctx, ctx.library, arg),
      ],
    );
  } else if (bound != null) {
    // Downward inference: `Optional.absent()` under `Optional<int>` produces
    // `Optional<int>`.
    final boundChain = bound;
    if (boundChain.file == staticType.file &&
        boundChain.name == staticType.name &&
        boundChain.typeArguments.isNotEmpty) {
      instantiatedType = (instantiatedType as InterfaceTypeRef).copyWith(
        arguments: boundChain.typeArguments,
      );
    }
  }

  return compileInstanceOf(
    ctx,
    staticType: staticType,
    instantiatedType: instantiatedType,
    name: name,
    argumentList: e.argumentList,
    isConst: e.isConst,
    source: e,
  );
}

/// Emits the `staticType.name(...)` constructor invocation shared by
/// `InstanceCreationExpression` and the `.name(...)` dot shorthand.
/// [staticType] is the declaring class; [instantiatedType] carries the
/// applied type arguments delivered to the callee.
Variable compileInstanceOf(
  CompilerContext ctx, {
  required TypeRef staticType,
  required TypeRef instantiatedType,
  required String name,
  required ArgumentList argumentList,
  required bool isConst,
  required AstNode source,
}) {
  // A class that declares no constructors gets a synthesized `Name.` body
  // taking only the runtime-type argument, with no lookup-table entry.
  if (name.isEmpty &&
      ctx.topLevelDeclarationsMap[staticType
              .file]!['${staticType.name}.$name'] ==
          null &&
      _hasImplicitDefaultConstructor(ctx, staticType)) {
    return ConstructorCall(
      staticType: staticType,
      instantiatedType: instantiatedType,
      name: name,
      offset: DeferredOrOffset.lookupStatic(
        ctx,
        staticType.file,
        staticType.name,
        name,
      ),
      isConst: isConst,
      implicitDefault: true,
    ).emit(
      ctx,
      BoundCall(
        positional: const [],
        named: const [],
        returnType: instantiatedType,
      ),
    );
  }

  final resolved = ctx.memberLookup.staticMember(
        staticType,
        name,
        MemberKind.method,
      ) ??
      (throw CompileError('Cannot find static method $staticType.$name'));

  final BoundCall arguments;

  if (resolved is BridgeMember) {
    final bridge = resolved.def;
    // Const factories are also exposed as static methods on some bindings
    // (e.g. `bool.hasEnvironment`); both defs carry a functionDescriptor.
    final fnDescriptor = switch (bridge) {
      BridgeConstructorDef d => d.functionDescriptor,
      BridgeMethodDef d => d.functionDescriptor,
      _ => throw CompileError(
        'Cannot invoke $staticType.$name as a constructor',
        source,
      ),
    };
    final classBridge =
        ctx.topLevelDeclarationsMap[staticType.file]![staticType.name]?.bridge;
    final genericNames = classBridge is BridgeClassDef
        ? classBridge.type.generics.keys.toList()
        : const <String>[];
    Map<String, TypeRef> argTypeParameters = const {};
    if (genericNames.isNotEmpty && instantiatedType.typeArguments.isEmpty) {
      // Parameter annotations compile permissively (`T` → dynamic); the real
      // bindings are inferred from the argument types below.
      argTypeParameters = {
        for (final name in genericNames) name: CoreTypes.dynamic.ref(ctx),
      };
    }
    arguments = ArgumentBinder(ctx).bindBridgeVector(
      argumentList,
      fnDescriptor,
      typeParameters: argTypeParameters,
    );

    if (genericNames.isNotEmpty && instantiatedType.typeArguments.isEmpty) {
      final paramRefs = {
        for (var i = 0; i < genericNames.length; i++)
          genericNames[i]: TypeParameterTypeRef(
            TypeParameterDef(
              TypeParameterOwner(
                TypeParameterOwnerKind.classLike,
                staticType.file,
                staticType.name,
              ),
              i,
              genericNames[i],
            ),
            file: staticType.file,
          ),
      };
      final bindings = <TypeParameterDef, TypeRef>{};
      // Bridge parameters carry no named flag; named args ride at the tail.
      final positionalParams = fnDescriptor.params;
      for (
        var i = 0;
        i < arguments.positionalValues.length && i < positionalParams.length;
        i++
      ) {
        final pattern = TypeRef.fromBridgeAnnotation(
          ctx,
          positionalParams[i].type,
          typeParameters: paramRefs,
        );
        final concrete =
            ctx.typeSystem.asInstanceOf(arguments.positionalValues[i].type, pattern.decl) ??
            arguments.positionalValues[i].type;
        ctx.typeSystem.unify(pattern, concrete, bindings);
      }
      instantiatedType = (instantiatedType as InterfaceTypeRef).copyWith(
        arguments: [
          for (var i = 0; i < genericNames.length; i++)
            bindings[paramRefs[genericNames[i]]!.parameter] ??
                CoreTypes.dynamic.ref(ctx),
        ],
      );
    }
  } else {
    final dec = (resolved as SourceMember).node;
    final fpl = (dec as ConstructorDeclaration).parameters.parameters;

    // Constructor signatures reference the declaring class's type parameters —
    // the callee's class (`B2` for `P1 = B2<int> with M`), not necessarily the
    // invoked name. Seed them from the instantiated type's arguments (or the
    // parameter bounds) so `T`-annotated parameters resolve.
    final ctorDecl = dec.parent?.parent;
    final classTypeParams = ctorDecl is Declaration
        ? classLikeClauses(ctorDecl).$4?.typeParameters
        : null;
    final seedGenerics = <String, TypeRef>{};
    if (classTypeParams != null) {
      final resolvedChain = instantiatedType;
      final appliedArgs =
          resolvedChain.file == resolved.library &&
              ctorDecl != null &&
              resolvedChain.name == declarationName(ctorDecl as Declaration)
          ? resolvedChain.typeArguments
          : instantiatedType.typeArguments;
      for (var i = 0; i < classTypeParams.length; i++) {
        final bound = classTypeParams[i].bound;
        seedGenerics[classTypeParams[i].name.lexeme] = i < appliedArgs.length
            ? appliedArgs[i]
            : bound == null
            ? CoreTypes.dynamic.ref(ctx)
            : TypeRef.fromAnnotation(
                ctx,
                resolved.library,
                bound,
                typeParameters: seedGenerics,
              );
      }
    }

    arguments = ArgumentBinder(ctx).bindParameterList(
      argumentList,
      staticType.file,
      fpl,
      dec,
      source: source,
      resolveGenerics: seedGenerics,
);







    //_args = argsPair.first;
    //_namedArgs = argsPair.second;
  }

  final classBridge =
      ctx.topLevelDeclarationsMap[staticType.file]![staticType.name]?.bridge;
  final target = ConstructorCall(
    staticType: staticType,
    instantiatedType: instantiatedType,
    name: name,
    offset: resolved is BridgeMember
        ? null
        : DeferredOrOffset.lookupStatic(
            ctx,
            staticType.file,
            staticType.name,
            name,
          ),
    constructor: resolved is BridgeMember
        ? null
        : (resolved as SourceMember).node as ConstructorDeclaration,
    isConst: isConst,
    externalIndex: resolved is BridgeMember
        ? ctx.bridgeStaticFunctionIndices[staticType
            .file]!['${staticType.name}.$name']!
        : null,
    classBridge: classBridge is BridgeClassDef ? classBridge : null,
  );
  return target.emit(
    ctx,
    BoundCall(
      positional: const [],
      named: const [],
      returnType: instantiatedType,
      vectorOverride: arguments.vector(),
    ),
  );
}

/// Whether [classType]'s declaration is a class with no declared constructors
/// (and no named primary constructor), so `new C()` calls the synthesized
/// default constructor.
bool _hasImplicitDefaultConstructor(CompilerContext ctx, TypeRef classType) {
  final decl =
      ctx.topLevelDeclarationsMap[classType.file]![classType.name]?.declaration;
  if (decl is ClassTypeAlias) {
    // `C() => S()` — the alias emits a synthesized `C.` exactly when the
    // superclass has no declared unnamed constructor (see
    // [compileClassTypeAlias]); a declared `S.` registers a forwarding `C.`
    // entry instead.
    final superName = classLikeClauses(decl).$1?.name.lexeme;
    if (superName == null) return false;
    return !ctx.topLevelDeclarationsMap[classType.file]!.entries.any(
      (entry) =>
          entry.key == '$superName.' &&
          entry.value.declaration is ConstructorDeclaration,
    );
  }
  if (decl is! ClassDeclaration) return false;
  if (decl.namePart is PrimaryConstructorDeclaration) {
    final primary = decl.namePart as PrimaryConstructorDeclaration;
    if (primary.constructorName != null ||
        primary.formalParameters.parameters.isNotEmpty) {
      return false;
    }
  }
  return !decl.body.members.any((m) => m is ConstructorDeclaration);
}
