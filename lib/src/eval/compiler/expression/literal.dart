import 'package:analyzer/dart/ast/ast.dart';

import '../builtins.dart';
import '../context.dart';
import '../errors.dart';

BuiltinValue parseLiteral(Literal l, CompilerContext ctx) {
  if (l is IntegerLiteral) {
    return BuiltinValue(intval: l.value);
  } else if (l is SimpleStringLiteral) {
    return BuiltinValue(stringval: l.stringValue);
  } else if (l is NullLiteral) {
    return BuiltinValue();
  }
  throw CompileError('Unknown literal type ${l.runtimeType}');
}