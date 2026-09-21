import 'package:dart_eval/src/eval/compiler/collection/spread.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/macros/loop.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/ir/alu.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/collection/for.dart';
import 'package:dart_eval/src/eval/compiler/collection/if.dart';

import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/conversion.dart';
import 'package:dart_eval/src/eval/compiler/backend/representation.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/collection.dart';

const _boxListElements = true;

Variable compileListLiteral(
  ListLiteral l,
  CompilerContext ctx, [
  TypeRef? bound,
]) {
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
    listSpecifiedType = TypeRef.fromAnnotation(
      ctx,
      ctx.library,
      typeArgs.arguments[0],
    );
    if (boundType != null &&
        !listSpecifiedType.isAssignableTo(ctx, boundType)) {
      throw CompileError(
        'List of type $listSpecifiedType is not assignable to List of type $boundType',
      );
    }
  } else {
    listSpecifiedType = boundType;
  }

  final listType = CoreTypes.list
      .ref(ctx)
      .copyWith(
        specifiedTypeArgs: [
          (listSpecifiedType ?? CoreTypes.dynamic.ref(ctx)).copyWith(
            boxed: _boxListElements,
          ),
        ],
        boxed: false,
      );
  var list = Variable.ssa(
    ctx,
    NewList(ctx.svar('list')),
    listType,
    exactType: listType,
  );

  ctx.beginScope();
  final resultTypes = <TypeRef>[];
  for (final e in elements) {
    resultTypes.addAll(compileListElement(e, list, ctx, _boxListElements));
  }
  ctx.endScope();

  if (listSpecifiedType == null) {
    return list.copyWith(
      type: CoreTypes.list
          .ref(ctx)
          .copyWith(
            boxed: false,
            specifiedTypeArgs: [
              resultTypes.isEmpty
                  ? CoreTypes.dynamic.ref(ctx)
                  : TypeRef.commonBaseType(ctx, resultTypes.toSet()),
            ],
          ),
    );
  }

  return list;
}

Variable boxListContents(CompilerContext ctx, Variable list) {
  final elementType = list.type.specifiedTypeArgs.first;
  final newList = Variable.ssa(
    ctx,
    NewList(ctx.svar('boxed_elements')),
    list.type.copyWith(
      boxed: false,
      specifiedTypeArgs: [elementType.copyWith(boxed: true)],
    ),
  );
  final index = BuiltinValue(intval: 0).push(ctx);
  final one = BuiltinValue(intval: 1).push(ctx);
  final length = Variable.ssa(
    ctx,
    IterableLength(ctx.svar('length'), list.ssa),
    CoreTypes.int.ref(ctx).copyWith(boxed: false),
  );
  macroLoop(
    ctx,
    null,
    condition: (ctx) => Variable.ssa(
      ctx,
      IntLessThan(ctx.svar('in_bounds'), index.ssa, length.ssa),
      CoreTypes.bool.ref(ctx).copyWith(boxed: false),
    ),
    body: (ctx, _) {
      final element = Variable.ssa(
        ctx,
        IndexList(ctx.svar('element'), list.ssa, index.ssa),
        elementType,
      );
      ctx.pushOp(ListAppend(newList.ssa, element.boxIfNeeded(ctx).ssa));
      return StatementInfo();
    },
    update: (ctx) {
      final incremented = ctx.svar('next_index');
      ctx.pushOp(IntAdd(incremented, index.ssa, one.ssa));
      ctx.pushOp(Assign(index.ssa, incremented));
    },
  );
  return newList;
}

List<TypeRef> compileListElement(
  CollectionElement e,
  Variable list,
  CompilerContext ctx,
  bool box,
) {
  final listType = list.type.specifiedTypeArgs[0];
  if (e is Expression) {
    var result = compileExpression(e, ctx, listType);
    result = convertForAssignment(
      ctx,
      result,
      listType,
      representation: box ? MachineRepresentation.object : null,
      source: e,
      description:
          'Cannot use expression of type ${result.type} in list of type $listType',
    );
    ctx.pushOp(ListAppend(list.ssa, result.ssa));
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
