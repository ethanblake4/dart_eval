import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/scope.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

void compileFieldDeclaration(int fieldIndex, FieldDeclaration d,
    CompilerContext ctx, NamedCompilationUnitMember parent) {
  final parentName = parent.name.lexeme;
  var fieldIndex0 = fieldIndex;
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
        final name = '$parentName.$fieldName';
        final index = ctx.topLevelGlobalIndices[ctx.library]![name]!;
        ctx.pushOp(SetGlobal.make(index, V.scopeFrameOffset), SetGlobal.LEN);
        ctx.topLevelVariableInferredTypes[ctx.library]![name] = type;
        ctx.topLevelGlobalInitializers[ctx.library]![name] = pos;
        ctx.runtimeGlobalInitializerMap[index] = pos;
        ctx.pushOp(Return.make(V.scopeFrameOffset), Return.LEN);
        ctx.endAllocScope(popValues: false);
      } else {
        ctx.topLevelVariableInferredTypes[ctx.library]![
            '$parentName.$fieldName'] = type ?? CoreTypes.dynamic.ref(ctx);
      }
    } else {
      final pos = beginMethod(ctx, d, d.offset, '$parentName.$fieldName (get)');
      ctx.pushOp(PushObjectPropertyImpl.make(0, fieldIndex0),
          PushObjectPropertyImpl.length);
      ctx.pushOp(Return.make(1), Return.LEN);
      ctx.instanceDeclarationPositions[ctx.library]![parentName]![0]
          [fieldName] = pos;
      ctx.instanceGetterIndices[ctx.library]![parentName]![fieldName] =
          fieldIndex0;

      if (!(field.isFinal || field.isConst)) {
        final setterPos =
            beginMethod(ctx, d, d.offset, '$parentName.$fieldName (set)');
        ctx.pushOp(SetObjectPropertyImpl.make(0, fieldIndex0, 1),
            SetObjectPropertyImpl.length);
        ctx.pushOp(Return.make(1), Return.LEN);
        ctx.instanceDeclarationPositions[ctx.library]![parentName]![1]
            [fieldName] = setterPos;
      }

      fieldIndex0++;
    }
  }
}
