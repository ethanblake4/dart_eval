import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart' show CoreTypes, AsyncTypes;
import '../context.dart';
import '../errors.dart';
import '../type.dart';
import 'promotion.dart';
import 'object_pattern_type.dart';
import 'global.dart';

/// The matched value's type on a successful edge. Widening tests retain
/// earlier proofs; record fields carry their own recursively refined types.
TypeRef matchedPatternType(
  CompilerContext ctx,
  ListPatternElement pattern,
  TypeRef bound,
) {
  TypeRef narrow(TypeRef required) {
    if (bound.isAssignableTo(ctx, required, forceAllowDynamic: false)) {
      return bound;
    }
    return isPromotionSubtype(ctx, required, bound)
        ? promotionView(bound, required)
        : bound;
  }

  switch (pattern) {
    case WildcardPattern(:final type):
      return type == null
          ? bound
          : narrow(TypeRef.fromAnnotation(ctx, ctx.library, type));
    case DeclaredVariablePattern(:final type):
      return type == null
          ? bound
          : narrow(TypeRef.fromAnnotation(ctx, ctx.library, type));
    case ObjectPattern(:final type):
      return narrow(objectPatternType(ctx, type, bound));
    case CastPattern(:final type):
      return narrow(TypeRef.fromAnnotation(ctx, ctx.library, type));
    case ParenthesizedPattern(:final pattern):
      return matchedPatternType(ctx, pattern, bound);
    case NullCheckPattern(:final pattern) || NullAssertPattern(:final pattern):
      return matchedPatternType(ctx, pattern, bound.withNullable(false));
    case LogicalAndPattern(:final leftOperand, :final rightOperand):
      return matchedPatternType(
        ctx,
        rightOperand,
        matchedPatternType(ctx, leftOperand, bound),
      );
    case LogicalOrPattern():
      return _patternPromotions(ctx, pattern, bound).last;
    case RelationalPattern(:final operator, :final operand)
        when operator.lexeme == '!=' && _isNullExpression(ctx, operand):
      return bound.withNullable(false);
    case RecordPattern():
      final shape = recordPatternShape(ctx, pattern);
      final record =
          bound is RecordTypeRef &&
              bound.positional.length == shape.positional.length &&
              bound.named.keys.toSet().containsAll(shape.named.keys) &&
              bound.named.length == shape.named.length
          ? bound
          : shape;
      var index = 0;
      final positional = <TypeRef>[];
      final named = <String, TypeRef>{};
      for (final field in pattern.fields) {
        if (field.name == null) {
          positional.add(
            matchedPatternType(ctx, field.pattern, record.positional[index++]),
          );
        } else {
          final name = field.effectiveName!;
          named[name] = matchedPatternType(
            ctx,
            field.pattern,
            record.named[name]!,
          );
        }
      }
      return narrow(RecordTypeRef(positional, named));
    case ListPattern():
      return narrow(listPatternType(ctx, pattern, bound));
    case MapPattern():
      return narrow(mapPatternType(ctx, pattern, bound));
    default:
      return bound;
  }
}

/// Excluding a null test or one arm of FutureOr can refine the failed edge.
/// Other nominal exclusions have no representable promotion type.
TypeRef unmatchedPatternType(
  CompilerContext ctx,
  ListPatternElement pattern,
  TypeRef bound,
) {
  if (pattern is ParenthesizedPattern) {
    return unmatchedPatternType(ctx, pattern.pattern, bound);
  }
  final TypeRef? tested = switch (pattern) {
    DeclaredVariablePattern(:final type?) || WildcardPattern(:final type?) =>
      TypeRef.fromAnnotation(ctx, ctx.library, type),
    ObjectPattern(:final type, fields: []) => objectPatternType(ctx, type, bound),
    ConstantPattern(:final expression) =>
      _isNullExpression(ctx, expression) ? CoreTypes.nullType.ref(ctx) : null,
    RelationalPattern(:final operator, :final operand)
        when operator.lexeme == '==' =>
      _isNullExpression(ctx, operand) ? CoreTypes.nullType.ref(ctx) : null,
    _ => null,
  };
  if (tested == null) return bound;
  if (tested.isSpec(CoreTypes.nullType) && !bound.isSpec(CoreTypes.nullType)) {
    return bound.withNullable(false);
  }
  if (bound is InterfaceTypeRef && bound.decl.isSpec(AsyncTypes.futureOr)) {
    final arguments = interfaceArgumentsOf(bound);
    if (arguments.isEmpty) return bound;
    final value = arguments.first;
    final future = ctx.types.bySpec(CoreTypes.future).instantiate([value]);
    final coversValue = value.isAssignableTo(
      ctx,
      tested,
      forceAllowDynamic: false,
    );
    final coversFuture = future.isAssignableTo(
      ctx,
      tested,
      forceAllowDynamic: false,
    );
    if (coversValue && !coversFuture) {
      return future.withNullable(
        bound.nullable && !tested.hasNullableRepresentation,
      );
    }
    if (coversFuture && !coversValue) {
      return value.withNullable(bound.nullable || value.nullable);
    }
  }
  return bound;
}

bool _isNullExpression(CompilerContext ctx, Expression expression) =>
    expression is NullLiteral ||
    inferStaticExpressionType(
      ctx,
      ctx.library,
      expression,
    ).isSpec(CoreTypes.nullType);

/// These casts cannot produce a value under sound pattern flow analysis.
bool patternAlwaysThrows(
  CompilerContext ctx,
  ListPatternElement pattern,
  TypeRef bound,
) {
  if (!ctx.soundFlowAnalysis(pattern)) return false;
  return switch (pattern) {
    ParenthesizedPattern(:final pattern) => patternAlwaysThrows(
      ctx,
      pattern,
      bound,
    ),
    CastPattern(:final type, :final pattern) => () {
      final target = TypeRef.fromAnnotation(ctx, ctx.library, type);
      return target.isSpec(CoreTypes.nullType) &&
              !bound.hasNullableRepresentation ||
          bound.isSpec(CoreTypes.nullType) &&
              !target.hasNullableRepresentation ||
          patternAlwaysThrows(ctx, pattern, target);
    }(),
    NullAssertPattern() => bound.isSpec(CoreTypes.nullType),
    LogicalAndPattern(:final leftOperand) => patternAlwaysThrows(
      ctx,
      leftOperand,
      bound,
    ),
    _ => false,
  };
}

/// The required map type uses explicit arguments or the subject's Map view.
InterfaceTypeRef mapPatternType(
  CompilerContext ctx,
  MapPattern pattern, [
  TypeRef? subject,
]) {
  final annotations = pattern.typeArguments?.arguments;
  if (annotations != null && annotations.length != 2) {
    throw CompileError('Map patterns require two type arguments', pattern);
  }
  final inferred = subject == null
      ? null
      : ctx.typeSystem.asInstanceOf(subject, ctx.types.bySpec(CoreTypes.map));
  final arguments = annotations == null
      ? interfaceArgumentsOf(inferred ?? CoreTypes.map.ref(ctx))
      : [
          for (final annotation in annotations)
            TypeRef.fromAnnotation(ctx, ctx.library, annotation),
        ];
  return CoreTypes.map
      .ref(ctx)
      .copyWith(
        arguments: arguments.isEmpty
            ? [CoreTypes.dynamic.ref(ctx), CoreTypes.dynamic.ref(ctx)]
            : arguments,
      );
}

/// The type tested by a list pattern, independent of the subject's promotion.
TypeRef listPatternType(
  CompilerContext ctx,
  ListPattern pattern, [
  TypeRef? bound,
]) {
  final arguments = pattern.typeArguments?.arguments;
  final list = bound == null
      ? null
      : ctx.typeSystem.asInstanceOf(bound, ctx.types.bySpec(CoreTypes.list));
  return CoreTypes.list
      .ref(ctx)
      .copyWith(
        arguments: [
          arguments == null
              ? list != null && interfaceArgumentsOf(list).isNotEmpty
                    ? interfaceArgumentsOf(list).first
                    : CoreTypes.dynamic.ref(ctx)
              : TypeRef.fromAnnotation(ctx, ctx.library, arguments.single),
        ],
      );
}

/// A join retains proofs reached by both alternatives, including intermediate
/// promotions in an `&&` chain. It cannot invent a proof from their LUB.
List<TypeRef> _patternPromotions(
  CompilerContext ctx,
  ListPatternElement pattern,
  TypeRef bound,
) {
  switch (pattern) {
    case ParenthesizedPattern(:final pattern):
      return _patternPromotions(ctx, pattern, bound);
    case NullCheckPattern(:final pattern) || NullAssertPattern(:final pattern):
      return [
        bound,
        ..._patternPromotions(ctx, pattern, bound.withNullable(false)),
      ];
    case LogicalAndPattern(:final leftOperand, :final rightOperand):
      final left = _patternPromotions(ctx, leftOperand, bound);
      return [...left, ..._patternPromotions(ctx, rightOperand, left.last)];
    case LogicalOrPattern(:final leftOperand, :final rightOperand):
      final left = _patternPromotions(ctx, leftOperand, bound);
      final right = _patternPromotions(ctx, rightOperand, bound);
      return [
        bound,
        for (final type in left)
          if (type != bound && right.contains(type)) type,
      ];
    default:
      return [bound, matchedPatternType(ctx, pattern, bound)];
  }
}

/// Tests a record's shape before reading fields; nested patterns perform
/// their own field tests in source order.
RecordTypeRef recordPatternShape(CompilerContext ctx, RecordPattern pattern) =>
    RecordTypeRef(
      [
        for (final field in pattern.fields)
          if (field.name == null) CoreTypes.object.ref(ctx).withNullable(true),
      ],
      {
        for (final field in pattern.fields)
          if (field.name != null)
            field.effectiveName!: CoreTypes.object.ref(ctx).withNullable(true),
      },
    );
