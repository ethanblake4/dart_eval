import 'package:analyzer/dart/ast/ast.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/method_invocation.dart';
import 'package:dart_eval/src/eval/compiler/helpers/argument_list.dart';
import 'package:dart_eval/src/eval/compiler/offset_tracker.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/bridge.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';
import 'package:dart_eval/src/eval/shared/registers.dart';

Variable compileInstanceCreation(
    CompilerContext ctx, InstanceCreationExpression e) {
  final type = e.constructorName.type;
  final name = type.importPrefix == null
      ? (e.constructorName.name?.name ?? '')
      : type.name2.lexeme;
  final typeName = type.importPrefix?.name.lexeme ?? type.name2.lexeme;
  final $resolved = IdentifierReference(null, typeName).getValue(ctx);

  if ($resolved.concreteTypes.isEmpty) {
    throw CompileError('Cannot create instance of a non-type $typeName');
  }

  final staticType = $resolved.concreteTypes.first;
  final _dec = resolveStaticMethod(ctx, staticType, name);

  ArgumentListResult argListResult;

  if (_dec.isBridge) {
    final bridge = _dec.bridge;
    final fnDescriptor = (bridge as BridgeConstructorDef).functionDescriptor;
    argListResult =
        compileArgumentListWithBridge(ctx, e.argumentList, fnDescriptor);
  } else {
    final dec = _dec.declaration!;
    final fpl = (dec as ConstructorDeclaration).parameters.parameters;

    argListResult = compileArgumentList(
        ctx, e.argumentList, staticType.file, fpl, dec,
        source: e);
  }

  final ssaArgs = argListResult.ssa.map((e) => SSA(e)).toList();

  //final _argTypes = _args.map((e) => e.type).toList();
  //final _namedArgTypes = _namedArgs.map((key, value) => MapEntry(key, value.type));

  final resultType = $resolved.concreteTypes.first.copyWith(boxed: true);
  if (_dec.isBridge) {
    final bridge = _dec.bridge!;
    if (bridge is BridgeClassDef && !bridge.wrap) {
      final type = TypeRef.fromBridgeTypeRef(ctx, bridge.type.type);

      final $null = BuiltinValue().push(ctx);
      return Variable.ssa(
          ctx,
          BridgeInstantiate(
              ctx.svar('bridge_inst'),
              ctx.bridgeStaticFunctionIndices[type.file]!['${type.name}.']!,
              $null.ssa,
              ssaArgs),
          resultType);
    } else {
      return Variable.ssa(
          ctx,
          InvokeExternal(
              ctx.svar('${staticType.name}.${name}_result'),
              ctx.bridgeStaticFunctionIndices[staticType.file]![
                  '${staticType.name}.$name']!,
              ssaArgs),
          resultType);
    }
  } else {
    final offset = DeferredOrOffset.lookupStatic(
        ctx, staticType.file, staticType.name, name);
    ctx.pushOp(Call(offset, ssaArgs));
    return Variable.ssa(
        ctx,
        AssignRegister(ctx.svar('${staticType.name}.${name}_result'), regGPR1),
        resultType);
  }
}
