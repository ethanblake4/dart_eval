import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/helpers/context_type.dart';
import '../helpers/constructor_type.dart';
import '../helpers/extension_type.dart';
import 'package:dart_eval/src/eval/compiler/member/member.dart';
import 'package:dart_eval/src/eval/compiler/member/member_name.dart';
import '../member/call_signature.dart';
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
  final typeReference = IdentifierReference(null, typeName);
  final $resolved = typeReference.getValue(ctx);
  final receiver = receiverOf(ctx, $resolved);

  if (receiver is! TypeLiteralReceiver) {
    throw CompileError('Cannot create instance of a non-type $typeName');
  }

  var staticType = receiver.type;
  if (e.isConst && bound != null) {
    bound = ctx.typeSystem.constantContextType(bound);
  }
  if (bound != null) bound = inferContextType(ctx, staticType, bound);
  var instantiatedType = staticType.withNullable(type.question != null);
  // A typedef instantiation (`P1()` where `P1 = B2<int>`) constructs the
  // aliased type directly — typedefs register no constructors of their own.
  final aliasDecl = switch (typeReference.denotation(ctx)) {
    TypeLiteralDenotation(:final declaration) => declaration,
    _ => null,
  };
  final isTypeAlias = aliasDecl is TypeAlias && aliasDecl is! ClassTypeAlias;
  if (aliasDecl is TypeAlias && aliasDecl is! ClassTypeAlias) {
    final expanded =
        ctx.typeFactory.resolveTypeAlias(
              ctx.library,
              aliasDecl,
              nullable: type.question != null,
              typeArgs: type.typeArguments?.arguments,
            )
            as InterfaceTypeRef;
    instantiatedType = staticType = type.typeArguments == null
        ? expanded.copyWith(arguments: interfaceArgumentsOf(staticType))
        : expanded;
  }
  if (type.typeArguments != null && !isTypeAlias) {
    instantiatedType = (instantiatedType as InterfaceTypeRef).copyWith(
      arguments: [
        for (final arg in type.typeArguments!.arguments)
          TypeRef.fromAnnotation(ctx, ctx.library, arg),
      ],
    );
  } else if (type.typeArguments == null && bound != null) {
    // Infer a constructor's type arguments from the expected interface, even
    // when the constructed class implements that interface indirectly.
    final declaration = nominalDeclOf(staticType);
    final inferred = constructorContextArguments(ctx, staticType, bound);
    if (inferred.isNotEmpty) {
      instantiatedType = (instantiatedType as InterfaceTypeRef).copyWith(
        arguments: [
          for (final parameter in declaration!.typeParameters)
            inferred[parameter] ?? TypeParameterTypeRef(parameter),
        ],
      );
    }
  }

  return compileInstanceOf(
    ctx,
    staticType: staticType,
    instantiatedType: instantiatedType,
    name: name,
    argumentList: e.argumentList,
    typeArguments: isTypeAlias ? null : type.typeArguments,
    returnContext: bound,
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
  TypeArgumentList? typeArguments,
  TypeRef? returnContext,
  required bool isConst,
  required AstNode source,
}) {
  final declaration = nominalDeclOf(staticType);
  if (declaration is SourceTypeDecl &&
      declaration.kind == TypeDeclKind.extensionType) {
    return constructExtensionType(
      ctx,
      declaration,
      instantiatedType,
      name,
      argumentList,
      isConst: isConst,
      source: source,
    );
  }
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

  final resolved =
      ctx.memberLookup.staticMember(staticType, name, MemberKind.method) ??
      (throw CompileError('Cannot find static method $staticType.$name'));

  late final ConstructorCall target;
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
    // The class's own generics stay as parameters while arguments bind —
    // `Iterable<T>` keeps literal arguments at their natural type (`[1]` →
    // `List<int>`) and the unify below binds `T` from those types. Erasing
    // to `dynamic` here would clamp the literal to `List<dynamic>` first.
    final appliedArguments = interfaceArgumentsOf(instantiatedType);
    final placeholders = genericNames.isEmpty
        ? const <String, TypeParameterTypeRef>{}
        : bridgeClassGenericParameters(ctx, staticType);
    final argTypeParameters = <String, TypeParameterTypeRef>{
      for (var i = 0; i < genericNames.length; i++)
        if (i >= appliedArguments.length ||
            appliedArguments[i] is UnknownTypeRef ||
            appliedArguments[i] == placeholders[genericNames[i]])
          genericNames[i]: TypeParameterTypeRef(
            ctx.typeParameterDefs.key(
              TypeParameterOwner(
                TypeParameterOwnerKind.callSite,
                ctx.library,
                '${staticType.name}.$name',
                source.offset,
              ),
              i,
              genericNames[i],
            ),
          ),
    };
    final argumentTypes = <String, TypeRef>{
      for (var i = 0; i < genericNames.length; i++)
        genericNames[i]:
            argTypeParameters[genericNames[i]] ?? appliedArguments[i],
    };
    target = ConstructorCall(
      staticType: staticType,
      instantiatedType: argTypeParameters.isNotEmpty ? null : instantiatedType,
      name: name,
      isConst: isConst,
      externalIndex:
          ctx.bridgeStaticFunctionIndices[staticType
              .file]!['${staticType.name}.$name']!,
      classBridge: classBridge is BridgeClassDef ? classBridge : null,
      bridgeFunction: fnDescriptor,
      signature: CallSignature.bridge(
        ctx,
        fnDescriptor,
        returnFallback: CoreTypes.dynamic.ref(ctx),
        owner: instantiatedType,
        typeParameters: argumentTypes,
      ),
    );
    arguments = ArgumentBinder(ctx).bindBridgeTarget(target, argumentList);

    if (argTypeParameters.isNotEmpty) {
      final bindings = <TypeParameterDef, TypeRef>{};
      // Bridge parameters carry no named flag; named args ride at the tail.
      final positionalParams = fnDescriptor.params;
      for (
        var i = 0;
        i < arguments.positional.length && i < positionalParams.length;
        i++
      ) {
        final pattern = TypeRef.fromBridgeAnnotation(
          ctx,
          positionalParams[i].type,
          typeParameters: argumentTypes,
        );
        final concrete =
            ctx.typeSystem.asInstanceOf(
              arguments.positional[i].type,
              nominalDeclOf(pattern),
            ) ??
            arguments.positional[i].type;
        ctx.typeSystem.unify(pattern, concrete, bindings);
      }
      instantiatedType = (instantiatedType as InterfaceTypeRef).copyWith(
        arguments: [
          for (var i = 0; i < genericNames.length; i++)
            argTypeParameters.containsKey(genericNames[i])
                ? bindings[argTypeParameters[genericNames[i]]!.parameter] ??
                      CoreTypes.dynamic.ref(ctx)
                : appliedArguments[i],
        ],
      );
    }
  } else {
    final dec = (resolved as SourceMember).node;

    // Constructor signatures reference the declaring class's type parameters —
    // the callee's class (`B2` for `P1 = B2<int> with M`), not necessarily the
    // invoked name. Applied arguments constrain them; omitted arguments remain
    // placeholders until the binder infers them from supplied values.
    final ctorDecl = dec.parent?.parent;
    final classTypeParams = ctorDecl is Declaration
        ? classLikeClauses(ctorDecl).$4?.typeParameters
        : null;
    final seedGenerics = <String, TypeRef>{};
    if (classTypeParams != null) {
      final appliedType = ctx.typeSystem.asInstanceOf(
        instantiatedType,
        ctx.types.find(
          resolved.library,
          declarationName(ctorDecl as Declaration),
        ),
      );
      final appliedArgs = interfaceArgumentsOf(appliedType ?? instantiatedType);
      for (var i = 0; i < classTypeParams.length; i++) {
        if (i < appliedArgs.length) {
          seedGenerics[classTypeParams[i].name.lexeme] = appliedArgs[i];
        }
      }
    }

    target = ConstructorCall(
      staticType: staticType,
      instantiatedType: interfaceArgumentsOf(instantiatedType).isEmpty
          ? null
          : instantiatedType,
      name: name,
      offset: DeferredOrOffset.lookupStatic(
        ctx,
        staticType.file,
        staticType.name,
        name,
      ),
      constructor: dec as ConstructorDeclaration,
      isConst: isConst,
      signature: CallSignature.forDeclaration(ctx, staticType.file, dec),
    );
    arguments = ArgumentBinder(ctx).bindSourceTarget(
      target,
      argumentList,
      source: source,
      seedGenerics: seedGenerics,
      typeArguments: typeArguments,
      returnContext: returnContext,
    );
  }

  return target.emit(
    ctx,
    BoundCall(
      positional: const [],
      named: const [],
      returnType: resolved is SourceMember
          ? arguments.returnType
          : instantiatedType,
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
