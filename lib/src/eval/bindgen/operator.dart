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
