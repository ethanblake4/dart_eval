import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/method_invocation.dart';
import 'package:dart_eval/src/eval/compiler/helpers/argument_list.dart';
import 'package:dart_eval/src/eval/compiler/helpers/const.dart';
import 'package:dart_eval/src/eval/compiler/dispatch.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/bridge.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import '../values/value_rep.dart';

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

  if ($resolved.concreteTypes.isEmpty) {
    throw CompileError('Cannot create instance of a non-type $typeName');
  }

  var staticType = $resolved.concreteTypes.first;
  var instantiatedType = staticType.copyWith(nullable: type.question != null);
  // A typedef instantiation (`P1()` where `P1 = B2<int>`) constructs the
  // aliased type directly — typedefs register no constructors of their own.
  final aliasDecl = ctx
      .topLevelDeclarationsMap[staticType.file]![staticType.name]
      ?.declaration;
  if (aliasDecl is TypeAlias && aliasDecl is! ClassTypeAlias) {
    instantiatedType = staticType =
        resolveTypeAlias(
          ctx,
          staticType.file,
          aliasDecl,
          nullable: type.question != null,
          typeArgs: type.typeArguments?.arguments,
        ).copyWith(
          specifiedTypeArgs: [
            if (type.typeArguments == null) ...staticType.specifiedTypeArgs,
          ],
        );
  }
  if (type.typeArguments != null) {
    instantiatedType = instantiatedType.copyWith(
      specifiedTypeArgs: [
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
        boundChain.specifiedTypeArgs.isNotEmpty) {
      instantiatedType = instantiatedType.copyWith(
        specifiedTypeArgs: boundChain.specifiedTypeArgs,
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
    var result = ctx.svar('instance');
    ctx.pushOp(
      Call(
        DeferredOrOffset.lookupStatic(
          ctx,
          staticType.file,
          staticType.name,
          name,
        ),
        [pushRuntimeTypeId(ctx, instantiatedType)],
        result: result,
      ),
    );
    if (isConst) {
      result = pushInternConst(ctx, result, instantiatedType);
    }
    return Variable.of(
      ctx,
      result,
      instantiatedType,
      rep: ValueRep.boxed,
      concreteTypes: [instantiatedType],
      exactType: instantiatedType,
    );
  }

  final dec0 = resolveStaticMethod(ctx, staticType, name);

  final ArgumentListResult arguments;

  if (dec0.isBridge) {
    final bridge = dec0.bridge;
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
    if (genericNames.isNotEmpty && instantiatedType.specifiedTypeArgs.isEmpty) {
      // Parameter annotations compile permissively (`T` → dynamic); the real
      // bindings are inferred from the argument types below.
      argTypeParameters = {
        for (final name in genericNames) name: CoreTypes.dynamic.ref(ctx),
      };
    }
    arguments = compileArgumentListWithBridge(
      ctx,
      argumentList,
      fnDescriptor,
      typeParameters: argTypeParameters,
    );

    if (genericNames.isNotEmpty && instantiatedType.specifiedTypeArgs.isEmpty) {
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
      final substitutions = Substitution.wrap(<TypeParameterDef, TypeRef>{});
      // Bridge parameters carry no named flag; named args ride at the tail.
      final positionalParams = fnDescriptor.params;
      for (
        var i = 0;
        i < arguments.args.length && i < positionalParams.length;
        i++
      ) {
        final pattern = TypeRef.fromBridgeAnnotation(
          ctx,
          positionalParams[i].type,
          typeParameters: paramRefs,
        );
        final concrete =
            ctx.typeSystem.asInstanceOf(arguments.args[i].type, pattern.decl) ??
            arguments.args[i].type;
        ctx.typeSystem.unify(pattern, concrete, substitutions);
      }
      instantiatedType = instantiatedType.copyWith(
        specifiedTypeArgs: [
          for (var i = 0; i < genericNames.length; i++)
            substitutions[paramRefs[genericNames[i]]!.parameter!] ??
                CoreTypes.dynamic.ref(ctx),
        ],
      );
    }
  } else {
    final dec = dec0.declaration!;
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
          resolvedChain.file == dec0.sourceLib &&
              ctorDecl != null &&
              resolvedChain.name == declarationName(ctorDecl as Declaration)
          ? resolvedChain.specifiedTypeArgs
          : instantiatedType.specifiedTypeArgs;
      for (var i = 0; i < classTypeParams.length; i++) {
        final bound = classTypeParams[i].bound;
        seedGenerics[classTypeParams[i].name.lexeme] = i < appliedArgs.length
            ? appliedArgs[i]
            : bound == null
            ? CoreTypes.dynamic.ref(ctx)
            : TypeRef.fromAnnotation(
                ctx,
                dec0.sourceLib,
                bound,
                typeParameters: seedGenerics,
              );
      }
    }

    arguments = compileArgumentList(
      ctx,
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

  var result = ctx.svar('instance');
  // A factory may return any subtype — the result is not exactly the
  // declared class.
  final isFactory =
      !dec0.isBridge &&
      (dec0.declaration! as ConstructorDeclaration).factoryKeyword != null;
  if (dec0.isBridge) {
    final classBridge =
        ctx.topLevelDeclarationsMap[staticType.file]![staticType.name]?.bridge;
    final externalId =
        ctx.bridgeStaticFunctionIndices[staticType
            .file]!['${staticType.name}.$name']!;
    if (classBridge is BridgeClassDef && !classBridge.wrap) {
      final subclass = BuiltinValue().push(ctx);
      ctx.pushOp(
        BridgeInstantiate(
          result,
          externalId,
          subclass.ssa,
          arguments.ssa,
          runtimeTypeId: ctx.runtimeTypes.idOf(staticType),
        ),
      );
    } else {
      ctx.pushOp(InvokeExternal(result, externalId, arguments.ssa));
    }
  } else {
    final constructor = dec0.declaration! as ConstructorDeclaration;
    final offset = DeferredOrOffset.lookupStatic(
      ctx,
      staticType.file,
      staticType.name,
      name,
    );
    final callArguments = [...arguments.ssa];
    // Enum constructors carry two synthetic leading parameters (index,
    // name) bound by the enum's own value materialization; direct calls —
    // only factories are reachable — bind them to null.
    if (constructor.parent?.parent is EnumDeclaration) {
      callArguments.insertAll(0, [
        BuiltinValue().push(ctx).ssa,
        BuiltinValue().push(ctx).ssa,
      ]);
    }
    if (constructor.factoryKeyword == null) {
      callArguments.add(pushRuntimeTypeId(ctx, instantiatedType));
    }
    ctx.pushOp(
      Call(
        offset,
        callArguments,
        result: result,
        // Factories have no receiver, so the class's instantiated type
        // arguments are delivered through the callable-type-argument channel.
        typeArguments: constructor.factoryKeyword != null
            ? [
                for (final arg in instantiatedType.specifiedTypeArgs)
                  ctx.runtimeTypes.idOf(arg),
              ]
            : const [],
      ),
    );
  }
  if (isConst) {
    result = pushInternConst(ctx, result, instantiatedType);
  }
  return Variable.of(
    ctx,
    result,
    instantiatedType,
    rep: ValueRep.boxed,
    concreteTypes: [instantiatedType],
    exactType: isFactory ? null : instantiatedType,
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
