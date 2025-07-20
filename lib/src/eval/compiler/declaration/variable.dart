import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/scope.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

void compileTopLevelVariableDeclaration(
    VariableDeclaration v, CompilerContext ctx) {
  final parent = v.parent!.parent! as TopLevelVariableDeclaration;
  final varName = v.name.lexeme;

  final initializer = v.initializer;
  if (initializer != null) {
    final pos = beginMethod(ctx, v, v.offset, '$varName*i');
    var V = compileExpression(initializer, ctx);
    TypeRef type;
    final specifiedType = parent.variables.type;
    if (specifiedType != null) {
      type = TypeRef.fromAnnotation(ctx, ctx.library, specifiedType);
      if (!V.type.isAssignableTo(ctx, type)) {
        throw CompileError(
            'Variable $varName of inferred type ${V.type} does not conform to type $type');
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
    final index = ctx.topLevelGlobalIndices[ctx.library]![varName]!;
    ctx.pushOp(SetGlobal.make(index, V.scopeFrameOffset), SetGlobal.LEN);
    ctx.topLevelVariableInferredTypes[ctx.library]![varName] = type;
    ctx.topLevelGlobalInitializers[ctx.library]![varName] = pos;
    ctx.runtimeGlobalInitializerMap[index] = pos;
    ctx.pushOp(Return.make(V.scopeFrameOffset), Return.LEN);
  }
}
