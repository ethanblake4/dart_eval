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
    return EvalList(_expandList(lexicalScope, inheritedScope, elements));
  }

  static List<EvalValue> _expandList(EvalScope lexicalScope, EvalScope inheritedScope,
      List<EvalCollectionElement> elements) {
    return [
      for (final e in elements)
        if(e is EvalMultiValuedCollectionElement)
          ..._expandList(lexicalScope, inheritedScope, e.evalMultiValue(lexicalScope, inheritedScope))
        else
          (e as EvalExpression).eval(lexicalScope, inheritedScope)
    ];
  }
}

class EvalMapLiteralEntry extends EvalCollectionElement {

  EvalMapLiteralEntry(this.length, this.offset, this.key, this.value);

  @override
  final int length;
  @override
  final int offset;

  final EvalExpression key;
  final EvalExpression value;
}

class EvalMapLiteral extends EvalExpression {
  EvalMapLiteral(int offset, int length, this.elements): super(offset, length);

  final List<EvalCollectionElement> elements;

  @override
  EvalValue eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    return EvalMap(_expandMap(lexicalScope, inheritedScope, elements));
  }

  static Map<EvalValue, EvalValue> _expandMap(EvalScope lexicalScope, EvalScope inheritedScope,
      List<EvalCollectionElement> elements) {
    return {
      for (final e in elements)
        if(e is EvalMultiValuedCollectionElement)
          ..._expandMap(lexicalScope, inheritedScope, e.evalMultiValue(lexicalScope, inheritedScope))
        else
          (e as EvalMapLiteralEntry).key.eval(lexicalScope, inheritedScope): e.value.eval(lexicalScope, inheritedScope)
    };
  }
}