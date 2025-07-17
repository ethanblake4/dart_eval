import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

import '../errors.dart';
import '../type.dart';
import '../variable.dart';
import 'statement.dart';

StatementInfo compileVariableDeclarationStatement(
    VariableDeclarationStatement s, CompilerContext ctx) {
  compileVariableDeclarationList(s.variables, ctx);
  return StatementInfo(-1);
}

void compileVariableDeclarationList(
    VariableDeclarationList l, CompilerContext ctx) {
  TypeRef? type;
  if (l.type != null) {
    type = TypeRef.fromAnnotation(ctx, ctx.library, l.type!);
  }

  for (final li in l.variables) {
    if (ctx.locals.last.containsKey(li.name.lexeme)) {
      throw CompileError('Cannot declare variable ${li.name.lexeme}'
          ' multiple times in the same scope');
    }
    final init = li.initializer;

    if (init != null) {
      var res = compileExpression(init, ctx, type);

      if (type != null) {
        // Resolver tipos genéricos usando os tipos temporários do contexto
        final resolvedType = _resolveGenericType(ctx, type);
        final resolvedResType = _resolveGenericType(ctx, res.type);

        if (!resolvedResType
            .resolveTypeChain(ctx)
            .isAssignableTo(ctx, resolvedType)) {
          throw CompileError(
              'Type mismatch: variable "${li.name.lexeme}" is specified'
              ' as type $resolvedType, but is initialized to an incompatible value of type ${resolvedResType}');
        }
      }
      // Debug de declaração removido para reduzir logs
      if (!((type ?? res.type).isUnboxedAcrossFunctionBoundaries)) {
        res = res.boxIfNeeded(ctx);
      }
      if (res.name != null) {
        final _type = type ?? res.type;
        var _v = Variable.alloc(
          ctx,
          _type.isUnboxedAcrossFunctionBoundaries
              ? _type.copyWith(boxed: false)
              : _type,
        );
        ctx.pushOp(PushNull.make(), PushNull.LEN);
        ctx.pushOp(CopyValue.make(_v.scopeFrameOffset, res.scopeFrameOffset),
            CopyValue.LEN);
        ctx.setLocal(li.name.lexeme, _v);
      } else {
        ctx.setLocal(
            li.name.lexeme,
            Variable(res.scopeFrameOffset,
                (type ?? res.type).copyWith(boxed: res.boxed),
                isFinal: l.isFinal || l.isConst,
                methodOffset: res.methodOffset,
                methodReturnType: res.methodReturnType,
                callingConvention: res.callingConvention));
      }
    } else {
      ctx.setLocal(
          li.name.lexeme,
          BuiltinValue()
              .push(ctx)
              .boxIfNeeded(ctx)
              .copyWith(type: type ?? CoreTypes.dynamic.ref(ctx)));
    }
  }
}

/// Resolve tipos genéricos usando os tipos temporários do contexto
TypeRef _resolveGenericType(CompilerContext ctx, TypeRef type) {
  // Primeiro, verificar se há uma resolução direta nos tipos temporários
  for (final entry in ctx.temporaryTypes.entries) {
    if (entry.value.containsKey(type.name)) {
      final resolvedType = entry.value[type.name]!;

      // Se o tipo resolvido é o mesmo que o tipo original (T -> T),
      // continuar procurando por uma resolução mais específica
      if (resolvedType.name == type.name) {
        continue;
      }

      return resolvedType;
    }
  }

  // Se não encontrou em temporaryTypes, procurar em visibleTypes
  for (final entry in ctx.visibleTypes.entries) {
    if (entry.value.containsKey(type.name)) {
      final resolvedType = entry.value[type.name]!;
      return resolvedType;
    }
  }

  // Se não encontrou, retornar o tipo original
  return type;
}
