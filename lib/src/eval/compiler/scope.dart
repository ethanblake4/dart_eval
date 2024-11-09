import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/bridge.dart';

import 'context.dart';

void beginMethod(
    CompilerContext ctx, AstNode scopeHost, int offset, String name,
    [bool isRoot = false]) {
  if (ctx.hasBegunMethod) {
    final methodBlock = ctx.commitBlock();
    if (ctx.entrypoint) {
      ctx.builder = ctx.builder.merge(methodBlock).root;
    } else {
      ctx.builder = ctx.builder.float(methodBlock).root;
    }
  }
  ctx.funcLabel = name;
  ctx.entrypoint = ctx.entrypoints.contains(scopeHost);
  ctx.hasBegunMethod = true;
}

void setupAsyncFunction(CompilerContext ctx) {
  ctx.setLocal(
      '#completer',
      Variable.ssa(
          ctx,
          InvokeExternal(
              ctx.svar('#completer'),
              ctx.bridgeStaticFunctionIndices[ctx.libraryMap['dart:async']!]![
                  'Completer.']!,
              []),
          AsyncTypes.completer.ref(ctx)));
  ctx.nearestAsyncFrame = ctx.locals.length - 1;
}
