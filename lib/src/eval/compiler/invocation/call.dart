import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

/// One syntactic call site — everything the resolver may use to pick a
/// [CallTarget]. Arguments are not compiled until the binder runs, because
/// each argument's context type is its parameter's type under the current
/// inference state.
final class CallSite {
  const CallSite({
    this.receiver,
    this.name,
    required this.shape,
    this.context,
    this.source,
    this.inConstContext = false,
  });

  /// The receiver of `r.m(...)`, or null for a bare `m(...)` call.
  final Receiver? receiver;

  /// The called name, or null for a function-expression call `f(...)`.
  final String? name;

  final CallShape shape;

  /// The expression's context type (`bound` today) — feeds downward
  /// inference and `.call` coercion.
  final TypeRef? context;

  final AstNode? source;

  /// Whether the call must fold to a compile-time constant.
  final bool inConstContext;
}

/// The argument list as written, before any parameter matching: positional
/// and named arguments in source order plus the explicit type arguments.
final class CallShape {
  const CallShape._(
    this.positional,
    this.named,
    this.sourceOrder,
    this.typeArguments,
  );

  factory CallShape.fromArgumentList(
    ArgumentList arguments, [
    List<TypeAnnotation>? typeArguments,
  ]) {
    final positional = <ArgSource>[];
    final named = <(String, ArgSource)>[];
    final sourceOrder = <int>[];
    var posIndex = 0, namedIndex = 0;
    for (final arg in arguments.arguments) {
      if (arg is NamedArgument) {
        named.add((arg.name.lexeme, ExpressionArg(arg.argumentExpression)));
        sourceOrder.add(-1 - namedIndex++);
      } else {
        positional.add(ExpressionArg(arg as Expression));
        sourceOrder.add(posIndex++);
      }
    }
    return CallShape._(
      positional,
      named,
      sourceOrder,
      typeArguments,
    );
  }

  /// A shape from already-compiled operands — operators, `x.call(...)`-style
  /// invocations, and bound-member applications.
  factory CallShape.values(
    List<Variable> positional, [
    Map<String, Variable>? named,
    List<TypeAnnotation>? typeArguments,
  ]) {
    return CallShape._(
      [for (final v in positional) ValueArg(v)],
      [
        for (final entry in (named ?? const <String, Variable>{}).entries)
          (entry.key, ValueArg(entry.value)),
      ],
      List.generate(positional.length, (i) => i),
      typeArguments,
    );
  }

  final List<ArgSource> positional;
  final List<(String, ArgSource)> named;

  /// Interleaving of positional (index >= 0) and named (-1 - index)
  /// arguments as written.
  final List<int> sourceOrder;
  final List<TypeAnnotation>? typeArguments;

  int get positionalArity => positional.length;
}

/// An argument's source — an unevaluated expression, an already-compiled
/// value, or a super-parameter forwarded by name.
sealed class ArgSource {
  const ArgSource();
}

final class ExpressionArg extends ArgSource {
  const ExpressionArg(this.expression);

  final Expression expression;
}

final class ValueArg extends ArgSource {
  const ValueArg(this.value);

  final Variable value;
}

final class ForwardedLocal extends ArgSource {
  const ForwardedLocal(this.localName);

  /// Name of the `super.x` parameter's backing local.
  final String localName;
}
