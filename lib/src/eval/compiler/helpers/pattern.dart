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
import 'package:dart_eval/src/eval/runtime/runtime.dart';

enum PatternBindContext { none, declare, declareFinal, matching }

TypeRef patternTypeBound(CompilerContext ctx, ListPatternElement pattern,
    {AstNode? source, TypeRef? bound}) {
  switch (pattern) {
    case ListPattern pat:
      TypeRef? specifiedTypeArg;
      if (pat.typeArguments != null) {
        if (pat.typeArguments!.arguments.length != 1) {
          throw CompileError(
              'List pattern must have exactly one type argument', source);
        }
        specifiedTypeArg = TypeRef.fromAnnotation(
            ctx, ctx.library, pat.typeArguments!.arguments[0]);
      }

      for (final element in pat.elements) {
        final elementType = patternTypeBound(ctx, element,
            source: source, bound: specifiedTypeArg);
        if (specifiedTypeArg != null &&
            !elementType.isAssignableTo(ctx, specifiedTypeArg)) {
          throw CompileError(
              'List pattern element type $elementType is not assignable to $specifiedTypeArg',
              source);
        }
      }

      final result = CoreTypes.list.ref(ctx).copyWith(
          specifiedTypeArgs: [if (specifiedTypeArg != null) specifiedTypeArg]);
      if (bound != null && !result.isAssignableTo(ctx, bound)) {
        throw CompileError(
            'List pattern type $result is not assignable to bound type $bound',
            source);
      }
      return result;
    case RecordPattern pat:
      final recordFields = <RecordParameterType>[];
      var positionalFields = 0;
      for (final field in pat.fields) {
        recordFields.add(
          RecordParameterType(
            field.name?.name?.lexeme ?? '\$${positionalFields++}',
            patternTypeBound(ctx, field.pattern, source: source),
            field.name != null,
          ),
        );
      }

      final result = CoreTypes.record.ref(ctx).copyWith(
            recordFields: recordFields,
          );

      if (bound != null && !result.isAssignableTo(ctx, bound)) {
        throw CompileError(
            'Record pattern type $result is not assignable to bound type $bound',
            source);
      }
      return result;
    case DeclaredVariablePattern pat:
      return pat.type != null
          ? TypeRef.fromAnnotation(ctx, ctx.library, pat.type!)
          : bound ?? CoreTypes.dynamic.ref(ctx);
    case AssignedVariablePattern pat:
      return IdentifierReference(null, pat.name.lexeme)
          .resolveType(ctx, forSet: true, source: source);
    case ParenthesizedPattern pat:
      return patternTypeBound(ctx, pat.pattern, source: source, bound: bound);
    case ObjectPattern pat:
      final type = TypeRef.fromAnnotation(ctx, ctx.library, pat.type);
      if (bound != null && !type.isAssignableTo(ctx, bound)) {
        throw CompileError(
            'Object pattern type $type is not assignable to bound type $bound',
            source);
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
            source);
      }
      return type;
    default:
      throw CompileError(
          "Refutable patterns can't be used in an irrefutable context."
          "Try using an if-case, a 'switch' statement, or a 'switch' expression instead.",
          source);
  }
}

Variable patternMatchAndBind(
    CompilerContext ctx, ListPatternElement pattern, Variable V,
    {PatternBindContext patternContext = PatternBindContext.none}) {
  switch (pattern) {
    case ConstantPattern pat:
      final constant = compileExpression(pat.expression, ctx);
      return V.invoke(ctx, '==', [constant]).result;
    case RecordPattern pat:
      var positionalFields = 1;
      Variable? result;
      for (final field in pat.fields) {
        final fieldName = field.effectiveName ?? '\$${positionalFields++}';
        final fieldResult = patternMatchAndBind(
            ctx, field.pattern, V.getProperty(ctx, fieldName),
            patternContext: patternContext);
        if (result == null) {
          result = fieldResult;
        } else {
          result = result.invoke(ctx, '&&', [fieldResult]).result;
        }
      }
      return result ??
          (throw CompileError(
              'Record pattern matching failed, no fields matched', pattern));
    case ListPattern pat:
      if (pat.elements.isEmpty) {
        return BuiltinValue(boolval: true).push(ctx);
      }
      Variable? result;
      for (var i = 0; i < pat.elements.length; i++) {
        final element = pat.elements[i];
        final listEl = IndexedReference(V, BuiltinValue(intval: i).push(ctx))
            .getValue(ctx);
        final elementResult = patternMatchAndBind(ctx, element, listEl,
            patternContext: patternContext);
        if (result == null) {
          result = elementResult;
        } else {
          result = result.invoke(ctx, '&&', [elementResult]).result;
        }
      }
      return result ??
          (throw CompileError(
              'List pattern matching failed, no elements matched', pattern));
    case VariablePattern pat:
      final variableName = pat.name.lexeme;
      final declare = patternContext == PatternBindContext.declare ||
          patternContext == PatternBindContext.declareFinal ||
          (patternContext == PatternBindContext.matching &&
              pat is DeclaredVariablePattern);
      if (declare && ctx.locals.last.containsKey(variableName)) {
        throw CompileError('Cannot declare variable $variableName'
            ' multiple times in the same scope');
      }
      final isFinal = patternContext == PatternBindContext.declareFinal ||
          (pat is DeclaredVariablePattern &&
              pat.keyword != null &&
              pat.keyword!.keyword == Keyword.FINAL);
      // If the variable is already in scope, we need to copy it to a new stack slot
      if (V.name != null) {
        if (!(V.type.isUnboxedAcrossFunctionBoundaries)) {
          V = V.boxIfNeeded(ctx);
        }
        var v = Variable.alloc(ctx, V.type, isFinal: isFinal);
        ctx.pushOp(PushNull.make(), PushNull.LEN);
        ctx.pushOp(CopyValue.make(v.scopeFrameOffset, V.scopeFrameOffset),
            CopyValue.LEN);
        ctx.setLocal(variableName, v);
      } else {
        ctx.setLocal(variableName, V.copyWith(isFinal: isFinal));
      }

      if (pat is DeclaredVariablePattern) {
        return _typeTest(ctx, pat.type, V);
      }

      return BuiltinValue(boolval: true).push(ctx);
    case RelationalPattern pat:
      final operand = compileExpression(pat.operand, ctx);
      final operator = binaryOpMap[pat.operator.type] ??
          (throw CompileError(
              'Unknown relational operator ${pat.operator.type}'));
      return V.invoke(ctx, operator, [operand]).result;
    case WildcardPattern pat:
      return _typeTest(ctx, pat.type, V);
    case ParenthesizedPattern pat:
      return patternMatchAndBind(ctx, pat.pattern, V,
          patternContext: patternContext);
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

  ctx.pushOp(IsType.make(V.scopeFrameOffset, ctx.typeRefIndexMap[slot]!, false),
      IsType.length);
  return Variable.alloc(ctx, CoreTypes.bool.ref(ctx).copyWith(boxed: false));
}
