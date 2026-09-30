import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart' show CoreTypes;
import '../context.dart';
import '../type.dart';
import 'promotion.dart';

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
      return narrow(TypeRef.fromAnnotation(ctx, ctx.library, type));
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
    case LogicalOrPattern(:final leftOperand, :final rightOperand):
      return TypeRef.commonBaseType(ctx, {
        matchedPatternType(ctx, leftOperand, bound),
        matchedPatternType(ctx, rightOperand, bound),
      });
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
      final arguments = pattern.typeArguments?.arguments;
      return narrow(
        CoreTypes.list
            .ref(ctx)
            .copyWith(
              arguments: [
                arguments == null
                    ? CoreTypes.dynamic.ref(ctx)
                    : TypeRef.fromAnnotation(
                        ctx,
                        ctx.library,
                        arguments.single,
                      ),
              ],
            ),
      );
    default:
      return bound;
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
