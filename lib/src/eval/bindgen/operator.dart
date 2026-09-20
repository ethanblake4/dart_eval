import 'package:analyzer/dart/element/element.dart';

abstract class OperatorMethod {
  String get name;
  String format(String obj, List<String> args);
}

class FunctionOperator implements OperatorMethod {
  @override
  final String name;

  const FunctionOperator(this.name);

  @override
  String format(String obj, List<String> args) {
    return '$obj.$name(${args.join(', ')})';
  }
}

class BinaryOperator implements OperatorMethod {
  final String op;

  @override
  final String name;

  const BinaryOperator(this.op, this.name);

  @override
  String format(String obj, List<String> args) {
    return '($obj $op ${args[0]})';
  }
}

class UnaryOperator implements OperatorMethod {
  final String op;

  @override
  final String name;

  const UnaryOperator(this.op, this.name);

  @override
  String format(String obj, List<String> args) {
    return '$op$obj';
  }
}

class IndexGetOperator implements OperatorMethod {
  @override
  final String name;

  const IndexGetOperator(this.name);

  @override
  String format(String obj, List<String> args) {
    return '$obj[${args[0]}]';
  }
}

class IndexSetOperator implements OperatorMethod {
  @override
  final String name;

  const IndexSetOperator(this.name);

  @override
  String format(String obj, List<String> args) {
    return '$obj[${args[0]}] = ${args[1]}';
  }
}

OperatorMethod resolveMethodOperator(String name) =>
    kOperatorNames[name] ?? FunctionOperator(name);

/// Adjust an [OperatorMethod] for a method's actual arity. A binary operator
/// declared with zero parameters is the unary form (e.g. `operator -()`).
OperatorMethod operatorForArity(String name, int paramCount) {
  final op = resolveMethodOperator(name);
  if (op is BinaryOperator && paramCount == 0) {
    return UnaryOperator(op.op, '${op.name}Unary');
  }
  return op;
}

/// Whether [method]'s arity matches the operator it declares. Non-operator
/// methods always match.
bool operatorArityMatches(MethodElement method) {
  final op = kOperatorNames[method.name];
  if (op == null) return true;
  return switch (op) {
    BinaryOperator() => method.formalParameters.length == 1,
    UnaryOperator() => method.formalParameters.isEmpty,
    IndexGetOperator() => method.formalParameters.length == 1,
    IndexSetOperator() => method.formalParameters.length == 2,
    _ => true,
  };
}

/// Collapse [methods] by name, preferring the variant whose arity matches the
/// declared operator when a class has both forms (e.g. `Duration.operator-`
/// and `Duration.operator-()`). Among equally-valid candidates the last
/// occurrence wins so declarations on [element] override supertypes when the
/// iterable lists supertype members first.
Iterable<MethodElement> dedupeMethods(Iterable<MethodElement> methods) {
  final map = <String?, MethodElement>{};
  for (final m in methods) {
    final prev = map[m.name];
    if (prev == null ||
        operatorArityMatches(m) ||
        !operatorArityMatches(prev)) {
      map[m.name] = m;
    }
  }
  return map.values;
}

// https://dart.dev/language/methods#operators
final kOperatorNames = <String, OperatorMethod>{
  '<': BinaryOperator('<', 'operatorLt'),
  '>': BinaryOperator('>', 'operatorGt'),
  '<=': BinaryOperator('<=', 'operatorLte'),
  '>=': BinaryOperator('>=', 'operatorGte'),
  '==': BinaryOperator('==', 'operatorEq'),
  '~': UnaryOperator('~', 'operatorBitNot'),
  '-': BinaryOperator('-', 'operatorMinus'),
  '+': BinaryOperator('+', 'operatorPlus'),
  '/': BinaryOperator('/', 'operatorDiv'),
  '~/': BinaryOperator('~/', 'operatorIntDiv'),
  '*': BinaryOperator('*', 'operatorMul'),
  '%': BinaryOperator('%', 'operatorMod'),
  '|': BinaryOperator('|', 'operatorBitOr'),
  '^': BinaryOperator('^', 'operatorBitXor'),
  '&': BinaryOperator('&', 'operatorBitAnd'),
  '<<': BinaryOperator('<<', 'operatorShl'),
  '>>': BinaryOperator('>>', 'operatorShr'),
  '>>>': BinaryOperator('>>>', 'operatorUshr'),
  '[]=': IndexSetOperator('operatorIndexSet'),
  '[]': IndexGetOperator('operatorIndexGet'),
};
