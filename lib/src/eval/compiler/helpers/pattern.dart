import 'package:control_flow_graph/control_flow_graph.dart' show Assign;
import 'package:dart_eval/src/eval/ir/types.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/binary.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import '../values/abi.dart';
import '../invocation/accessors.dart';
import '../invocation/resolver.dart';
import 'pattern_type.dart';
import '../macros/branch.dart' show compileNonNullCondition;

enum PatternBindContext { none, declare, declareFinal, matching }

/// The success edge continues matching; failures select the next alternative.
abstract interface class PatternMatchContinuation {
  void requireMatch(Variable condition);
  Variable matchOr(
    LogicalOrPattern pattern,
    Variable subject,
    PatternBindContext patternContext,
  );
  bool get deferCaptures;
}

/// The names a pattern binds — [declared] selects declared variables (fresh
/// bindings, e.g. `var (a, b) = ...`) vs assigned variables (writes to
/// existing locals, e.g. `(a, b) = ...`).
Iterable<String> patternBoundNames(
  AstNode pattern, {
  required bool declared,
}) sync* {
  switch (pattern) {
    case DeclaredVariablePattern pat:
      if (declared && pat.name.lexeme != '_') yield pat.name.lexeme;
    case AssignedVariablePattern pat:
      if (!declared) yield pat.name.lexeme;
    case RecordPattern pat:
      yield* pat.fields.expand(
        (f) => patternBoundNames(f.pattern, declared: declared),
      );
    case ListPattern pat:
      yield* pat.elements.expand(
        (e) => patternBoundNames(e, declared: declared),
      );
    case ParenthesizedPattern pat:
      yield* patternBoundNames(pat.pattern, declared: declared);
    case LogicalOrPattern pat:
      yield* patternBoundNames(pat.leftOperand, declared: declared);
      yield* patternBoundNames(pat.rightOperand, declared: declared);
    case LogicalAndPattern pat:
      yield* patternBoundNames(pat.leftOperand, declared: declared);
      yield* patternBoundNames(pat.rightOperand, declared: declared);
    case ObjectPattern pat:
      yield* pat.fields.expand(
        (f) => patternBoundNames(f.pattern, declared: declared),
      );
    case CastPattern pat:
      yield* patternBoundNames(pat.pattern, declared: declared);
    case NullCheckPattern pat:
      yield* patternBoundNames(pat.pattern, declared: declared);
    case NullAssertPattern pat:
      yield* patternBoundNames(pat.pattern, declared: declared);
    default:
  }
}

TypeRef patternTypeBound(
  CompilerContext ctx,
  ListPatternElement pattern, {
  AstNode? source,
  TypeRef? bound,
}) {
  switch (pattern) {
    case ListPattern pat:
      TypeRef? specifiedTypeArg;
      if (pat.typeArguments != null) {
        if (pat.typeArguments!.arguments.length != 1) {
          throw CompileError(
            'List pattern must have exactly one type argument',
            source,
          );
        }
        specifiedTypeArg = TypeRef.fromAnnotation(
          ctx,
          ctx.library,
          pat.typeArguments!.arguments[0],
        );
      }

      for (final element in pat.elements) {
        final elementType = patternTypeBound(
          ctx,
          element,
          source: source,
          bound: specifiedTypeArg,
        );
        if (specifiedTypeArg != null &&
            !elementType.isAssignableTo(ctx, specifiedTypeArg)) {
          throw CompileError(
            'List pattern element type $elementType is not assignable to $specifiedTypeArg',
            source,
          );
        }
      }

      final result = CoreTypes.list
          .ref(ctx)
          .copyWith(arguments: [?specifiedTypeArg]);
      if (bound != null && !result.isAssignableTo(ctx, bound)) {
        throw CompileError(
          'List pattern type $result is not assignable to bound type $bound',
          source,
        );
      }
      return result;
    case RecordPattern pat:
      final positional = <TypeRef>[];
      final named = <String, TypeRef>{};
      for (var i = 0; i < pat.fields.length; i++) {
        final field = pat.fields[i];
        final type = patternTypeBound(ctx, field.pattern, source: source);
        if (field.name == null) {
          positional.add(type);
        } else {
          named[field.effectiveName ?? '\$${i + 1}'] = type;
        }
      }

      final result = RecordTypeRef(positional, named);

      if (bound != null && !result.isAssignableTo(ctx, bound)) {
        throw CompileError(
          'Record pattern type $result is not assignable to bound type $bound',
          source,
        );
      }
      return result;
    case DeclaredVariablePattern pat:
      return pat.type != null
          ? TypeRef.fromAnnotation(ctx, ctx.library, pat.type!)
          : bound ?? CoreTypes.dynamic.ref(ctx);
    case AssignedVariablePattern pat:
      return IdentifierReference(
        null,
        pat.name.lexeme,
      ).resolveType(ctx, forSet: true, source: source);
    case ParenthesizedPattern pat:
      return patternTypeBound(ctx, pat.pattern, source: source, bound: bound);
    case ObjectPattern pat:
      final type = TypeRef.fromAnnotation(ctx, ctx.library, pat.type);
      if (bound != null && !type.isAssignableTo(ctx, bound)) {
        throw CompileError(
          'Object pattern type $type is not assignable to bound type $bound',
          source,
        );
      }
      return type;
    case WildcardPattern pat:
      final typeAnnotation = pat.type;
      if (typeAnnotation == null) {
        return bound ?? CoreTypes.dynamic.ref(ctx);
      }
      final type = TypeRef.fromAnnotation(ctx, ctx.library, typeAnnotation);
      if (bound != null && !type.isAssignableTo(ctx, bound)) {
        throw CompileError(
          'Wildcard pattern type $type is not assignable to bound type $bound',
          source,
        );
      }
      return type;
    default:
      throw CompileError(
        "Refutable patterns can't be used in an irrefutable context."
        "Try using an if-case, a 'switch' statement, or a 'switch' expression instead.",
        source,
      );
  }
}

Variable patternMatchAndBind(
  CompilerContext ctx,
  ListPatternElement pattern,
  Variable V, {
  PatternBindContext patternContext = PatternBindContext.none,
  PatternMatchContinuation? continuation,
}) {
  final result = _matchPattern(
    ctx,
    pattern,
    V,
    patternContext: patternContext,
    continuation: continuation,
  );
  if (continuation == null) return result;
  continuation.requireMatch(result);
  return BuiltinValue(boolval: true).push(ctx);
}

Variable _matchPattern(
  CompilerContext ctx,
  ListPatternElement pattern,
  Variable V, {
  required PatternBindContext patternContext,
  PatternMatchContinuation? continuation,
}) {
  final requireMatch = continuation?.requireMatch;
  switch (pattern) {
    case ConstantPattern pat:
      // The pattern's context type is the matched value's type — this is
      // what lets `case .blue:` resolve the shorthand.
      final constant = compileExpression(pat.expression, ctx, V.type);
      return CallResolver(ctx).invokeOperator(constant, '==', [V]).result;
    case RecordPattern pat:
      if (requireMatch != null) {
        final shape = recordPatternShape(ctx, pat);
        requireMatch(_typeTestType(ctx, shape, V));
        V = V.withType(
          V.type is RecordTypeRef &&
                  V.type
                      .withNullable(false)
                      .isAssignableTo(ctx, shape, forceAllowDynamic: false)
              ? V.type.withNullable(false)
              : shape,
        );
      }
      var positionalFields = 1;
      Variable? result;
      for (final field in pat.fields) {
        final fieldName = field.effectiveName ?? '\$${positionalFields++}';
        final fieldResult = patternMatchAndBind(
          ctx,
          field.pattern,
          GetTarget.read(ctx, V, fieldName),
          patternContext: patternContext,
          continuation: continuation,
        );
        if (result == null || requireMatch != null) {
          result = fieldResult;
        } else {
          result = CallResolver(
            ctx,
          ).invokeOperator(result, '&&', [fieldResult]).result;
        }
      }
      return result ?? BuiltinValue(boolval: true).push(ctx);
    case ListPattern pat:
      if (requireMatch != null) {
        final listType = listPatternType(ctx, pat);
        requireMatch(_typeTestType(ctx, listType, V));
        final matchedType = matchedPatternType(ctx, pat, V.type);
        V = V.withType(
          matchedType.isAssignableTo(ctx, listType, forceAllowDynamic: false)
              ? matchedType
              : listType,
        );
        if (pat.elements.any((element) => element is RestPatternElement)) {
          throw CompileError('Rest list patterns are not supported', pat);
        }
        final length = GetTarget.read(ctx, V, 'length');
        requireMatch(
          CallResolver(ctx).invokeOperator(length, '==', [
            BuiltinValue(intval: pat.elements.length).push(ctx),
          ]).result,
        );
      }
      if (pat.elements.isEmpty) {
        return BuiltinValue(boolval: true).push(ctx);
      }
      Variable? result;
      for (var i = 0; i < pat.elements.length; i++) {
        final element = pat.elements[i];
        final listEl = IndexedReference(
          V,
          BuiltinValue(intval: i).push(ctx),
        ).getValue(ctx);
        final elementResult = patternMatchAndBind(
          ctx,
          element,
          listEl,
          patternContext: patternContext,
          continuation: continuation,
        );
        if (result == null || requireMatch != null) {
          result = elementResult;
        } else {
          result = CallResolver(
            ctx,
          ).invokeOperator(result, '&&', [elementResult]).result;
        }
      }
      return result ??
          (throw CompileError(
            'List pattern matching failed, no elements matched',
            pattern,
          ));
    case VariablePattern pat:
      final variableName = pat.name.lexeme;
      final declare =
          patternContext == PatternBindContext.declare ||
          patternContext == PatternBindContext.declareFinal ||
          (patternContext == PatternBindContext.matching &&
              pat is DeclaredVariablePattern);
      if (declare &&
          variableName != '_' &&
          ctx.locals.last.containsKey(variableName)) {
        throw CompileError(
          'Cannot declare variable $variableName'
          ' multiple times in the same scope',
        );
      }
      final isFinal =
          patternContext == PatternBindContext.declareFinal ||
          (pat is DeclaredVariablePattern &&
              pat.keyword != null &&
              pat.keyword!.keyword == Keyword.FINAL);
      // A `_` pattern variable is a wildcard: it matches but binds nothing.
      final bindsVariable = variableName != '_';
      if (Abi.unboxedAcrossCalls(V.type).isBoxed) {
        V = V.boxIfNeeded(ctx);
      }
      final bindingType = pat is DeclaredVariablePattern && pat.type != null
          ? TypeRef.fromAnnotation(ctx, ctx.library, pat.type!)
          : V.type;
      final currentType =
          bindingType.nullable &&
              !V.type.nullable &&
              !V.type.isSpec(CoreTypes.dynamic) &&
              !V.type.isSpec(CoreTypes.nullType)
          ? bindingType.withNullable(false)
          : bindingType;
      final v = Variable.ssa(
        ctx,
        Assign(ctx.svar(variableName), V.ssa),
        currentType,
        rep: V.rep,
      );
      if (bindsVariable) {
        final binding = ctx.setLocal(
          variableName,
          v,
          declaredType: bindingType,
          isFinal: isFinal,
        );
        if (continuation?.deferCaptures != true) {
          binding.captureBinding(ctx, pat);
        }
      }

      if (pat is DeclaredVariablePattern) {
        return _typeTest(ctx, pat.type, V);
      }

      return BuiltinValue(boolval: true).push(ctx);
    case LogicalOrPattern pat:
      if (continuation != null) {
        return continuation.matchOr(pat, V, patternContext);
      }
      final alternativeContext = patternContext == PatternBindContext.matching
          ? PatternBindContext.none
          : patternContext;
      final left = patternMatchAndBind(
        ctx,
        pat.leftOperand,
        V,
        patternContext: alternativeContext,
      );
      final right = patternMatchAndBind(
        ctx,
        pat.rightOperand,
        V,
        patternContext: alternativeContext,
      );
      return CallResolver(ctx).invokeOperator(left, '||', [right]).result;
    case LogicalAndPattern pat:
      final left = patternMatchAndBind(
        ctx,
        pat.leftOperand,
        V,
        patternContext: patternContext,
        continuation: continuation,
      );
      final right = patternMatchAndBind(
        ctx,
        pat.rightOperand,
        requireMatch == null
            ? V
            : V.withType(matchedPatternType(ctx, pat.leftOperand, V.type)),
        patternContext: patternContext,
        continuation: continuation,
      );
      if (requireMatch != null) return right;
      return CallResolver(ctx).invokeOperator(left, '&&', [right]).result;
    case ObjectPattern pat:
      var result = _typeTest(ctx, pat.type, V);
      requireMatch?.call(result);
      // A tested interface can expose getters absent from the original
      // static class, even when neither type is a subtype of the other.
      final matchedType = TypeRef.fromAnnotation(ctx, ctx.library, pat.type);
      final matchedValue = V.copyWith(type: matchedType);
      for (final field in pat.fields) {
        // `(:var x)` shorthand: the getter name is the pattern's own name.
        final propName =
            field.name?.name?.lexeme ?? _shorthandPatternName(field.pattern);
        if (propName == null) {
          throw CompileError('Object pattern field requires a name', field);
        }
        final fieldValue = GetTarget.read(ctx, matchedValue, propName);
        final fieldResult = patternMatchAndBind(
          ctx,
          field.pattern,
          fieldValue,
          patternContext: patternContext,
          continuation: continuation,
        );
        result = requireMatch != null
            ? fieldResult
            : CallResolver(
                ctx,
              ).invokeOperator(result, '&&', [fieldResult]).result;
      }
      return result;
    case CastPattern pat:
      final slot = TypeRef.fromAnnotation(ctx, ctx.library, pat.type);
      // AssertType needs an object operand; box into a fresh slot.
      final boxed = V.boxed ? V : V.boxIntoFreshSlot(ctx);
      ctx.pushOp(AssertType(boxed.ssa, ctx.runtimeTypes.idOf(slot)));
      return patternMatchAndBind(
        ctx,
        pat.pattern,
        boxed.copyWith(type: slot),
        patternContext: patternContext,
        continuation: continuation,
      );
    case RelationalPattern pat:
      final operand = compileExpression(pat.operand, ctx, V.type);
      final operator =
          binaryOpMap[pat.operator.type] ??
          (throw CompileError(
            'Unknown relational operator ${pat.operator.type}',
          ));
      return CallResolver(ctx).invokeOperator(V, operator, [operand]).result;
    case WildcardPattern pat:
      return _typeTest(ctx, pat.type, V);
    case ParenthesizedPattern pat:
      return patternMatchAndBind(
        ctx,
        pat.pattern,
        V,
        patternContext: patternContext,
        continuation: continuation,
      );
    case NullCheckPattern pat:
      final nonNull = compileNonNullCondition(ctx, V);
      requireMatch?.call(nonNull);
      final matched = patternMatchAndBind(
        ctx,
        pat.pattern,
        V.copyWith(type: V.type.withNullable(false)),
        patternContext: patternContext,
        continuation: continuation,
      );
      if (requireMatch != null) return matched;
      return CallResolver(ctx).invokeOperator(nonNull, '&&', [matched]).result;
    case NullAssertPattern pat:
      if (V.type.nullable || V.type.isSpec(CoreTypes.dynamic)) {
        final boxed = V.boxed ? V : V.boxIntoFreshSlot(ctx);
        ctx.pushOp(
          AssertType(
            boxed.ssa,
            ctx.runtimeTypes.idOf(CoreTypes.object.ref(ctx)),
          ),
        );
      }
      return patternMatchAndBind(
        ctx,
        pat.pattern,
        V.withType(V.type.withNullable(false)),
        patternContext: patternContext,
        continuation: continuation,
      );
    default:
      throw CompileError('Unsupported pattern type: ${pattern.runtimeType}');
  }
}

String? _shorthandPatternName(DartPattern pattern) => switch (pattern) {
  VariablePattern(:final name) => name.lexeme,
  NullCheckPattern(:final pattern) ||
  NullAssertPattern(:final pattern) ||
  ParenthesizedPattern(:final pattern) => _shorthandPatternName(pattern),
  _ => null,
};

Variable _typeTest(CompilerContext ctx, TypeAnnotation? patType, Variable V) {
  if (patType == null) return BuiltinValue(boolval: true).push(ctx);
  final slot = TypeRef.fromAnnotation(ctx, ctx.library, patType);
  V.inferType(ctx, slot);
  return _typeTestType(ctx, slot, V);
}

Variable _typeTestType(CompilerContext ctx, TypeRef slot, Variable V) {
  if (V.type.isAssignableTo(ctx, slot, forceAllowDynamic: false)) {
    return BuiltinValue(boolval: true).push(ctx);
  }

  // IsType takes an object operand; box into a fresh slot so V's own SSA
  // keeps its (possibly unboxed) representation for other uses.
  final operand = V.boxed ? V : V.boxIntoFreshSlot(ctx);
  return Variable.ssa(
    ctx,
    IsType(
      ctx.svar('pattern_type'),
      operand.ssa,
      ctx.runtimeTypes.idOf(slot),
      false,
    ),
    CoreTypes.bool.ref(ctx),
    rep: ValueRep.bool,
  );
}
