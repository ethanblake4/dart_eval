import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/collection/list.dart';
import 'package:dart_eval/src/eval/compiler/collection/set_map.dart';

import '../builtins.dart';
import '../context.dart';
import '../errors.dart';
import '../variable.dart';

BuiltinValue parseConstLiteral(Literal l, CompilerContext ctx) {
  if (l is IntegerLiteral) {
    return BuiltinValue(intval: l.value);
  } else if (l is SimpleStringLiteral) {
    return BuiltinValue(stringval: l.stringValue);
  } else if (l is NullLiteral) {
    return BuiltinValue();
  }
  throw CompileError('Unknown constant literal type ${l.runtimeType}');
}

Variable parseLiteral(Literal l, CompilerContext ctx) {
  if (l is IntegerLiteral || l is SimpleStringLiteral || l is NullLiteral) {
    return parseConstLiteral(l, ctx).push(ctx);
  }
  if (l is ListLiteral) {
    return compileListLiteral(l, ctx);
  }
  if (l is SetOrMapLiteral) {
    return compileSetOrMapLiteral(l, ctx);
  }
  throw CompileError('Unknown literal type ${l.runtimeType}');
}
