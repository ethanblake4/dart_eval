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

/// Compiles a spread element in a list literal.
List<TypeRef> compileSpreadElementForList(
    SpreadElement e, Variable list, CompilerContext ctx, bool box) {
  final listType = list.type.specifiedTypeArgs[0];
  final expression = e.expression;
  final isNullAware = e.isNullAware;

  // Compile the expression to get the spreaded collection
  var _collection = compileExpression(expression, ctx, list.type);

  if (isNullAware) {
    // For null-aware spread, we need to check if the collection is not null
    // TODO: implement null check for ...? operator
    // For now, treat it as a normal spread
  }

  // Check if the collection is iterable
  final iterableType = CoreTypes.iterable.ref(ctx);
  if (!_collection.type
      .resolveTypeChain(ctx)
      .isAssignableTo(ctx, iterableType)) {
    throw CompileError(
        'Cannot spread non-iterable type ${_collection.type} in list literal');
  }

  // Get the element type of the collection
  var collectionElementType = CoreTypes.dynamic.ref(ctx);
  if (_collection.type.specifiedTypeArgs.isNotEmpty) {
    collectionElementType = _collection.type.specifiedTypeArgs[0];
  }

  // Check if the collection elements are compatible with the list type
  if (!collectionElementType
      .resolveTypeChain(ctx)
      .isAssignableTo(ctx, listType)) {
    throw CompileError(
        'Cannot spread collection of type ${collectionElementType} in list of type $listType');
  }

  // Implement the spread using a loop similar to boxListContents
  late Variable $i, $1, len;

  // Initialize loop variables
  $i = BuiltinValue(intval: 0).push(ctx);
  $1 = BuiltinValue(intval: 1).push(ctx);

  // Get the length of the collection
  len = Variable.alloc(ctx, CoreTypes.int.ref(ctx).copyWith(boxed: false));
  ctx.pushOp(PushIterableLength.make(_collection.scopeFrameOffset),
      PushIterableLength.LEN);

  // Loop to add each element
  macroLoop(ctx, AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true),
      initialization: (_ctx) {
    // We have already initialized the variables above
  }, condition: (_ctx) {
    // i < len
    final v =
        Variable.alloc(_ctx, CoreTypes.bool.ref(ctx).copyWith(boxed: false));
    _ctx.pushOp(
        NumLt.make($i.scopeFrameOffset, len.scopeFrameOffset), NumLt.LEN);
    return v;
  }, body: (_ctx, rt) {
    // Get the element at index i
    final element = Variable.alloc(_ctx, collectionElementType);
    _ctx.pushOp(
        IndexList.make(_collection.scopeFrameOffset, $i.scopeFrameOffset),
        IndexList.LEN);

    // Boxing if needed
    final elementToAdd = box ? element.boxIfNeeded(ctx) : element;

    // Add the element to the list
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
    // Nothing additional needed after the loop
  });

  return [collectionElementType];
}
