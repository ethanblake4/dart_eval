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

  var result = StatementInfo();

  for (final s in b.statements) {
    final stInfo = compileStatement(
      s,
      expectedReturnType,
      ctx,
      skipClassBoxing: skipClassBoxing,
    );

    if (!stInfo.canCompleteNormally) {
      result = stInfo;
      break;
    }
  }

  ctx.endScope();

  return result;
}
