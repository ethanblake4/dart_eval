import 'package:analyzer/dart/ast/ast.dart';

import '../context.dart';
import 'statement.dart';
import '../type.dart';

StatementInfo compileBlock(
  Block b,
  TypeRef? expectedReturnType,
  CompilerContext ctx, {
  String name = '<block>',
  bool skipClassBoxing = false,
}) {
  ctx.beginScope();

  var willAlwaysReturn = false;
  var willAlwaysThrow = false;
  var willAlwaysBreak = false;

  for (final s in b.statements) {
    final stInfo = compileStatement(
      s,
      expectedReturnType,
      ctx,
      skipClassBoxing: skipClassBoxing,
    );

    if (stInfo.willAlwaysBreak) {
      willAlwaysBreak = true;
      break;
    }
    if (stInfo.willAlwaysThrow) {
      willAlwaysThrow = true;
      break;
    }
    if (stInfo.willAlwaysReturn) {
      willAlwaysReturn = true;
      break;
    }
  }

  ctx.endScope();

  return StatementInfo(
    willAlwaysReturn: willAlwaysReturn,
    willAlwaysThrow: willAlwaysThrow,
    willAlwaysBreak: willAlwaysBreak,
  );
}
