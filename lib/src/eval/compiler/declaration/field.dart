import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/scope.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/globals.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:dart_eval/src/eval/shared/registers.dart';

void compileFieldDeclaration(int fieldIndex, FieldDeclaration d,
    CompilerContext ctx, NamedCompilationUnitMember parent) {
  final parentName = parent.name.lexeme;
  var _fieldIndex = fieldIndex;
  for (final field in d.fields.variables) {
    final fieldName = field.name.lexeme;
    if (d.isStatic) {
      final initializer = field.initializer;
      TypeRef? type;
      final specifiedType = d.fields.type;
      if (specifiedType != null) {
        type = TypeRef.fromAnnotation(ctx, ctx.library, specifiedType);
      }
      if (initializer != null) {
        final pos = beginMethod(ctx, field, field.offset, '$fieldName*i');
        ctx.beginAllocScope();
        var V = compileExpression(initializer, ctx, type);
        if (type != null) {
          if (!V.type.isAssignableTo(ctx, type)) {
            throw CompileError(
                'Static field $parentName.$fieldName of inferred type ${V.type} '
                'does not conform to type $type');
          }
        } else {
          type = V.type;
        }
        if (!type.isUnboxedAcrossFunctionBoundaries) {
          V = V.boxIfNeeded(ctx);
          type = type.copyWith(boxed: true);
        } else {
          V = V.unboxIfNeeded(ctx);
          type = type.copyWith(boxed: false);
        }
        final _name = '$parentName.$fieldName';
        final _index = ctx.topLevelGlobalIndices[ctx.library]![_name]!;
        ctx.pushOp(SetGlobal(_index, V.ssa));
        ctx.topLevelVariableInferredTypes[ctx.library]![_name] = type;
        ctx.pushOp(Return(V.ssa));
        ctx.endAllocScope(popValues: false);
      } else {
        ctx.topLevelVariableInferredTypes[ctx.library]![
            '$parentName.$fieldName'] = type ?? CoreTypes.dynamic.ref(ctx);
      }
    } else {
      final pos = beginMethod(ctx, d, d.offset, '$parentName.$fieldName (get)');
      final obj = Variable.ssa(ctx, AssignRegister(ctx.svar('this'), regGPR3),
          CoreTypes.object.ref(ctx));
      final result = Variable.ssa(
          ctx,
          LoadPropertyStatic(ctx.svar(fieldName), obj.ssa, _fieldIndex),
          CoreTypes.dynamic.ref(ctx));
      ctx.pushOp(Return(result.ssa));
      ctx.instanceGetterIndices[ctx.library]![parentName]![fieldName] =
          _fieldIndex;

      if (!(field.isFinal || field.isConst)) {
        beginMethod(ctx, d, d.offset, '$parentName.$fieldName (set)');
        final value = Variable.ssa(
            ctx,
            AssignRegister(ctx.svar('value'), regGPR1),
            CoreTypes.dynamic.ref(ctx));
        ctx.pushOp(SetPropertyStatic(
          obj.ssa,
          _fieldIndex,
          value.ssa,
        ));
        ctx.pushOp(Return(value.ssa));
      }

      _fieldIndex++;
    }
  }
}
