import 'package:analyzer/dart/ast/ast.dart';

import '../context.dart';
import 'statement.dart';
import '../type.dart';

StatementInfo compileBlock(
    Block b, AlwaysReturnType? expectedReturnType, CompilerContext ctx,
    {String name = '<block>'}) {
  final position = ctx.out.length;
  ctx.beginAllocScope();

  var willAlwaysReturn = false;
  var willAlwaysThrow = false;

  for (final s in b.statements) {
    final stInfo = compileStatement(s, expectedReturnType, ctx);

    if (stInfo.willAlwaysThrow) {
      willAlwaysThrow = true;
      break;
    }
    if (stInfo.willAlwaysReturn) {
      willAlwaysReturn = true;
      break;
    }
  }

  ctx.endAllocScope(popValues: !willAlwaysThrow && !willAlwaysReturn);

  return StatementInfo(position,
      willAlwaysReturn: willAlwaysReturn, willAlwaysThrow: willAlwaysThrow);
}
