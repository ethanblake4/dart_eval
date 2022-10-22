import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/declaration/constructor.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/scope.dart';
import 'package:dart_eval/src/eval/compiler/statement/block.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/util.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

void compileFunctionDeclaration(FunctionDeclaration d, CompilerContext ctx) {
  ctx.runPrescan(d);
  ctx.topLevelDeclarationPositions[ctx.library]![d.name2.value() as String] =
      beginMethod(ctx, d, d.offset, (d.name2.value() as String) + '()');

  final _existingAllocs = d.functionExpression.parameters?.parameters.length ?? 0;
  ctx.beginAllocScope(existingAllocLen: _existingAllocs);
  ctx.scopeFrameOffset += _existingAllocs;
  final resolvedParams = resolveFPLDefaults(ctx, d.functionExpression.parameters!, false, allowUnboxed: true);

  var i = 0;

  for (final param in resolvedParams) {
    final p = param.parameter;
    Variable Vrep;

    p as SimpleFormalParameter;
    var type = EvalTypes.dynamicType;
    if (p.type != null) {
      type = TypeRef.fromAnnotation(ctx, ctx.library, p.type!);
    }
    Vrep = Variable(i, type.copyWith(boxed: !type.isUnboxedAcrossFunctionBoundaries))..name = p.name!.value() as String;

    ctx.setLocal(Vrep.name!, Vrep);

    i++;
  }

  final b = d.functionExpression.body;

  if (b.isAsynchronous) {
    setupAsyncFunction(ctx);
  }

  StatementInfo? stInfo;
  if (b is BlockFunctionBody) {
    stInfo = compileBlock(
        b.block, AlwaysReturnType.fromAnnotation(ctx, ctx.library, d.returnType, EvalTypes.dynamicType), ctx,
        name: (d.name2.value() as String) + '()');
  } else if (b is ExpressionFunctionBody) {
    ctx.beginAllocScope();
    final V = compileExpression(b.expression, ctx);
    ctx.pushOp(Return.make(V.scopeFrameOffset), Return.LEN);
    ctx.endAllocScope();
  } else {
    throw CompileError('Unsupported function body type: ${b.runtimeType}');
  }

  if (stInfo == null || !(stInfo.willAlwaysReturn || stInfo.willAlwaysThrow)) {
    if (b.isAsynchronous) {
      asyncComplete(ctx, -1);
      return;
    }
  }

  ctx.endAllocScope();

  if (stInfo == null || !(stInfo.willAlwaysReturn || stInfo.willAlwaysThrow)) {
    ctx.pushOp(Return.make(-1), Return.LEN);
  }
}
