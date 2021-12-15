import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/scope.dart';
import 'package:dart_eval/src/eval/compiler/statement/block.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

void compileFunctionDeclaration(FunctionDeclaration d, CompilerContext ctx) {
  ctx.topLevelDeclarationPositions[ctx.library]![d.name.name] = enterScope(ctx, d, d.offset, d.name.name + '()');
  final b = d.functionExpression.body;
  StatementInfo? stInfo;
  if (b is BlockFunctionBody) {
    stInfo = compileBlock(b.block, AlwaysReturnType.fromAnnotation(ctx, ctx.library, d.returnType, dynamicType), ctx,
        name: d.name.name + '()');
  }
  if (stInfo == null || !(stInfo.willAlwaysReturn || stInfo.willAlwaysThrow)) {
    ctx.pushOp(Return.make(-1), Return.LEN);
  }
  exitScope(ctx);
}