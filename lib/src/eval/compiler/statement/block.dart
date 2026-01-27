import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/model/label.dart';

import '../context.dart';
import 'statement.dart';
import '../type.dart';

StatementInfo compileBlock(
    Block b, AlwaysReturnType? expectedReturnType, CompilerContext ctx,
    {String name = '<block>', bool skipClassBoxing = false}) {
  final position = ctx.out.length;
  ctx.beginAllocScope();

  var willAlwaysReturn = false;
  var willAlwaysThrow = false;

  ctx.labels.add(SimpleCompilerLabel());
  for (final s in b.statements) {
    final stInfo = compileStatement(s, expectedReturnType, ctx, skipClassBoxing: skipClassBoxing);

    if (stInfo.willAlwaysThrow) {
      willAlwaysThrow = true;
      break;
    }
    if (stInfo.willAlwaysReturn) {
      willAlwaysReturn = true;
      break;
    }
  }
  ctx.labels.removeLast();

  ctx.endAllocScope(popValues: !willAlwaysThrow && !willAlwaysReturn);

  return StatementInfo(position,
      willAlwaysReturn: willAlwaysReturn, willAlwaysThrow: willAlwaysThrow);
}
