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
import 'object_pattern_type.dart';
import '../macros/branch.dart' show compileNonNullCondition, macroBranch;
import '../statement/statement.dart';
import 'conversion.dart';

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
  void assignVariable(AssignedVariablePattern pattern, Variable value);
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
    case RestPatternElement(:final pattern):
      if (pattern != null) {
        yield* patternBoundNames(pattern, declared: declared);
      }
    case MapPattern pat:
      yield* pat.elements.whereType<MapPatternEntry>().expand(
        (entry) => patternBoundNames(entry.value, declared: declared),
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

      var elementType = specifiedTypeArg ?? CoreTypes.dynamic.ref(ctx);
      if (specifiedTypeArg == null) {
        for (final element in pat.elements) {
          TypeRef? constraint;
          if (element is RestPatternElement) {
            if (element.pattern != null) {
              final rest = patternTypeBound(
                ctx,
                element.pattern!,
                source: source,
              );
              final iterable = ctx.typeSystem.asInstanceOf(
                rest,
                ctx.types.bySpec(CoreTypes.iterable),
              );
              if (iterable != null &&
                  interfaceArgumentsOf(iterable).isNotEmpty) {
                constraint = interfaceArgumentsOf(iterable).first;
              }
            }
          } else {
            constraint = patternTypeBound(ctx, element, source: source);
          }
          if (constraint == null) continue;
          elementType = ctx.typeSystem.greatestLowerBound(
            elementType,
            constraint,
          );
        }
      }
      final result = CoreTypes.list.ref(ctx).copyWith(arguments: [elementType]);
      if (bound != null && !result.isAssignableTo(ctx, bound)) {
        throw CompileError(
          'List pattern type $result is not assignable to bound type $bound',
          source,
        );
      }
      return result;
    case RestPatternElement(:final pattern):
      return pattern == null
          ? bound ?? CoreTypes.dynamic.ref(ctx)
          : patternTypeBound(ctx, pattern, source: source, bound: bound);
    case MapPattern pat:
      if (pat.typeArguments != null &&
          pat.typeArguments!.arguments.length != 2) {
        throw CompileError('Map patterns require two type arguments', source);
      }
      final explicit = mapPatternType(ctx, pat);
      var valueType = interfaceArgumentsOf(explicit)[1];
      if (pat.typeArguments == null) {
        for (final entry in pat.elements.whereType<MapPatternEntry>()) {
          valueType = ctx.typeSystem.greatestLowerBound(
            valueType,
            patternTypeBound(ctx, entry.value, source: source),
          );
        }
      }
      return explicit.copyWith(
        arguments: [interfaceArgumentsOf(explicit)[0], valueType],
      );
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
    case LogicalAndPattern pat:
      return ctx.typeSystem.greatestLowerBound(
        patternTypeBound(ctx, pat.leftOperand, source: source),
        patternTypeBound(ctx, pat.rightOperand, source: source),
      );
    case NullAssertPattern pat:
      return patternTypeBound(
        ctx,
        pat.pattern,
        source: source,
      ).withNullable(true);
    case CastPattern():
      return CoreTypes.dynamic.ref(ctx);
    case ObjectPattern pat:
      final type = bound == null
          ? objectPatternContextType(ctx, pat.type)
          : objectPatternType(ctx, pat.type, bound);
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
        requireMatch(
          _typeTestType(ctx, shape, V, patternContext: patternContext),
        );
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
      return _matchListPattern(ctx, pat, V, patternContext, continuation);
    case MapPattern pat:
      return _matchMapPattern(ctx, pat, V, patternContext, continuation);
    case AssignedVariablePattern pat:
      if (continuation != null) {
        continuation.assignVariable(pat, V);
      } else {
        IdentifierReference(null, pat.name.lexeme).setValue(ctx, V, pat);
      }
      return BuiltinValue(boolval: true).push(ctx);
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
      if (pat is DeclaredVariablePattern &&
          pat.type != null &&
          requireMatch != null) {
        requireMatch(_typeTest(ctx, pat.type, V));
        V = V.withType(matchedPatternType(ctx, pat, V.type));
      }
      if (patternContext != PatternBindContext.matching) {
        V = convertForAssignment(
          ctx,
          V,
          bindingType,
          representation: Abi.storageSlot(bindingType).bank,
          source: pat,
        );
      }
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
      final matchedType = objectPatternType(ctx, pat.type, V.type);
      var result = _typeTestType(
        ctx,
        matchedType,
        V,
        patternContext: patternContext,
      );
      requireMatch?.call(result);
      // A tested interface can expose getters absent from the original
      // static class, even when neither type is a subtype of the other.
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

Variable _matchListPattern(
  CompilerContext ctx,
  ListPattern pattern,
  Variable value,
  PatternBindContext patternContext,
  PatternMatchContinuation? continuation,
) {
  final requiredContext =
      patternContext != PatternBindContext.matching &&
          value.type.isSpec(CoreTypes.dynamic)
      ? patternTypeBound(ctx, pattern)
      : value.type;
  final listType = listPatternType(ctx, pattern, requiredContext);
  final typeTest = _typeTestType(
    ctx,
    listType,
    value,
    patternContext: patternContext,
  );
  continuation?.requireMatch(typeTest);
  final matchedType = matchedPatternType(ctx, pattern, value.type);
  value = value.withType(
    matchedType.isAssignableTo(ctx, listType, forceAllowDynamic: false)
        ? matchedType
        : listType,
  );
  final restIndex = pattern.elements.indexWhere((e) => e is RestPatternElement);
  if (restIndex >= 0 &&
      pattern.elements
          .skip(restIndex + 1)
          .any((e) => e is RestPatternElement)) {
    throw CompileError(
      'List patterns may contain only one rest element',
      pattern,
    );
  }
  final fixedCount = pattern.elements.length - (restIndex < 0 ? 0 : 1);
  final tailCount = restIndex < 0 ? 0 : fixedCount - restIndex;
  Variable? length;
  if (restIndex < 0 || fixedCount > 0) {
    length = GetTarget.read(ctx, value, 'length');
    continuation?.requireMatch(
      CallResolver(ctx).invokeOperator(length, restIndex < 0 ? '==' : '>=', [
        BuiltinValue(intval: fixedCount).push(ctx),
      ]).result,
    );
  }
  Variable? result;
  for (var i = 0; i < pattern.elements.length; i++) {
    final element = pattern.elements[i];
    ListPatternElement inner = element;
    Variable input;
    if (element is RestPatternElement) {
      final rest = element.pattern;
      if (rest == null || rest is WildcardPattern && rest.type == null) {
        continue;
      }
      inner = rest;
      input = CallResolver(ctx).invokeOperator(value, 'sublist', [
        BuiltinValue(intval: restIndex).push(ctx),
        if (tailCount > 0)
          CallResolver(ctx).invokeOperator(length!, '-', [
            BuiltinValue(intval: tailCount).push(ctx),
          ]).result,
      ]).result;
    } else {
      if (element is WildcardPattern && element.type == null) continue;
      final index = restIndex >= 0 && i > restIndex
          ? CallResolver(ctx).invokeOperator(length!, '-', [
              BuiltinValue(intval: pattern.elements.length - i).push(ctx),
            ]).result
          : BuiltinValue(intval: i).push(ctx);
      input = nominalDeclOf(value.type) is SourceTypeDecl
          ? CallResolver(ctx).invokeOperator(value, '[]', [index]).result
          : IndexedReference(value, index).getValue(ctx);
    }
    final matched = patternMatchAndBind(
      ctx,
      inner,
      input,
      patternContext: patternContext,
      continuation: continuation,
    );
    result = result == null || continuation != null
        ? matched
        : CallResolver(ctx).invokeOperator(result, '&&', [matched]).result;
  }
  return result ?? BuiltinValue(boolval: true).push(ctx);
}

Variable _matchMapPattern(
  CompilerContext ctx,
  MapPattern pattern,
  Variable subject,
  PatternBindContext patternContext,
  PatternMatchContinuation? continuation,
) {
  if (pattern.elements.isEmpty ||
      pattern.elements.any((entry) => entry is! MapPatternEntry)) {
    throw CompileError('Map patterns require key/value entries', pattern);
  }
  final requiredContext =
      patternContext != PatternBindContext.matching &&
          subject.type.isSpec(CoreTypes.dynamic)
      ? patternTypeBound(ctx, pattern)
      : subject.type;
  final mapType = mapPatternType(ctx, pattern, requiredContext);
  var result = _typeTestType(
    ctx,
    mapType,
    subject,
    patternContext: patternContext,
  );
  continuation?.requireMatch(result);
  final map = subject.withType(mapType);
  final arguments = interfaceArgumentsOf(mapType);
  final valueType = arguments[1];
  final knownNullable =
      valueType.nullable ||
      valueType.isSpec(CoreTypes.dynamic) ||
      valueType.isSpec(CoreTypes.nullType) ||
      valueType.isSpec(CoreTypes.voidType);
  final nonNullable =
      !knownNullable &&
      valueType.isAssignableTo(
        ctx,
        CoreTypes.object.ref(ctx),
        forceAllowDynamic: false,
      );
  // A free type parameter can be nullable at runtime. Share its test across
  // entries; ordinary nullable and nonnullable values need no such test.
  final nullAllowed = knownNullable || nonNullable
      ? null
      : _typeTestType(ctx, valueType, BuiltinValue().push(ctx));
  for (final entry in pattern.elements.cast<MapPatternEntry>()) {
    final key = compileExpression(entry.key, ctx, arguments[0]);
    final value = IndexedReference(map, key).getValue(ctx);
    final present = _mapEntryPresent(
      ctx,
      map,
      key,
      value,
      nonNullable,
      nullAllowed,
    );
    continuation?.requireMatch(present);
    final matched = patternMatchAndBind(
      ctx,
      entry.value,
      value.withType(valueType),
      patternContext: patternContext,
      continuation: continuation,
    );
    result = continuation != null
        ? matched
        : CallResolver(ctx).invokeOperator(present, '&&', [matched]).result;
  }
  return result;
}

Variable _mapEntryPresent(
  CompilerContext ctx,
  Variable map,
  Variable key,
  Variable value,
  bool nonNullable,
  Variable? nullAllowed,
) {
  final nonNull = compileNonNullCondition(ctx, value);
  if (nonNullable) return nonNull;
  final result = ctx.svar('map_key_present');
  StatementInfo contains(CompilerContext ctx, TypeRef? _) {
    CallResolver(ctx)
        .invokeOperator(map, 'containsKey', [key])
        .result
        .toRep(ctx, ValueRep.bool, into: result);
    return StatementInfo();
  }

  macroBranch(
    ctx,
    null,
    condition: (_) => nonNull,
    thenBranch: (ctx, _) {
      BuiltinValue(boolval: true).push(ctx, result);
      return StatementInfo();
    },
    elseBranch: (ctx, _) {
      if (nullAllowed == null) return contains(ctx, null);
      return macroBranch(
        ctx,
        null,
        condition: (_) => nullAllowed,
        thenBranch: contains,
        elseBranch: (ctx, _) {
          BuiltinValue(boolval: false).push(ctx, result);
          return StatementInfo();
        },
      );
    },
  );
  return Variable.of(ctx, result, CoreTypes.bool.ref(ctx), rep: ValueRep.bool);
}

String? _shorthandPatternName(DartPattern pattern) => switch (pattern) {
  VariablePattern(:final name) => name.lexeme,
  NullCheckPattern(:final pattern) ||
  NullAssertPattern(:final pattern) ||
  ParenthesizedPattern(:final pattern) => _shorthandPatternName(pattern),
  _ => null,
};

Variable _typeTest(
  CompilerContext ctx,
  TypeAnnotation? patType,
  Variable V, {
  PatternBindContext patternContext = PatternBindContext.matching,
}) {
  if (patType == null) return BuiltinValue(boolval: true).push(ctx);
  final slot = TypeRef.fromAnnotation(ctx, ctx.library, patType);
  V.inferType(ctx, slot);
  return _typeTestType(ctx, slot, V, patternContext: patternContext);
}

Variable _typeTestType(
  CompilerContext ctx,
  TypeRef slot,
  Variable V, {
  PatternBindContext patternContext = PatternBindContext.matching,
}) {
  if (V.type.isAssignableTo(ctx, slot, forceAllowDynamic: false)) {
    return BuiltinValue(boolval: true).push(ctx);
  }

  // IsType takes an object operand; box into a fresh slot so V's own SSA
  // keeps its (possibly unboxed) representation for other uses.
  final operand = V.boxed ? V : V.boxIntoFreshSlot(ctx);
  if (patternContext != PatternBindContext.matching) {
    ctx.pushOp(AssertType(operand.ssa, ctx.runtimeTypes.idOf(slot)));
    return BuiltinValue(boolval: true).push(ctx);
  }
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
