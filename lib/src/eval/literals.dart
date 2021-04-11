import 'package:dart_eval/src/eval/collections.dart';
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

class EvalBoolLiteral extends EvalExpression {
  EvalBoolLiteral(int offset, int length, this.value) : super(offset, length);
  final bool value;

  @override
  EvalValue eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    return EvalBool(value);
  }
}

class EvalListLiteral extends EvalExpression {
  EvalListLiteral(int offset, int length, this.elements) : super(offset, length);

  final List<EvalCollectionElement> elements;

  @override
  EvalValue eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    return EvalList(
        elements.expand<EvalValue<dynamic>>((element) => element is EvalMultiValuedCollectionElement
          ? element.evalMultiValue(lexicalScope, inheritedScope)
          : [(element as EvalExpression).eval(lexicalScope, inheritedScope)]).toList()
    );
  }
}
