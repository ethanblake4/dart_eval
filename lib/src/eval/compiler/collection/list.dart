import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/collection/for.dart';
import 'package:dart_eval/src/eval/compiler/collection/if.dart';
import 'package:dart_eval/src/eval/compiler/collection/spread.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/macros/loop.dart';
import 'package:dart_eval/src/eval/compiler/model/label.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

const _boxListElements = true;

Variable compileListLiteral(ListLiteral l, CompilerContext ctx,
    [TypeRef? bound]) {
  final elements = l.elements;

  TypeRef? boundType;
  if (bound != null && bound.specifiedTypeArgs.isNotEmpty) {
    if (bound.specifiedTypeArgs.length > 1) {
      throw CompileError('Lists can only have one type argument');
    }
    boundType = bound.specifiedTypeArgs.first;
  }
  TypeRef? listSpecifiedType;
  final typeArgs = l.typeArguments;
  if (typeArgs != null) {
    listSpecifiedType =
        TypeRef.fromAnnotation(ctx, ctx.library, typeArgs.arguments[0]);
    if (boundType != null &&
        !listSpecifiedType.isAssignableTo(ctx, boundType)) {
      throw CompileError(
          'List of type $listSpecifiedType is not assignable to List of type $boundType');
    }
  } else {
    listSpecifiedType = boundType;
  }

  ctx.pushOp(PushList.make(), PushList.LEN);

  var list = Variable.alloc(
    ctx,
    CoreTypes.list.ref(ctx).copyWith(
        specifiedTypeArgs: [listSpecifiedType ?? CoreTypes.dynamic.ref(ctx)],
        boxed: false),
  );

  ctx.beginAllocScope();
  ctx.labels.add(SimpleCompilerLabel());
  final resultTypes = <TypeRef>[];
  for (final e in elements) {
    resultTypes.addAll(compileListElement(e, list, ctx, _boxListElements));
  }
  ctx.labels.removeLast();
  ctx.endAllocScope();

  if (listSpecifiedType == null) {
    return Variable(
        list.scopeFrameOffset,
        CoreTypes.list.ref(ctx).copyWith(boxed: false, specifiedTypeArgs: [
          resultTypes.isEmpty
              ? CoreTypes.dynamic.ref(ctx)
              : TypeRef.commonBaseType(ctx, resultTypes.toSet())
        ]));
  }

  return list;
}

Variable boxListContents(CompilerContext ctx, Variable list) {
  late Variable $i, $1, len, newList;

  macroLoop(ctx, AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true),
      initialization: (ctx) {
    $i = BuiltinValue(intval: 0).push(ctx);
    $1 = BuiltinValue(intval: 1).push(ctx);

    // final len = list.length;
    len = Variable.alloc(ctx, CoreTypes.int.ref(ctx).copyWith(boxed: false));
    ctx.pushOp(
        PushIterableLength.make(list.scopeFrameOffset), PushIterableLength.LEN);

    // final newList = <T{boxed}>[];
    ctx.pushOp(PushList.make(), PushList.LEN);

    newList = Variable.alloc(
        ctx,
        CoreTypes.list.ref(ctx).copyWith(boxed: true, specifiedTypeArgs: [
          list.type.specifiedTypeArgs[0].copyWith(boxed: true)
        ]));
  }, condition: (ctx) {
    // i < len
    final v =
        Variable.alloc(ctx, CoreTypes.bool.ref(ctx).copyWith(boxed: false));
    ctx.pushOp(
        NumLt.make($i.scopeFrameOffset, len.scopeFrameOffset), NumLt.LEN);
    return v;
  }, body: (ctx, rt) {
    final v = Variable.alloc(ctx, list.type.specifiedTypeArgs[0]);
    ctx.pushOp(IndexList.make(list.scopeFrameOffset, $i.scopeFrameOffset),
        IndexList.LEN);
    final boxed = v.boxIfNeeded(ctx);
    ctx.pushOp(
        ListAppend.make(newList.scopeFrameOffset, boxed.scopeFrameOffset),
        ListAppend.LEN);
    return StatementInfo(-1);
  }, update: (ctx) {
    final ip1 =
        Variable.alloc(ctx, CoreTypes.int.ref(ctx).copyWith(boxed: false));
    ctx.pushOp(
        NumAdd.make($i.scopeFrameOffset, $1.scopeFrameOffset), NumAdd.LEN);
    ctx.pushOp(CopyValue.make($i.scopeFrameOffset, ip1.scopeFrameOffset),
        CopyValue.LEN);
  }, after: (ctx) {
    ctx.pushOp(CopyValue.make(list.scopeFrameOffset, newList.scopeFrameOffset),
        CopyValue.LEN);
  });

  // return list.cast<T{boxed}>;
  return Variable(
      list.scopeFrameOffset,
      list.type.copyWith(specifiedTypeArgs: [
        list.type.specifiedTypeArgs[0].copyWith(boxed: true)
      ]))
    ..name = list.name
    ..frameIndex = list.frameIndex;
}

List<TypeRef> compileListElement(
    CollectionElement e, Variable list, CompilerContext ctx, bool box) {
  final listType = list.type.specifiedTypeArgs[0];
  if (e is Expression) {
    var result = compileExpression(e, ctx, listType);
    if (!result.type.resolveTypeChain(ctx).isAssignableTo(ctx, listType)) {
      throw CompileError(
          'Cannot use expression of type ${result.type} in list of type $listType');
    }
    if (box) {
      result = result.boxIfNeeded(ctx);
    }
    ctx.pushOp(ListAppend.make(list.scopeFrameOffset, result.scopeFrameOffset),
        ListAppend.LEN);
    return [result.type];
  } else if (e is IfElement) {
    return compileIfElementForList(e, list, ctx, box);
  } else if (e is ForElement) {
    return compileForElementForList(e, list, ctx, box);
  } else if (e is SpreadElement) {
    return compileSpreadElementForList(e, list, ctx, box);
  }
  throw CompileError('Unknown list collection element ${e.runtimeType}');
}
