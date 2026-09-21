import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/method_invocation.dart';
import 'package:dart_eval/src/eval/compiler/helpers/argument_list.dart';
import 'package:dart_eval/src/eval/compiler/dispatch.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/bridge.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';

Variable compileInstanceCreation(
  CompilerContext ctx,
  InstanceCreationExpression e,
) {
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

  final staticType = $resolved.concreteTypes.first;
  var instantiatedType = staticType.copyWith(
    nullable: type.question != null,
  );
  if (type.typeArguments != null) {
    instantiatedType = instantiatedType.copyWith(
      specifiedTypeArgs: [
        for (final arg in type.typeArguments!.arguments)
          TypeRef.fromAnnotation(ctx, ctx.library, arg),
      ],
    );
  }

  // A class that declares no constructors gets a synthesized `Name.` body
  // taking only the runtime-type argument, with no lookup-table entry.
  if (name.isEmpty &&
      ctx.topLevelDeclarationsMap[staticType
              .file]!['${staticType.name}.$name'] ==
          null &&
      _hasImplicitDefaultConstructor(ctx, staticType)) {
    final result = ctx.svar('instance');
    ctx.pushOp(
      Call(
        DeferredOrOffset.lookupStatic(
          ctx,
          staticType.file,
          staticType.name,
          name,
        ),
        [
          BuiltinValue(
            intval: instantiatedType.runtimeTypeId(ctx),
          ).push(ctx).ssa,
        ],
        result: result,
      ),
    );
    return Variable.of(
      ctx,
      result,
      instantiatedType.copyWith(boxed: true),
      concreteTypes: [instantiatedType],
    );
  }

  final dec0 = resolveStaticMethod(ctx, staticType, name);

  final ArgumentListResult arguments;

  if (dec0.isBridge) {
    final bridge = dec0.bridge;
    final fnDescriptor = (bridge as BridgeConstructorDef).functionDescriptor;
    arguments = compileArgumentListWithBridge(
      ctx,
      e.argumentList,
      fnDescriptor,
    );

    //_args = argsPair.first;
    //_namedArgs = argsPair.second;
  } else {
    final dec = dec0.declaration!;
    final fpl = (dec as ConstructorDeclaration).parameters.parameters;

    arguments = compileArgumentList(
      ctx,
      e.argumentList,
      staticType.file,
      fpl,
      dec,
      source: e,
    );
    //_args = argsPair.first;
    //_namedArgs = argsPair.second;
  }

  final result = ctx.svar('instance');
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
          runtimeTypeId: staticType.runtimeTypeId(ctx),
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
    if (constructor.factoryKeyword == null) {
      callArguments.add(
        BuiltinValue(intval: instantiatedType.runtimeTypeId(ctx)).push(ctx).ssa,
      );
    }
    ctx.pushOp(Call(offset, callArguments, result: result));
  }
  return Variable.of(
    ctx,
    result,
    instantiatedType.copyWith(boxed: true),
    concreteTypes: [instantiatedType],
  );
}

/// Whether [classType]'s declaration is a class with no declared constructors
/// (and no named primary constructor), so `new C()` calls the synthesized
/// default constructor.
bool _hasImplicitDefaultConstructor(CompilerContext ctx, TypeRef classType) {
  final decl =
      ctx.topLevelDeclarationsMap[classType.file]![classType.name]?.declaration;
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
