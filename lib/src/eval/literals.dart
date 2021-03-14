import 'package:dart_eval/src/eval/expressions.dart';
import 'package:dart_eval/src/eval/primitives.dart';
import 'package:dart_eval/src/eval/scope.dart';
import 'package:dart_eval/src/eval/value.dart';

class EvalNumLiteral extends EvalExpression {
  EvalNumLiteral(int offset, int length, this.value) : super(offset, length);
  final num value;

  @override
  EvalValue eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    return EvalNum(value);
  }
}

class EvalStringLiteral extends EvalExpression {
  EvalStringLiteral(int offset, int length, this.value) : super(offset, length);
  final String value;

  @override
  EvalValue eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    return EvalString(value);
  }
}

class EvalIntLiteral extends EvalExpression {
  EvalIntLiteral(int offset, int length, this.value) : super(offset, length);
  final int value;

  @override
  EvalValue eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    return EvalInt(value);
  }
}