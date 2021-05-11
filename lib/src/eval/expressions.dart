import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/class.dart';
import 'package:dart_eval/src/eval/collections.dart';
import 'package:dart_eval/src/eval/functions.dart';
import 'package:dart_eval/src/eval/primitives.dart';
import 'package:dart_eval/src/eval/reference.dart';
import 'package:dart_eval/src/eval/scope.dart';
import 'package:dart_eval/src/eval/type.dart';
import 'package:dart_eval/src/eval/value.dart';
import 'package:dart_eval/src/parse/source.dart';

/// A class that can be evaluated in Eval
abstract class EvalRunnable {
  /// Evaluate this function in the supplied scope
  EvalValue eval(EvalScope lexicalScope, EvalScope inheritedScope);
}

/// A Dart expression
abstract class EvalExpression extends DartSourceNode
    implements EvalRunnable, EvalCollectionElement {
  const EvalExpression(int offset, int length) : super(offset, length);
}

/// A Dart expression that can return a reference to a value instead of the value itself
abstract class EvalReferenceExpression implements EvalExpression {
  Reference evalReference(EvalScope lexicalScope, EvalScope inheritedScope);
}

/*class EvalDeclarationExpression extends EvalExpression {

  EvalDeclarationExpression(int offset, int length, this.) : super(offset, length);

  @override
  EvalValue eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    // TODO: implement eval
    throw UnimplementedError();
  }

}*/

/// An expression representing the null literal
///
/// See [NullLiteral]
class EvalNullExpression extends EvalExpression {
  EvalNullExpression(int offset, int length) : super(offset, length);

  @override
  EvalValue eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    return EvalNull();
  }
}

/// An expression that calls a method on a value
///
/// See [MethodInvocation]
class EvalCallExpression extends EvalExpression {
  /// Create an [EvalCallExpression]
  EvalCallExpression(
      int offset, int length, this.child, this.methodName, this.params)
      : super(offset, length);

  /// The expression to call [methodName] on
  final EvalExpression? child;

  /// The method to call on [child], or the function to lookup if no [child] is provided
  final String methodName;

  /// Parameters to the method
  final List<EvalExpression> params;

  @override
  EvalValue eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    final c = child?.eval(lexicalScope, inheritedScope);
    final m = c?.evalGetField(methodName);
    final f = m ??
        lexicalScope.lookup(methodName)?.value ??
        inheritedScope.lookup(methodName)?.value;
    if (f == null) {
      throw ArgumentError('Method does not exist: $methodName');
    }
    if (f is EvalCallable) {
      return f.call(
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
    throw ArgumentError('Cannot call a non-function/callable class');
  }
}

/// Defines a expression function
///
/// See [FunctionExpression]
class EvalFunctionExpression extends EvalExpression {
  EvalFunctionExpression(int offset, int length, this.body, this.params)
      : super(offset, length);

  DartMethodBody body;
  List<ParameterDefinition> params;

  @override
  EvalFunctionImpl eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    return EvalFunctionImpl(body, params);
  }
}

/// An identifier, such as a variable name
///
/// See [Identifier]
class EvalIdentifierExpression extends EvalExpression
    implements EvalReferenceExpression {
  EvalIdentifierExpression(int offset, int length, this.name)
      : super(offset, length);
  final String name;

  /// Lookup this identifier in the scope and return a [Reference]
  @override
  Reference evalReference(EvalScope lexicalScope, EvalScope inheritedScope) {
    return (lexicalScope.lookup(name) ?? inheritedScope.lookup(name)) ??
        (throw ArgumentError("Unknown identifier '$name'"));
  }

  /// Lookup this identifier in the scope and return its value
  @override
  EvalValue eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    return (lexicalScope.lookup(name) ?? inheritedScope.lookup(name))?.value ??
        (throw ArgumentError("Unknown identifier '$name'"));
  }
}

/// An identifier with a prefix
///
/// See [PrefixedIdentifier]
class EvalPrefixedIdentifierExpression extends EvalIdentifierExpression {
  EvalPrefixedIdentifierExpression(
      int offset, int length, this.prefix, String name)
      : super(offset, length, name);

  final String prefix;

  /// Lookup this identifier in the scope and return a [Reference]
  @override
  Reference evalReference(EvalScope lexicalScope, EvalScope inheritedScope) {
    final pfx =
        (lexicalScope.lookup(prefix) ?? inheritedScope.lookup(prefix))?.value ??
            (throw ArgumentError());
    return FieldReference(pfx, name);
  }

  /// Lookup this identifier in the scope and return its value
  @override
  EvalValue eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    final pfx =
        (lexicalScope.lookup(prefix) ?? inheritedScope.lookup(prefix))?.value ??
            (throw ArgumentError());
    return pfx.evalGetField(name);
  }
}

/// An expression that assigns a value to a reference
///
/// See [AssignmentExpression]
class EvalAssignmentExpression extends EvalExpression {
  EvalAssignmentExpression(
      int offset, int length, this.lhs, this.rhs, this.operator)
      : super(offset, length);

  final EvalReferenceExpression lhs;
  final EvalExpression rhs;

  /// The operator to use for assignment. Usually '='
  final TokenType operator;

  @override
  EvalValue eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    final ref = lhs.evalReference(lexicalScope, inheritedScope);
    final val = rhs.eval(lexicalScope, inheritedScope);

    if (operator == TokenType.EQ) {
      return ref.value = val;
    }

    throw ArgumentError('Assignment expression: unknown operator $operator');
  }
}

/// Access a property/field of a value
///
/// See [PropertyAccess]
class EvalPropertyAccessExpression extends EvalExpression {
  EvalPropertyAccessExpression(int offset, int length, this.target, this.name)
      : super(offset, length);

  final EvalExpression target;
  final String name;

  @override
  EvalValue eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    return target.eval(lexicalScope, inheritedScope).evalGetField(name);
  }
}

class EvalIndexExpression extends EvalExpression {
  EvalIndexExpression(int offset, int length, this.target, this.expression)
      : super(offset, length);

  final EvalExpression target;
  final EvalExpression expression;

  @override
  EvalValue eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    final _target = target.eval(lexicalScope, inheritedScope);
    return _target.evalGetField('[]').call(lexicalScope, inheritedScope, [],
        [Parameter(expression.eval(lexicalScope, inheritedScope))],
        target: _target);
  }
}

class EvalIsExpression extends EvalExpression {
  EvalIsExpression(int offset, int length, this.lhs, this.rhs)
      : super(offset, length);

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
  EvalInstanceCreationExpresion(
      int offset, int length, this.identifier, this.constructorName)
      : super(offset, length);

  final EvalIdentifierExpression identifier;
  final String constructorName;

  @override
  EvalValue eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    final on = identifier.eval(lexicalScope, inheritedScope);
    if (!(on is EvalClass)) {
      throw ArgumentError(
          'Attempting to construct something that\'s not a class');
    }
    final EvalCallable constructor;
    if (constructorName.isEmpty) {
      constructor = on;
    } else {
      constructor = on.evalGetField(constructorName);
    }
    return constructor.call(lexicalScope, inheritedScope, [], []);
  }
}

class EvalNamedExpression extends EvalExpression {
  EvalNamedExpression(int offset, int length, this.name, this.expression)
      : super(offset, length);

  final EvalExpression expression;
  final String name;

  @override
  EvalValue eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    return expression.eval(lexicalScope, inheritedScope);
  }
}

class EvalBinaryExpression extends EvalExpression {
  EvalBinaryExpression(int offset, int length, this.leftOperand, this.operator,
      this.rightOperand)
      : super(offset, length);

  final EvalExpression leftOperand;
  final EvalExpression rightOperand;
  final TokenType operator;

  @override
  EvalValue eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    final method = operator.lexeme;

    final l = leftOperand.eval(lexicalScope, inheritedScope);
    final m = l.evalGetField(method);
    if (!(m is EvalFunction)) {
      throw ArgumentError('No operator method $operator');
    }
    return m.call(lexicalScope, inheritedScope, [],
        [Parameter(rightOperand.eval(lexicalScope, inheritedScope))],
        target: l);
  }
}

class EvalPostfixExpression extends EvalExpression {
  final EvalReferenceExpression operand;
  final TokenType operator;

  EvalPostfixExpression(int offset, int length, this.operand, this.operator)
      : super(offset, length);

  @override
  EvalValue eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    final ref = operand.evalReference(lexicalScope, inheritedScope);
    if (operator == TokenType.PLUS_PLUS) {
      final v = ref.value!;
      ref.value = v.evalGetField('+').call(
          lexicalScope, inheritedScope, [], [Parameter(EvalInt(1))],
          target: v);
      return v;
    } else if (operator == TokenType.MINUS_MINUS) {
      final v = ref.value!;
      ref.value = v.evalGetField('-').call(
          lexicalScope, inheritedScope, [], [Parameter(EvalInt(1))],
          target: v);
      return v;
    }
    throw UnimplementedError(
        'No implementation for postfix operator $operator');
  }
}
