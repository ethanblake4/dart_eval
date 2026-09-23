import 'package:dart_eval/src/eval/ir/memory.dart';
import 'package:dart_eval/src/eval/ir/types.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/binary.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/invoke.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import '../values/abi.dart';

enum PatternBindContext { none, declare, declareFinal, matching }

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
          .copyWith(specifiedTypeArgs: [?specifiedTypeArg]);
      if (bound != null && !result.isAssignableTo(ctx, bound)) {
        throw CompileError(
          'List pattern type $result is not assignable to bound type $bound',
          source,
        );
      }
      return result;
    case RecordPattern pat:
      final recordFields = <RecordParameterType>[];
      var positionalFields = 1;
      for (final field in pat.fields) {
        recordFields.add(
          RecordParameterType(
            field.name?.name?.lexeme ?? '\$${positionalFields++}',
            patternTypeBound(ctx, field.pattern, source: source),
            field.name != null,
          ),
        );
      }

      final result = CoreTypes.record
          .ref(ctx)
          .copyWith(recordFields: recordFields);

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
}) {
  switch (pattern) {
    case ConstantPattern pat:
      // The pattern's context type is the matched value's type — this is
      // what lets `case .blue:` resolve the shorthand.
      final constant = compileExpression(pat.expression, ctx, V.type);
      return V.invoke(ctx, '==', [constant]).result;
    case RecordPattern pat:
      var positionalFields = 1;
      Variable? result;
      for (final field in pat.fields) {
        final fieldName = field.effectiveName ?? '\$${positionalFields++}';
        final fieldResult = patternMatchAndBind(
          ctx,
          field.pattern,
          V.getProperty(ctx, fieldName),
          patternContext: patternContext,
        );
        if (result == null) {
          result = fieldResult;
        } else {
          result = result.invoke(ctx, '&&', [fieldResult]).result;
        }
      }
      return result ??
          (throw CompileError(
            'Record pattern matching failed, no fields matched',
            pattern,
          ));
    case ListPattern pat:
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
        );
        if (result == null) {
          result = elementResult;
        } else {
          result = result.invoke(ctx, '&&', [elementResult]).result;
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
      if (V.name != null) {
        if (Abi.unboxedAcrossCalls(V.type).isBoxed) {
          V = V.boxIfNeeded(ctx);
        }
        final v = Variable.ssa(
          ctx,
          Assign(ctx.svar(variableName), V.ssa),
          V.type,
          rep: V.rep,
          isFinal: isFinal,
        );
        if (bindsVariable) ctx.setLocal(variableName, v);
      } else {
        if (bindsVariable) {
          ctx.setLocal(variableName, V.copyWith(isFinal: isFinal));
        }
      }

      if (pat is DeclaredVariablePattern) {
        return _typeTest(ctx, pat.type, V);
      }

      return BuiltinValue(boolval: true).push(ctx);
    case LogicalOrPattern pat:
      final left = patternMatchAndBind(
        ctx,
        pat.leftOperand,
        V,
        patternContext: patternContext,
      );
      final right = patternMatchAndBind(
        ctx,
        pat.rightOperand,
        V,
        patternContext: patternContext,
      );
      return left.invoke(ctx, '||', [right]).result;
    case LogicalAndPattern pat:
      final left = patternMatchAndBind(
        ctx,
        pat.leftOperand,
        V,
        patternContext: patternContext,
      );
      final right = patternMatchAndBind(
        ctx,
        pat.rightOperand,
        V,
        patternContext: patternContext,
      );
      return left.invoke(ctx, '&&', [right]).result;
    case ObjectPattern pat:
      var result = _typeTest(ctx, pat.type, V);
      for (final field in pat.fields) {
        // `(:var x)` shorthand: the getter name is the pattern's own name.
        final propName =
            field.name?.name?.lexeme ??
            (field.pattern is VariablePattern
                ? (field.pattern as VariablePattern).name.lexeme
                : null);
        if (propName == null) {
          throw CompileError('Object pattern field requires a name', field);
        }
        final fieldValue = V.getProperty(ctx, propName);
        final fieldResult = patternMatchAndBind(
          ctx,
          field.pattern,
          fieldValue,
          patternContext: patternContext,
        );
        result = result.invoke(ctx, '&&', [fieldResult]).result;
      }
      return result;
    case CastPattern pat:
      final slot = TypeRef.fromAnnotation(ctx, ctx.library, pat.type);
      // AssertType needs an object operand; box into a fresh slot.
      final boxed = V.boxed ? V : V.boxIntoFreshSlot(ctx);
      ctx.pushOp(AssertType(boxed.ssa, slot.runtimeTypeId(ctx)));
      return patternMatchAndBind(
        ctx,
        pat.pattern,
        boxed.copyWith(type: slot),
        patternContext: patternContext,
      );
    case RelationalPattern pat:
      final operand = compileExpression(pat.operand, ctx, V.type);
      final operator =
          binaryOpMap[pat.operator.type] ??
          (throw CompileError(
            'Unknown relational operator ${pat.operator.type}',
          ));
      return V.invoke(ctx, operator, [operand]).result;
    case WildcardPattern pat:
      return _typeTest(ctx, pat.type, V);
    case ParenthesizedPattern pat:
      return patternMatchAndBind(
        ctx,
        pat.pattern,
        V,
        patternContext: patternContext,
      );
    default:
      throw CompileError('Unsupported pattern type: ${pattern.runtimeType}');
  }
}

Variable _typeTest(CompilerContext ctx, TypeAnnotation? patType, Variable V) {
  final slot = patType != null
      ? TypeRef.fromAnnotation(ctx, ctx.library, patType)
      : CoreTypes.dynamic.ref(ctx);

  V.inferType(ctx, slot);
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
      slot.runtimeTypeId(ctx),
      false,
    ),
    CoreTypes.bool.ref(ctx),
    rep: ValueRep.bool,
  );
}
