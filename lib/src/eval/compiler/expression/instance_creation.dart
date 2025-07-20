import 'package:analyzer/dart/ast/ast.dart';
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
import 'package:dart_eval/src/eval/runtime/runtime.dart';

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
  final dec0 = resolveStaticMethod(ctx, staticType, name);

  //final List<Variable> _args;
  //final Map<String, Variable> _namedArgs;

  if (dec0.isBridge) {
    final bridge = dec0.bridge;
    final fnDescriptor = (bridge as BridgeConstructorDef).functionDescriptor;
    compileArgumentListWithBridge(ctx, e.argumentList, fnDescriptor);

    //_args = argsPair.first;
    //_namedArgs = argsPair.second;
  } else {
    final dec = dec0.declaration!;
    final fpl = (dec as ConstructorDeclaration).parameters.parameters;

    compileArgumentList(ctx, e.argumentList, staticType.file, fpl, dec,
        source: e);
    //_args = argsPair.first;
    //_namedArgs = argsPair.second;
  }

  //final _argTypes = _args.map((e) => e.type).toList();
  //final _namedArgTypes = _namedArgs.map((key, value) => MapEntry(key, value.type));

  if (dec0.isBridge) {
    final bridge = dec0.bridge!;
    if (bridge is BridgeClassDef && !bridge.wrap) {
      final type = TypeRef.fromBridgeTypeRef(ctx, bridge.type.type);

      final $null = BuiltinValue().push(ctx);
      final op = BridgeInstantiate.make($null.scopeFrameOffset,
          ctx.bridgeStaticFunctionIndices[type.file]!['${type.name}.']!);
      ctx.pushOp(op, BridgeInstantiate.len(op));
    } else {
      final op = InvokeExternal.make(ctx.bridgeStaticFunctionIndices[
          staticType.file]!['${staticType.name}.$name']!);
      ctx.pushOp(op, InvokeExternal.LEN);
      ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
    }
  } else {
    final offset = DeferredOrOffset.lookupStatic(
        ctx, staticType.file, staticType.name, name);
    final loc = ctx.pushOp(Call.make(offset.offset ?? -1), Call.length);
    if (offset.offset == null) {
      ctx.offsetTracker.setOffset(loc, offset);
    }
    ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
  }

  return Variable.alloc(
      ctx, $resolved.concreteTypes.first.copyWith(boxed: true));
}
