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
        final bool isAssignable =
            type.resolveTypeChain(ctx).isAssignableTo(ctx, res.type);

        if (!isAssignable) {
          final bool isGeneric = isGenericType(ctx, res.type);

          if (!isGeneric) {
            throw CompileError(
                'Type mismatch: variable "${li.name.lexeme} is specified'
                ' as type $type, but is initialized to an incompatible value of type ${res.type}');
          }
        }
      }
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

/// Função utilitária para identificar se um tipo é genérico
/// Considera múltiplas formas de identificação de tipos genéricos
bool isGenericType(CompilerContext ctx, TypeRef? type) {
  if (type == null) return false;

  // 1. Verificar se tem parâmetros genéricos definidos
  if (type.genericParams.isNotEmpty) {
    return true;
  }

  // 2. Verificar se foi especializado com argumentos de tipo
  if (type.specifiedTypeArgs.isNotEmpty) {
    return true;
  }

  // 3. Verificar se é um tipo de função genérica
  if (type.functionType != null) {
    return true;
  }

  // 4. Verificar se é um parâmetro genérico nos tipos temporários
  for (final typeMap in ctx.temporaryTypes.values) {
    if (typeMap.containsKey(type.name)) {
      return true;
    }
  }

  // 5. Verificar se é um tipo genérico visível
  for (final typeMap in ctx.visibleTypes.values) {
    if (typeMap.containsKey(type.name)) {
      // Verificar se o tipo encontrado tem características genéricas
      final foundType = typeMap[type.name]!;
      if (foundType.genericParams.isNotEmpty ||
          foundType.specifiedTypeArgs.isNotEmpty) {
        return true;
      }
    }
  }

  // 6. Verificar se não existe em topLevelDeclarationsMap (pode ser um parâmetro genérico)
  if (ctx.topLevelDeclarationsMap[type.file] == null ||
      ctx.topLevelDeclarationsMap[type.file]![type.name] == null) {
    // Se o nome tem características de tipo genérico (ex: nome de uma letra como T, U, V)
    // ou se está em um contexto onde tipos genéricos são esperados
    return type.name.length == 1 && type.name.toUpperCase() == type.name;
  }

  return false;
}
