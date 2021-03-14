import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/src/eval/class.dart';
import 'package:dart_eval/src/eval/functions.dart';
import 'package:dart_eval/src/eval/primitives.dart';
import 'package:dart_eval/src/eval/scope.dart';
import 'package:dart_eval/src/eval/type.dart';
import 'package:dart_eval/src/eval/value.dart';
import 'package:dart_eval/src/parse/source.dart';

abstract class EvalRunnable {
  EvalValue eval(EvalScope lexicalScope, EvalScope inheritedScope);
}

abstract class EvalExpression extends DartSourceNode implements EvalRunnable {
  const EvalExpression(int offset, int length) : super(offset, length);
}

/*class EvalDeclarationExpression extends EvalExpression {

  EvalDeclarationExpression(int offset, int length, this.) : super(offset, length);

  @override
  EvalValue eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    // TODO: implement eval
    throw UnimplementedError();
  }

}*/

class EvalNullExpression extends EvalExpression {
  EvalNullExpression(int offset, int length) : super(offset, length);

  @override
  EvalValue eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    return EvalNull();
  }

  @override
  EvalType get returnType => EvalType.nullType;
}

class EvalCallExpression extends EvalExpression {
  EvalCallExpression(int offset, int length, this.child, this.methodName, this.params) : super(offset, length);

  final EvalExpression? child;
  final String methodName;
  final List<EvalExpression> params;

  @override
  EvalValue eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    final c = child?.eval(lexicalScope, inheritedScope);
    final m = c?.getField(methodName);
    final f = m ?? lexicalScope.lookup(methodName)?.value ?? inheritedScope.lookup(methodName)?.value;
    if (f is EvalCallable) {
      return (f as EvalCallable).call(
          lexicalScope,
          inheritedScope,
          [],
          params
              .map((e) => e is EvalNamedExpression
                  ? NamedParameter(e.name, e.eval(lexicalScope, inheritedScope))
                  : Parameter(e.eval(lexicalScope, inheritedScope)))
              .toList(),
          target: c);
    }
    if (f == null) {
      throw ArgumentError('Method does not exist: $methodName');
    }
    throw ArgumentError('Cannot call a non-function/callable class');
  }
}

class EvalFunctionExpression extends EvalExpression {
  EvalFunctionExpression(int offset, int length, this.body, this.params) : super(offset, length);

  DartMethodBody body;
  List<ParameterDefinition> params;

  @override
  EvalFunctionImpl eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    return EvalFunctionImpl(body, params);
  }
}

class EvalIdentifierExpression extends EvalExpression {
  EvalIdentifierExpression(int offset, int length, this.name) : super(offset, length);
  final String name;

  @override
  EvalValue eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    return (lexicalScope.lookup(name) ?? inheritedScope.lookup(name))?.value ??
        (throw ArgumentError("Unknown identifier '$name'"));
  }
}

class EvalPrefixedIdentifierExpression extends EvalIdentifierExpression {
  EvalPrefixedIdentifierExpression(int offset, int length, this.prefix, String name) : super(offset, length, name);

  final String prefix;

  @override
  EvalValue eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    final pfx = (lexicalScope.lookup(prefix) ?? inheritedScope.lookup(prefix))?.value ?? (throw ArgumentError());
    return pfx.getField(name);
  }
}

class EvalPropertyAccessExpression extends EvalExpression {
  EvalPropertyAccessExpression(int offset, int length, this.target, this.name) : super(offset, length);

  final EvalExpression target;
  final String name;

  @override
  EvalValue eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    return target.eval(lexicalScope, inheritedScope).getField(name);
  }
}

class EvalIsExpression extends EvalExpression {
  EvalIsExpression(int offset, int length, this.lhs, this.rhs) : super(offset, length);

  final EvalExpression lhs;
  final EvalExpression rhs;

  @override
  EvalValue eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    final evLHS = lhs.eval(lexicalScope, inheritedScope);
    final evRHS = rhs.eval(lexicalScope, inheritedScope);

    if (evRHS.evalType != EvalType.typeType || !(evRHS is EvalAbstractClass)) {
      throw ArgumentError();
    }

    return EvalBool(evLHS.evalType == evRHS.delegatedType);
  }
}

class EvalInstanceCreationExpresion extends EvalExpression {
  EvalInstanceCreationExpresion(int offset, int length, this.identifier, this.constructorName) : super(offset, length);

  final EvalIdentifierExpression identifier;
  final String constructorName;

  @override
  EvalValue eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    final on = identifier.eval(lexicalScope, inheritedScope);
    if (!(on is EvalClass)) {
      throw ArgumentError('Attempting to construct something that\'s not a class');
    }
    final EvalCallable constructor;
    if (constructorName.isEmpty) {
      constructor = on;
    } else {
      constructor = on.getField(constructorName) as EvalCallable;
    }
    return constructor.call(lexicalScope, inheritedScope, [], []);
  }
}

class EvalNamedExpression extends EvalExpression {
  EvalNamedExpression(int offset, int length, this.name, this.expression) : super(offset, length);

  final EvalExpression expression;
  final String name;

  @override
  EvalValue eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    return expression.eval(lexicalScope, inheritedScope);
  }
}

class EvalBinaryExpression extends EvalExpression {
  EvalBinaryExpression(int offset, int length, this.leftOperand, this.operator, this.rightOperand)
      : super(offset, length);

  final EvalExpression leftOperand;
  final EvalExpression rightOperand;
  final TokenType operator;

  @override
  EvalValue eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    final method = operator.lexeme;

    final l = leftOperand.eval(lexicalScope, inheritedScope);
    final m = l.getField(method);
    if (!(m is EvalFunction)) {
      throw ArgumentError('No operator method $operator');
    }
    return m.call(lexicalScope, inheritedScope, [], [Parameter(rightOperand.eval(lexicalScope, inheritedScope))], target: l);
  }
}
