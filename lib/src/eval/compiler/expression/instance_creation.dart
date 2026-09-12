import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/method_invocation.dart';
import 'package:dart_eval/src/eval/compiler/helpers/argument_list.dart';
import 'package:dart_eval/src/eval/compiler/offset_tracker.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/bridge.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';

Variable compileInstanceCreation(
  CompilerContext ctx,
  InstanceCreationExpression e,
) {
  final type = e.constructorName.type;
  final name = type.importPrefix == null
      ? (e.constructorName.name?.name ?? '')
      : type.name.lexeme;
  final typeName = type.importPrefix?.name.lexeme ?? type.name.lexeme;
  final $resolved = IdentifierReference(null, typeName).getValue(ctx);

  if ($resolved.concreteTypes.isEmpty) {
    throw CompileError('Cannot create instance of a non-type $typeName');
  }

  final staticType = $resolved.concreteTypes.first;
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
        BridgeInstantiate(result, externalId, subclass.ssa, arguments.ssa),
      );
    } else {
      ctx.pushOp(InvokeExternal(result, externalId, arguments.ssa));
    }
  } else {
    final offset = DeferredOrOffset.lookupStatic(
      ctx,
      staticType.file,
      staticType.name,
      name,
    );
    ctx.pushOp(Call(offset, arguments.ssa, result: result));
  }
  return Variable.of(
    ctx,
    result,
    staticType.copyWith(boxed: true),
    concreteTypes: [staticType],
  );
}
