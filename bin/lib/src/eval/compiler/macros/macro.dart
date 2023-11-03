import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

typedef MacroClosure = Function(CompilerContext ctx);
typedef MacroVariableClosure = Variable Function(CompilerContext ctx);
typedef MacroStatementClosure = StatementInfo Function(
    CompilerContext ctx, AlwaysReturnType? expectedReturnType);
