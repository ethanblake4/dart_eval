import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/macros/loop.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

/// Compila um SpreadElement para ser usado em uma lista
List<TypeRef> compileSpreadElementForList(
    SpreadElement e, Variable list, CompilerContext ctx, bool box) {
  final listType = list.type.specifiedTypeArgs[0];
  final expression = e.expression;
  final isNullAware = e.isNullAware;

  // Compilar a expressão que representa a coleção a ser expandida
  var _collection = compileExpression(expression, ctx);

  // Verificar se é null-aware spread (...?)
  if (isNullAware) {
    // Para spread null-aware, precisamos verificar se a coleção não é null
    // TODO: implementar verificação de null para ...? operator
    // Por enquanto, vamos tratar como spread normal
  }

  // Verificar se a coleção é iterável
  final iterableType = CoreTypes.iterable.ref(ctx);
  if (!_collection.type
      .resolveTypeChain(ctx)
      .isAssignableTo(ctx, iterableType)) {
    throw CompileError(
        'Cannot spread non-iterable type ${_collection.type} in list literal');
  }

  // Obter o tipo dos elementos da coleção
  var collectionElementType = CoreTypes.dynamic.ref(ctx);
  if (_collection.type.specifiedTypeArgs.isNotEmpty) {
    collectionElementType = _collection.type.specifiedTypeArgs[0];
  }

  // Verificar se os elementos da coleção são compatíveis com o tipo da lista
  if (!collectionElementType
      .resolveTypeChain(ctx)
      .isAssignableTo(ctx, listType)) {
    throw CompileError(
        'Cannot spread collection of type ${collectionElementType} in list of type $listType');
  }

  // Implementar o spread usando um loop similar ao boxListContents
  late Variable $i, $1, len;

  // Inicializar variáveis do loop
  $i = BuiltinValue(intval: 0).push(ctx);
  $1 = BuiltinValue(intval: 1).push(ctx);

  // Obter o comprimento da coleção
  len = Variable.alloc(ctx, CoreTypes.int.ref(ctx).copyWith(boxed: false));
  ctx.pushOp(PushIterableLength.make(_collection.scopeFrameOffset),
      PushIterableLength.LEN);

  // Loop para adicionar cada elemento
  macroLoop(ctx, AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true),
      initialization: (_ctx) {
    // Já inicializamos as variáveis acima
  }, condition: (_ctx) {
    // i < len
    final v =
        Variable.alloc(_ctx, CoreTypes.bool.ref(ctx).copyWith(boxed: false));
    _ctx.pushOp(
        NumLt.make($i.scopeFrameOffset, len.scopeFrameOffset), NumLt.LEN);
    return v;
  }, body: (_ctx, rt) {
    // Obter o elemento no índice i
    final element = Variable.alloc(_ctx, collectionElementType);
    _ctx.pushOp(
        IndexList.make(_collection.scopeFrameOffset, $i.scopeFrameOffset),
        IndexList.LEN);

    // Boxing se necessário
    final elementToAdd = box ? element.boxIfNeeded(ctx) : element;

    // Adicionar o elemento à lista
    _ctx.pushOp(
        ListAppend.make(list.scopeFrameOffset, elementToAdd.scopeFrameOffset),
        ListAppend.LEN);

    return StatementInfo(-1);
  }, update: (_ctx) {
    // i++
    final ip1 =
        Variable.alloc(_ctx, CoreTypes.int.ref(ctx).copyWith(boxed: false));
    _ctx.pushOp(
        NumAdd.make($i.scopeFrameOffset, $1.scopeFrameOffset), NumAdd.LEN);
    _ctx.pushOp(CopyValue.make($i.scopeFrameOffset, ip1.scopeFrameOffset),
        CopyValue.LEN);
  }, after: (_ctx) {
    // Nada adicional necessário após o loop
  });

  return [collectionElementType];
}
