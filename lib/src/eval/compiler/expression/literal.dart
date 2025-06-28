import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/collection/list.dart';
import 'package:dart_eval/src/eval/compiler/collection/set_map.dart';
import 'package:dart_eval/src/eval/compiler/expression/adjacent_strings.dart';
import 'package:dart_eval/src/eval/compiler/expression/record.dart';
import 'package:dart_eval/src/eval/compiler/expression/string_interpolation.dart';
import 'package:dart_eval/src/eval/compiler/expression/symbol.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/shared/types.dart';

import '../builtins.dart';
import '../context.dart';
import '../errors.dart';
import '../variable.dart';

BuiltinValue parseConstLiteral(Literal l, CompilerContext ctx,
    [TypeRef? bound]) {
  if (l is IntegerLiteral) {
    if (bound != null && bound == CoreTypes.double.ref(ctx)) {
      return BuiltinValue(doubleval: l.value!.toDouble());
    }
    return BuiltinValue(intval: l.value);
  } else if (l is DoubleLiteral) {
    return BuiltinValue(doubleval: l.value);
  } else if (l is SimpleStringLiteral) {
    return BuiltinValue(stringval: l.stringValue);
  } else if (l is BooleanLiteral) {
    return BuiltinValue(boolval: l.value);
  } else if (l is NullLiteral) {
    return BuiltinValue();
  }
  throw CompileError('Unknown constant literal type ${l.runtimeType}');
}

Variable parseLiteral(Literal l, CompilerContext ctx, [TypeRef? bound]) {
  if (l is IntegerLiteral ||
      l is DoubleLiteral ||
      l is SimpleStringLiteral ||
      l is NullLiteral ||
      l is BooleanLiteral) {
    return parseConstLiteral(l, ctx, bound).push(ctx);
  }
  if (l is ListLiteral) {
    return compileListLiteral(l, ctx);
  }
  if (l is SetOrMapLiteral) {
    return compileSetOrMapLiteral(l, ctx);
  }
  if (l is StringInterpolation) {
    return compileStringInterpolation(ctx, l);
  }
  if (l is AdjacentStrings) {
    return compileAdjacentStrings(ctx, l);
  }
  if (l is SymbolLiteral) {
    return compileSymbolLiteral(l, ctx);
  }
  if (l is RecordLiteral) {
    return compileRecordLiteral(l, ctx);
  }
  throw CompileError('Unknown literal type ${l.runtimeType}');
}
