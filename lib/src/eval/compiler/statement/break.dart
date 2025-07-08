import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/model/label.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';

StatementInfo compileBreakStatement(BreakStatement s, CompilerContext ctx) {
  if (s.label != null) {
    throw CompileError('Break labels are not currently supported', s);
  }

  final currentState = ctx.saveState();

  var index =
      ctx.labels.lastIndexWhere((label) => label.type == LabelType.loop);

  if (index == -1) {
    index =
        ctx.labels.lastIndexWhere((label) => label.type == LabelType.branch);
  }

  if (index == -1) {
    throw CompileError(
        'Cannot use \'break\' outside of a loop or switch context', s);
  }

  for (var i = ctx.labels.length - 1; i > index; i--) {
    ctx.labels[i].cleanup(ctx);
  }
  final label = ctx.labels[index];
  final offset = label.cleanup(ctx);
  if (!ctx.labelReferences.containsKey(label)) {
    ctx.labelReferences[label] = {};
  }
  ctx.labelReferences[label]!.add(offset);
  ctx.restoreState(currentState);
  return StatementInfo(-1);
}
