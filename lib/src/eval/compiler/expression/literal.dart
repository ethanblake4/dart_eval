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
import '../helpers/context_type.dart';
import '../errors.dart';
import '../variable.dart';

BuiltinValue parseConstLiteral(
  Literal l,
  CompilerContext ctx, [
  TypeRef? bound,
]) {
  if (l is IntegerLiteral) {
    if (bound != null) {
      bound = inferContextType(ctx, CoreTypes.int.ref(ctx), bound);
    }
    if (bound != null && bound.isSpec(CoreTypes.double)) {
      return BuiltinValue(doubleval: _integerAsDouble(l));
    }
    if (l.value == null) {
      throw CompileError('Integer literal is outside the int range', l);
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

double _integerAsDouble(IntegerLiteral literal) {
  final value = literal.value;
  if (value != null && value >= 0 && value.bitLength <= 53) {
    return value.toDouble();
  }
  final BigInt integer;
  if (value != null && value >= 0) {
    integer = BigInt.from(value);
  } else {
    // High-bit hex tokens wrap as signed int; wide decimals have no int value.
    final lexeme = literal.literal.lexeme.replaceAll('_', '');
    final isHex = lexeme.startsWith('0x') || lexeme.startsWith('0X');
    integer = isHex
        ? BigInt.parse(lexeme.substring(2), radix: 16)
        : BigInt.parse(lexeme);
  }
  final result = integer.toDouble();
  if (!result.isFinite || BigInt.from(result) != integer) {
    throw CompileError(
      'Integer literal is not exactly representable as double',
      literal,
    );
  }
  return result;
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
    return compileListLiteral(l, ctx, bound);
  }
  if (l is SetOrMapLiteral) {
    return compileSetOrMapLiteral(l, ctx, bound);
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
    return compileRecordLiteral(l, ctx, bound);
  }
  throw CompileError('Unknown literal type ${l.runtimeType}');
}
