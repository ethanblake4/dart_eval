import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/source_node_wrapper.dart';
import 'package:dart_eval/src/eval/bridge/declaration.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/identifier.dart';
import 'package:dart_eval/src/eval/compiler/helpers/argument_list.dart';
import 'package:dart_eval/src/eval/compiler/offset_tracker.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

Variable compileInstanceCreation(CompilerContext ctx, InstanceCreationExpression e) {
  final type = e.constructorName.type;
  final name = e.constructorName.name;
  final $resolved = compileIdentifier(type.name, ctx);

  if ($resolved.concreteTypes.isEmpty) {
    throw CompileError('Cannot create instance of a non-type ${type.name.name}');
  }

  final file = $resolved.concreteTypes.first.file;

  final Variable method;
  final DeferredOrOffset? offset;
  DeclarationOrBridge? _dec;

  if (name == null) {
    method = $resolved;
    offset = method.methodOffset ?? (throw CompileError('Trying to instantiate $type, which is not a class'));

    _dec = ctx.topLevelDeclarationsMap[offset.file]![type];
    if (_dec == null || (!_dec.isBridge && _dec.declaration! is ClassDeclaration)) {
      _dec = ctx.topLevelDeclarationsMap[offset.file]![offset.name ?? type.name.name + '.'] ??
          (throw CompileError('Cannot instantiate: The class $type does not have a default constructor'));
    }
  } else {
    method = IdentifierReference($resolved, name.name).getValue(ctx);
    offset = method.methodOffset ?? (throw CompileError('Trying to instantiate $type, which is not a class'));

    _dec = ctx.topLevelDeclarationsMap[offset.file]![type.name.name + '.${name.name}'] ??
        (throw CompileError('Cannot instantiate: The class $type does not have constructor ${name.name}'));
  }

  final List<Variable> _args;
  final Map<String, Variable> _namedArgs;

  if (_dec.isBridge) {
    final bridge = _dec.bridge;
    final fnDescriptor = (bridge as BridgeConstructorDef).functionDescriptor;
    final argsPair = compileArgumentListWithBridge(ctx, e.argumentList, fnDescriptor);

    _args = argsPair.first;
    _namedArgs = argsPair.second;
  } else {
    final dec = _dec.declaration!;
    final fpl = (dec as ConstructorDeclaration).parameters.parameters;

    final argsPair = compileArgumentList(ctx, e.argumentList, file, fpl, dec);
    _args = argsPair.first;
    _namedArgs = argsPair.second;
  }

  final _argTypes = _args.map((e) => e.type).toList();
  final _namedArgTypes = _namedArgs.map((key, value) => MapEntry(key, value.type));

  if (_dec.isBridge) {
    final bridge = _dec.bridge!;
    if (bridge is BridgeClassDef && !bridge.wrap) {
      final type = TypeRef.fromBridgeTypeRef(ctx, bridge.type.type);

      final $null = BuiltinValue().push(ctx);
      final op =
          BridgeInstantiate.make($null.scopeFrameOffset, ctx.bridgeStaticFunctionIndices[type.file]!['${type.name}.']!);
      ctx.pushOp(op, BridgeInstantiate.len(op));
    } else {
      final op = InvokeExternal.make(ctx.bridgeStaticFunctionIndices[offset.file]![offset.name]!);
      ctx.pushOp(op, InvokeExternal.LEN);
      ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
    }
  } else {
    final loc = ctx.pushOp(Call.make(offset.offset ?? -1), Call.LEN);
    if (offset.offset == null) {
      ctx.offsetTracker.setOffset(loc, offset);
    }
    ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
  }

  return Variable.alloc(ctx, $resolved.concreteTypes.first.copyWith(boxed: true));
}
