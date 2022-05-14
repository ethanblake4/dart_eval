import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/scope.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

void compileFieldDeclaration(int fieldIndex, FieldDeclaration d, CompilerContext ctx, ClassDeclaration parent) {
  var _fieldIndex = fieldIndex;
  for (final field in d.fields.variables) {
    if (d.isStatic) {
      final initializer = field.initializer;
      if (initializer != null) {
        final pos = beginMethod(ctx, field, field.offset, parent.name.name + '.' + field.name.name + ' (init)');
        var V = compileExpression(initializer, ctx);
        TypeRef type;
        final specifiedType = d.fields.type;
        if (specifiedType != null) {
          type = TypeRef.fromAnnotation(ctx, ctx.library, specifiedType);
          if (!V.type.isAssignableTo(ctx, type)) {
            throw CompileError(
                'Static field ${parent.name.name}.${field.name.name} of inferred type ${V.type} '
                    'does not conform to type $type');
          }
        } else {
          type = V.type;
        }
        if (!unboxedAcrossFunctionBoundaries.contains(type)) {
          V = V.boxIfNeeded(ctx);
          type = type.copyWith(boxed: true);
        } else {
          V = V.unboxIfNeeded(ctx);
          type = type.copyWith(boxed: false);
        }
        final _name = '${parent.name.name}.${field.name.name}';
        final _index = ctx.topLevelGlobalIndices[ctx.library]![_name]!;
        ctx.pushOp(SetGlobal.make(_index, V.scopeFrameOffset), SetGlobal.LEN);
        ctx.topLevelVariableInferredTypes[ctx.library]![_name] = type;
        ctx.topLevelGlobalInitializers[ctx.library]![_name] = pos;
        ctx.runtimeGlobalInitializerMap[_index] = pos;
        ctx.pushOp(Return.make(V.scopeFrameOffset), Return.LEN);
      }
    } else {
      final pos = beginMethod(ctx, d, d.offset, parent.name.name + '.' + field.name.name + ' (get)');
      ctx.pushOp(PushObjectPropertyImpl.make(0, _fieldIndex), PushObjectPropertyImpl.LEN);
      ctx.pushOp(Return.make(1), Return.LEN);
      ctx.instanceDeclarationPositions[ctx.library]![parent.name.name]![0][field.name.name] = pos;

      if (!(field.isFinal || field.isConst)) {
        final setterPos = beginMethod(ctx, d, d.offset, parent.name.name + '.' + field.name.name + ' (set)');
        ctx.pushOp(SetObjectPropertyImpl.make(0, _fieldIndex, 1), SetObjectPropertyImpl.LEN);
        ctx.pushOp(Return.make(1), Return.LEN);
        ctx.instanceDeclarationPositions[ctx.library]![parent.name.name]![1][field.name.name] = setterPos;
      }

      _fieldIndex++;
    }
  }
}
