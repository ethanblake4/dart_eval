import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/collection/if.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/macros/loop.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

const _boxListElements = true;

Variable compileListLiteral(ListLiteral l, CompilerContext ctx) {
  final elements = l.elements;

  TypeRef? listSpecifiedType;
  final typeArgs = l.typeArguments;
  if (typeArgs != null) {
    listSpecifiedType = TypeRef.fromAnnotation(ctx, ctx.library, typeArgs.arguments[0]);
  }

  ctx.pushOp(PushList.make(), PushList.LEN);

  var _list = Variable.alloc(
    ctx,
    EvalTypes.listType.copyWith(specifiedTypeArgs: [listSpecifiedType ?? EvalTypes.dynamicType], boxed: false),
  );

  ctx.beginAllocScope();
  final resultTypes = <TypeRef>[];
  for (final e in elements) {
    resultTypes.addAll(compileListElement(e, _list, ctx, _boxListElements));
  }
  ctx.endAllocScope();

  if (listSpecifiedType == null) {
    return Variable(
        _list.scopeFrameOffset,
        EvalTypes.listType
            .copyWith(boxed: false, specifiedTypeArgs: [TypeRef.commonBaseType(ctx, resultTypes.toSet())]));
  }

  return _list;
}

Variable boxListContents(CompilerContext ctx, Variable list) {
  late Variable $i, $1, len, newList;

  macroLoop(ctx, AlwaysReturnType(EvalTypes.dynamicType, true), initialization: (_ctx) {
    $i = BuiltinValue(intval: 0).push(_ctx);
    $1 = BuiltinValue(intval: 1).push(_ctx);

    // final len = list.length;
    len = Variable.alloc(_ctx, EvalTypes.intType.copyWith(boxed: false));
    _ctx.pushOp(PushIterableLength.make(list.scopeFrameOffset), PushIterableLength.LEN);

    // final newList = <T{boxed}>[];
    _ctx.pushOp(PushList.make(), PushList.LEN);

    newList = Variable.alloc(
        _ctx,
        EvalTypes.listType
            .copyWith(boxed: true, specifiedTypeArgs: [list.type.specifiedTypeArgs[0].copyWith(boxed: true)]));
  }, condition: (_ctx) {
    // i < len
    final v = Variable.alloc(_ctx, EvalTypes.boolType.copyWith(boxed: false));
    _ctx.pushOp(NumLt.make($i.scopeFrameOffset, len.scopeFrameOffset), NumLt.LEN);
    return v;
  }, body: (_ctx, rt) {
    final v = Variable.alloc(_ctx, list.type.specifiedTypeArgs[0]);
    _ctx.pushOp(IndexList.make(list.scopeFrameOffset, $i.scopeFrameOffset), IndexList.LEN);
    final boxed = v.boxIfNeeded(ctx);
    _ctx.pushOp(ListAppend.make(newList.scopeFrameOffset, boxed.scopeFrameOffset), ListAppend.LEN);
    return StatementInfo(-1);
  }, update: (_ctx) {
    final ip1 = Variable.alloc(_ctx, EvalTypes.intType.copyWith(boxed: false));
    _ctx.pushOp(NumAdd.make($i.scopeFrameOffset, $1.scopeFrameOffset), NumAdd.LEN);
    _ctx.pushOp(CopyValue.make($i.scopeFrameOffset, ip1.scopeFrameOffset), CopyValue.LEN);
  }, after: (_ctx) {
    _ctx.pushOp(CopyValue.make(list.scopeFrameOffset, newList.scopeFrameOffset), CopyValue.LEN);
  });

  // return list.cast<T{boxed}>;
  return Variable(list.scopeFrameOffset,
      list.type.copyWith(specifiedTypeArgs: [list.type.specifiedTypeArgs[0].copyWith(boxed: true)]))
    ..name = list.name
    ..frameIndex = list.frameIndex;
}

List<TypeRef> compileListElement(CollectionElement e, Variable list, CompilerContext ctx, bool box) {
  final listType = list.type.specifiedTypeArgs[0];
  if (e is Expression) {
    var _result = compileExpression(e, ctx);
    if (!_result.type.resolveTypeChain(ctx).isAssignableTo(ctx, listType)) {
      throw CompileError('Cannot use expression of type ${_result.type} in list of type $listType');
    }
    if (box) {
      _result = _result.boxIfNeeded(ctx);
    }
    ctx.pushOp(ListAppend.make(list.scopeFrameOffset, _result.scopeFrameOffset), ListAppend.LEN);
    return [_result.type];
  } else if (e is IfElement) {
    return compileIfElementForList(e, list, ctx, box);
  }
  throw CompileError('Unknown list collection element ${e.runtimeType}');
}
